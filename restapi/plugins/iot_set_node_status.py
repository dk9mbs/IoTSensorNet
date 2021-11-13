import datetime

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log

logger=log.create_logger(__name__)

def __validate(params):
    if 'data' not in params:
        return False
    if 'node_name' not in params['data']:
        return False
    if 'ip_address' not in params['data']:
        return False
    if 'source_id' not in params['data']:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params")
        return

    node_name=params['data']['node_name']['value']
    ip_address=params['data']['ip_address']['value']
    source_id=params['data']['source_id']['value']
    node_id=0
    now=datetime.datetime.now()

    fetch=f"""
    <restapi type="select">
        <table name="iot_node" alias="n"/>
        <select>
            <field name="id" table_alias="n"/>
        </select>
        <filter>
            <condition field="name" value="{node_name}" operator="="/>
        </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)
    print(rs.get_result())
    if rs.get_eof():
        _add_log_item(context, "Node not found", f"Node {node_name} not registered in iot_node or deactivated",node_name, 100)
        raise Exception(f"Node not registered: {node_name}")

    node_id=rs.get_result()['id']
    rs.close()
    params['data']['node_id']={"value": node_id, "value_old": None}

    fetch=f"""
    <restapi type="update">
        <table name="iot_node"/>
        <fields>
            <field name="last_heard_on" value="{now}"/>
            <field name="ip_address" value="{ip_address}"/>
        </fields>
        <filter>
            <condition field="id" value="{node_id}"/>
        </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)

def _add_log_item(context,name, message, node_name, source_id):
    fetch=f"""
    <restapi type="insert">
        <table name="iot_log"/>
        <fields>
            <field name="source_id" value="{source_id}"/>
            <field name="name" value="{name}"/>
            <field name="message" value="{message}"/>
            <field name="node_name" value="{node_name}"/>
        </fields>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)


