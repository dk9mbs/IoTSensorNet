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
    if 'data' not in params:
        return False
    if 'node_name' not in params['data']:
        return False
    if 'node_version' not in params['data']:
        return False
    if 'ip_address' not in params['data']:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params")
        return

    node_name=params['data']['node_name']
    node_version=params['data']['node_version']
    ip_address=params['data']['ip_address']

    rs=iot_common.get_node_by_node_name(context, node_name)
    iot_common.set_node_last_heard(context, node_name)
    iot_common.set_node_version(context, node_name, node_version)
    iot_common.set_ip_address(context, node_name, ip_address)
