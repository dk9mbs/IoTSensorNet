import datetime

import iot_common
from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from services.fetchxml import build_fetchxml_by_alias
from core import log

from services.jinjatemplate import JinjaTemplate
from core.jinjaenv import JinjaEnvironment


logger=log.create_logger(__name__)

def __validate(params):
    if 'input' not in params:
        return False
    if 'node_name' not in params['input']:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params")
        return

    JinjaEnvironment.register_template_function('iot_get_numeric_sensor_value', iot_common.get_numeric_sensor_value)
    JinjaEnvironment.register_template_function('iot_get_sensor_value', iot_common.get_sensor_value)

    node_name=params['input']['node_name']
    display_text=""

    rs=iot_common.get_node_by_node_name(context, node_name)

    if not rs.get_eof():
        display_text=rs.get_result()['display_template']

    template=JinjaTemplate.create_string_template(context, display_text)
    display_text=template.render({"rs": rs, "context": context})
    rs.close()

    params['output']=display_text
