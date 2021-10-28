import unittest
from decimal import Decimal

from core.database import CommandBuilderFactory
from core.database import FetchXmlParser
from config import CONFIG
from core.appinfo import AppInfo
from core.plugin import Plugin
from services.database import DatabaseServices

class TestPluginExecution(unittest.TestCase):
    def setUp(self):
        AppInfo.init(__name__, CONFIG['default'])
        session_id=AppInfo.login("root","password")
        self.context=AppInfo.create_context(session_id)

    def test_execution(self):
        sensor1="sensor001"
        sensor2="sensor002"
        sensor3="sensor003"
        external_sensor="ext0815"
        value1=87.0000
        value2=15.0000
        value3=99.0000

        self.__delete_sensor(sensor1)
        self.__delete_sensor(sensor2)
        self.__delete_sensor(sensor3)
        self.__delete_sensor(external_sensor)

        #create one sensor
        self.__create_sensor(sensor1, sensor1, sensor1)
        self.__insert_sensor_data(sensor1, value1)

        last_value=self.__read_last_value(sensor1)
        self.assertEqual(last_value, value1)

        # routing from external to internal
        # set value on sensor2 over the external id
        self.__create_sensor(sensor2, sensor2, sensor2)
        self.__create_routing(external_sensor, sensor2)
        self.__insert_sensor_data(external_sensor, value2)

        last_value=self.__read_last_value(sensor1)
        self.assertEqual(last_value, value1)

        last_value=self.__read_last_value(sensor2)
        self.assertEqual(last_value, value2)

        #
        # create sensor and assign automaticly
        #
        self.__create_sensor(sensor3, sensor3, sensor3)
        self.__insert_sensor_data(sensor3, value3)
        last_value=self.__read_last_value(sensor3)
        self.assertEqual(last_value, value3)



    def __read_last_value(self, sensor_id):
        fetch=f"""
        <restapi type="select">
            <table name="iot_sensor" alias="s"/>
            <select>
                <field name="last_value" table_alias="s"/>
            </select>
            <filter type="or">
                <condition field="id" value="{sensor_id}" operator="="/>
            </filter>
        </restapi>
        """
        fetchparser=FetchXmlParser(fetch, self.context)
        rs=DatabaseServices.exec(fetchparser, self.context,fetch_mode=1, run_as_system=True)
        return Decimal(rs.get_result()['last_value'])

    def __insert_sensor_data(self, sensor_id, value):
        fetch=f"""
        <restapi type="insert">
            <table name="iot_sensor_data"/>
            <fields>
                <field name="sensor_id" value="{sensor_id}"/>
                <field name="sensor_namespace" value="testns"/>
                <field name="sensor_value" value="{value}"/>
            </fields>
        </restapi>
        """

        fetchparser=FetchXmlParser(fetch, self.context)
        DatabaseServices.exec(fetchparser, self.context, run_as_system=True)

    def __delete_sensor(self, sensor_id):
        fetch=f"""
        <restapi type="delete">
            <table name="iot_sensor"/>
            <filter>
                <condition field="id" value="{sensor_id}" operator="="/>
            </filter>
        </restapi>
        """
        fetchparser=FetchXmlParser(fetch, self.context)
        DatabaseServices.exec(fetchparser, self.context, run_as_system=True)

        fetch=f"""
        <restapi type="delete">
            <table name="iot_sensor_routing"/>
            <filter type="or">
                <condition field="external_sensor_id" value="{sensor_id}" operator="="/>
                <condition field="internal_sensor_id" value="{sensor_id}" operator="="/>
            </filter>
        </restapi>
        """
        fetchparser=FetchXmlParser(fetch, self.context)
        DatabaseServices.exec(fetchparser, self.context, run_as_system=True)


    def __create_sensor(self, sensor_id, alias, description):
        fetch=f"""
        <restapi type="insert">
            <table name="iot_sensor"/>
            <fields>
                <field name="id" value="{sensor_id}"/>
                <field name="alias" value="{alias}"/>
                <field name="description" value="{description}"/>
            </fields>
        </restapi>
        """
        fetchparser=FetchXmlParser(fetch, self.context)
        DatabaseServices.exec(fetchparser, self.context, run_as_system=True)

    def __create_routing(self, external_sensor_id, internal_sensor_id):
        fetch=f"""
        <restapi type="insert">
            <table name="iot_sensor_routing"/>
            <fields>
                <field name="internal_sensor_id" value="{internal_sensor_id}"/>
                <field name="external_sensor_id" value="{external_sensor_id}"/>
                <field name="description" value="Integrationtest"/>
            </fields>
        </restapi>
        """
        fetchparser=FetchXmlParser(fetch, self.context)
        DatabaseServices.exec(fetchparser, self.context, run_as_system=True)


    def tearDown(self):
        AppInfo.save_context(self.context, True)
        AppInfo.logoff(self.context)

if __name__ == '__main__':
    unittest.main()
