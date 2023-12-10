import iot_common
from plugins.iot_endpoint_device import get_endpoint
from core import log
from core.appinfo import AppInfo
from services.jinjatemplate import JinjaTemplate
from core.jinjaenv import JinjaEnvironment
from plugins.iot_action_device_switch import execute as execute_switch

logger=log.create_logger(__name__)


def execute(context, plugin_context, params):
    JinjaEnvironment.register_template_function('iot_get_numeric_sensor_value', iot_common.get_numeric_sensor_value)
    JinjaEnvironment.register_template_function('iot_get_sensor_value', iot_common.get_sensor_value)
    logger.info("Init Iot jinja2 functions... done")

    AppInfo.get_api("solution").add_resource(get_endpoint(),"/iot/v1.0/device/<internal_device_id>/<value>/<command>", methods=['POST'])
    AppInfo.get_api("solution").add_resource(get_endpoint(),"/iot/v1.0/device/<internal_device_id>/<value>/<port>/<command>", methods=['POST'])
    logger.info("Add endpoint for control iot devices... done")






