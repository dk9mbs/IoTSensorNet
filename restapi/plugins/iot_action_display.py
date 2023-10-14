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

    node_name=params['input']['node_name']
    display_text=""
    node_version=""

    if 'node_version' in params['input']:
        node_version=params['input']['node_version']

    rs=iot_common.get_node_by_node_name(context, node_name)
    iot_common.set_node_last_heard(context, node_name, node_version=node_version)

    if not rs.get_eof():
        display_text=rs.get_result()['display_template']

    template=JinjaTemplate.create_string_template(context, display_text)
    display_text=template.render({"rs": rs, "context": context})
    rs.close()

    display_text=display_text.replace("\"","").encode("utf-8","ignore").decode("ascii","ignore")
    params['output']=display_text
