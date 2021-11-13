import unittest

from core.database import CommandBuilderFactory
from core.database import FetchXmlParser
from config import CONFIG
from core.appinfo import AppInfo
from core.plugin import Plugin
from services.database import DatabaseServices
from core import log


class TestPluginExecution(unittest.TestCase):
    def setUp(self):
        AppInfo.init(__name__, CONFIG['default'])
        session_id=AppInfo.login("root","password")
        self.context=AppInfo.create_context(session_id)

    def test_execution(self):
        from iot_set_node_status import execute

        self._create_node(self.context)

        params={"data":
        {"node_name": {"value": "test", "value_old": None},
            "ip_address": {"value": "192.168.0.1", "value_old": None}, "source_id": {"value": "1", "value_old": None}   }}
        execute(self.context, {}, params)


        fetch=f"""
        <restapi type="insert">
            <table name="iot_log"/>
            <fields>
                <field name="name" value="Test"/>
                <field name="message" value="Testmessage!"/>
                <field name="node_name" value="test"/>
                <field name="source_id" value="1"/>
            </fields>
        </restapi>
        """
        fetchparser=FetchXmlParser(fetch, self.context)
        DatabaseServices.exec(fetchparser, self.context, run_as_system=True)




        params={"data":
        {"node_name": {"value": "test-1", "value_old": None},
            "ip_address": {"value": "192.168.0.1", "value_old": None}, "source_id": {"value": "1", "value_old": None}   }}
        #execute(self.context, {}, params)

    def tearDown(self):
        AppInfo.save_context(self.context, True)
        AppInfo.logoff(self.context)

    def _create_node(self, context):
        fetch=f"""
        <restapi type="select">
            <table name="iot_node" alias="n"/>
            <select>
                <field name="id" table_alias="n"/>
            </select>
            <filter>
                <condition field="id" value="9999" operator="="/>
            </filter>
        </restapi>
        """
        fetchparser=FetchXmlParser(fetch, context)
        rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)
        if not rs.get_eof():
            return

        fetch=f"""
        <restapi type="insert">
            <table name="iot_node"/>
            <fields>
                <field name="id" value="9999"/>
                <field name="name" value="test"/>
            </fields>
        </restapi>
        """
        fetchparser=FetchXmlParser(fetch, context)
        DatabaseServices.exec(fetchparser, context, run_as_system=True)


if __name__ == '__main__':
    unittest.main()
