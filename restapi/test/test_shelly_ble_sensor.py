import unittest

from core.database import CommandBuilderFactory
from core.database import FetchXmlParser
from config import CONFIG
from core.appinfo import AppInfo
from core.plugin import Plugin


class TestPluginExecution(unittest.TestCase):
    def setUp(self):
        AppInfo.init(__name__, CONFIG['default'])
        session_id=AppInfo.login("root","password")
        self.context=AppInfo.create_context(session_id)

    def test_execution(self):
        from iot_plugin_shelly_ble_sensor import execute

        false=False
        params={"data":
        {"addr":"7c:c6:b6:9e:f0:0b","rssi":-75,"local_name":"","service_data":
            {"encryption":false,"BTHome_version":2,"pid":238,"battery":100,"humidity":58,"temperature":23.3}}
        }
        execute(self.context, {}, params)

    def tearDown(self):
        AppInfo.save_context(self.context, True)
        AppInfo.logoff(self.context)

if __name__ == '__main__':
    unittest.main()
