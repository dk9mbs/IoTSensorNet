import datetime
import unittest
from unittest import mock

from config import CONFIG
from core.appinfo import AppInfo
from core.fetchxmlparser import FetchXmlParser
from core.plugin import Plugin
from services.database import DatabaseServices

import iot_sensor_throttle
from iot_sensor_throttle import must_store

SENSOR="test_throttle_001"

class TestThrottleRule(unittest.TestCase):
    def setUp(self):
        self.now=datetime.datetime(2026,11,24,12,0,0)

    def _ago(self, sec):
        return self.now-datetime.timedelta(seconds=sec)

    def test_t1_not_throttled(self):
        self.assertTrue(must_store(20.0, self.now, 60, None, 0.2, 20.0, self._ago(1)))

    def test_t2_first_value(self):
        self.assertTrue(must_store(20.0, self.now, 60, 900, 0.2, None, None))

    def test_t3_same_value_after_60s(self):
        self.assertFalse(must_store(20.0, self.now, 60, 900, 0.2, 20.0, self._ago(60)))

    def test_t4_heartbeat(self):
        self.assertTrue(must_store(20.0, self.now, 60, 900, 0.2, 20.0, self._ago(900)))

    def test_t5_change_after_min_interval(self):
        self.assertTrue(must_store(20.2, self.now, 60, 900, 0.2, 20.0, self._ago(60)))
        self.assertTrue(must_store(19.5, self.now, 60, 900, 0.2, 20.0, self._ago(60)))

    def test_t6_change_before_min_interval(self):
        self.assertFalse(must_store(25.0, self.now, 60, 900, 0.2, 20.0, self._ago(59)))

    def test_heartbeat_only(self):
        self.assertFalse(must_store(25.0, self.now, 60, 900, None, 20.0, self._ago(600)))
        self.assertFalse(must_store(25.0, self.now, 60, 900, 0, 20.0, self._ago(600)))

    def test_min_interval_null(self):
        self.assertTrue(must_store(25.0, self.now, None, 900, 0.2, 20.0, self._ago(1)))


class TestThrottlePlugin(unittest.TestCase):
    def setUp(self):
        AppInfo.init(__name__, CONFIG['default'])
        session_id=AppInfo.login("root","password")
        self.context=AppInfo.create_context(session_id)

        self._delete_sensor()
        self._exec(f"""<restapi type="insert"><table name="iot_sensor"/><fields>
            <field name="id" value="{SENSOR}"/><field name="alias" value="{SENSOR}"/>
            <field name="description" value="{SENSOR}"/>
            </fields></restapi>""")

    def tearDown(self):
        self._delete_sensor()
        AppInfo.save_context(self.context, True)
        AppInfo.logoff(self.context)

    def _exec(self, xml, fetch_mode=-1):
        return DatabaseServices.exec(FetchXmlParser(xml, self.context), self.context, fetch_mode=fetch_mode, run_as_system=True)

    def _delete_sensor(self):
        self._exec(f"""<restapi type="delete"><table name="iot_sensor_data"/>
            <filter><condition field="sensor_id" value="{SENSOR}"/></filter></restapi>""")
        self._exec(f"""<restapi type="delete"><table name="iot_sensor_routing"/>
            <filter><condition field="external_sensor_id" value="{SENSOR}"/></filter></restapi>""")
        self._exec(f"""<restapi type="delete"><table name="iot_sensor"/>
            <filter><condition field="id" value="{SENSOR}"/></filter></restapi>""")

    def _set_sensor(self, **fields):
        xml_fields="".join(f'<field name="{k}" value="{v}"/>' for k,v in fields.items())
        self._exec(f"""<restapi type="update"><table name="iot_sensor"/>
            <fields>{xml_fields}</fields>
            <filter><condition field="id" value="{SENSOR}"/></filter></restapi>""")

    def _throttle(self, min_sec=60, max_sec=900, deadband=0.2):
        self._set_sensor(store_min_interval_sec=min_sec, store_max_interval_sec=max_sec, store_deadband=deadband)

    def _age_last_stored(self, sec):
        last_on=datetime.datetime.now().replace(microsecond=0)-datetime.timedelta(seconds=sec)
        self._set_sensor(store_last_on=last_on)

    def _insert(self, value):
        return self._exec(f"""<restapi type="insert"><table name="iot_sensor_data"/><fields>
            <field name="sensor_id" value="{SENSOR}"/><field name="sensor_namespace" value="test"/>
            <field name="sensor_value" value="{value}"/>
            </fields></restapi>""", fetch_mode=0)

    def _count(self):
        rs=self._exec(f"""<restapi type="select"><table name="iot_sensor_data"/>
            <filter><condition field="sensor_id" value="{SENSOR}"/></filter></restapi>""", fetch_mode=0)
        return len(rs.get_result())

    def _sensor(self):
        rs=self._exec(f"""<restapi type="select"><table name="iot_sensor"/>
            <filter><condition field="id" value="{SENSOR}"/></filter></restapi>""", fetch_mode=1)
        return rs.get_result()

    def test_t1_not_throttled(self):
        self._insert(20.0)
        self._insert(20.0)
        self.assertEqual(self._count(), 2)
        self.assertEqual(self._sensor()['store_last_on'], "")

    def test_t2_t3_first_then_drop(self):
        self._throttle()
        self._insert(20.0)
        self.assertEqual(self._count(), 1)
        self.assertEqual(float(self._sensor()['store_last_value']), 20.0)
        self.assertNotEqual(self._sensor()['store_last_on'], "")

        self._age_last_stored(60)
        rs=self._insert(20.1)
        self.assertIsNone(rs.get_inserted_id())
        self.assertEqual(rs.get_cursor().rowcount, 0)
        self.assertEqual(self._count(), 1)
        self.assertEqual(float(self._sensor()['last_value']), 20.1)
        self.assertEqual(float(self._sensor()['store_last_value']), 20.0)

    def test_t4_heartbeat(self):
        self._throttle()
        self._insert(20.0)
        self._age_last_stored(900)
        self._insert(20.0)
        self.assertEqual(self._count(), 2)

    def test_t5_t6_deadband(self):
        self._throttle()
        self._insert(20.0)
        self._age_last_stored(30)
        self._insert(25.0)
        self.assertEqual(self._count(), 1)

        self._age_last_stored(60)
        self._insert(20.2)
        self.assertEqual(self._count(), 2)
        self.assertEqual(float(self._sensor()['store_last_value']), 20.2)

    def test_failed_insert_not_remembered(self):
        # only the before phase runs, as if the insert failed afterwards
        self._throttle()
        params={"data": {"sensor_id": {"value": SENSOR}, "sensor_value": {"value": 20.0},
            "sensor_namespace": {"value": "test"}}}
        cancelled=Plugin(self.context, "iot_sensor_data", "insert").execute('before', params)
        self.assertFalse(cancelled)
        self.assertEqual(self._sensor()['store_last_on'], "")
        self.assertEqual(self._sensor()['store_last_value'], "")

    def test_t7_not_a_number(self):
        plugin_context={"type": "before", "cancel": False}
        params={"data": {"sensor_id": {"value": SENSOR}, "sensor_value": {"value": "abc"}}}
        iot_sensor_throttle.execute(self.context, plugin_context, params)
        self.assertFalse(plugin_context['cancel'])

    def test_t8_exception_stores(self):
        self._throttle()
        self._insert(20.0)
        self._age_last_stored(60)
        with mock.patch.object(iot_sensor_throttle, "_read_sensor", side_effect=Exception("db error")):
            self._insert(20.0)
        self.assertEqual(self._count(), 2)

if __name__ == '__main__':
    unittest.main()
