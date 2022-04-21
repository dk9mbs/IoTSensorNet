import iot_common
from core import log
from services.jinjatemplate import JinjaTemplate
from core.jinjaenv import JinjaEnvironment



logger=log.create_logger(__name__)

def execute(context, plugin_context, params):
    JinjaEnvironment.register_template_function('iot_get_numeric_sensor_value', iot_common.get_numeric_sensor_value)
    JinjaEnvironment.register_template_function('iot_get_sensor_value', iot_common.get_sensor_value)
    logger.info("Init Iot jinja2 functions... done")
