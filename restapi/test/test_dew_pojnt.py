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

    def test_calc_dew_point(self):
        from iot_lib_dew_point import iot_LibDewPoint
        dew_point=iot_LibDewPoint(23.2, 68.0)
        dew_point.calc()
        self.assertEqual(dew_point.get_dew_point(), 16.97)

    def tearDown(self):
        AppInfo.save_context(self.context, True)
        AppInfo.logoff(self.context)

if __name__ == '__main__':
    unittest.main()
