import datetime

from core.fetchxmlparser import FetchXmlParser, escape_xml_value
from services.database import DatabaseServices
from core import log

logger=log.create_logger(__name__)

PARAMS_KEY="iot_sensor_throttle"

#
# Throttles the history in iot_sensor_data.
# before (iot_sensor_data/insert, sync, after routing, iot_setlast_value and
# dew point): decides and drops a value with plugin_context['cancel']=True.
# after (sync): sets store_last_* only if the insert was executed.
# All state is kept in iot_sensor.
#

def config():
    return {"raise_exception": False}

def _validate(params):
    if 'data' not in params:
        return False
    if 'sensor_value' not in params['data']:
        return False
    if 'sensor_id' not in params['data']:
        return False

    return True

def _to_float(value):
    if value==None or value=="":
        return None

    try:
        return float(value)
    except (TypeError, ValueError):
        return None

def _to_datetime(value):
    if value==None or value=="":
        return None

    if isinstance(value, datetime.datetime):
        return value

    return datetime.datetime.fromisoformat(str(value))

#
# Returns True if the value has to be stored. See spec chapter 5.
#
def must_store(value, now, min_interval_sec, max_interval_sec, deadband, last_value, last_on):
    if max_interval_sec==None:
        return True

    if last_on==None or last_value==None:
        return True

    elapsed=(now-last_on).total_seconds()
    # 4 decimals like the columns, otherwise 20.2-20.0 < 0.2
    delta=round(abs(value-last_value), 4)

    if elapsed>=max_interval_sec:
        return True

    if deadband!=None and deadband>0:
        if elapsed>=(min_interval_sec or 0) and delta>=deadband:
            return True

    return False

def _read_sensor(context, sensor_id):
    fetch=f"""
    <restapi type="select">
        <table name="iot_sensor"/>
        <select>
            <field name="store_min_interval_sec"/>
            <field name="store_max_interval_sec"/>
            <field name="store_deadband"/>
            <field name="store_last_value"/>
            <field name="store_last_on"/>
        </select>
        <filter>
            <condition field="id" value="{escape_xml_value(sensor_id)}"/>
        </filter>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)

    if rs.get_eof():
        return None

    return rs.get_result()

def _write_last_stored(context, sensor_id, value, now):
    fetch=f"""
    <restapi type="update">
        <table name="iot_sensor"/>
        <fields>
            <field name="store_last_value" value="{escape_xml_value(value)}"/>
            <field name="store_last_on" value="{escape_xml_value(now)}"/>
        </fields>
        <filter>
            <condition field="id" value="{escape_xml_value(sensor_id)}"/>
        </filter>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)

def execute(context, plugin_context, params):
    if plugin_context['type']=='after':
        _after(context, plugin_context, params)
    else:
        _before(context, plugin_context, params)

#
# Decides only. The value to remember is passed to the after phase in
# params[PARAMS_KEY] (not in params['data'], that is the sql).
#
def _before(context, plugin_context, params):
    if not _validate(params):
        logger.warning(f"Missings params")
        return

    value=_to_float(params['data']['sensor_value']['value'])
    sensor_id=params['data']['sensor_id']['value']

    # no number: store as before
    if value==None:
        return

    sensor=_read_sensor(context, sensor_id)
    if sensor==None:
        return

    max_interval_sec=_to_float(sensor['store_max_interval_sec'])
    if max_interval_sec==None:
        return

    now=datetime.datetime.now().replace(microsecond=0)

    store=must_store(value, now,
        _to_float(sensor['store_min_interval_sec']),
        max_interval_sec,
        _to_float(sensor['store_deadband']),
        _to_float(sensor['store_last_value']),
        _to_datetime(sensor['store_last_on']))

    if not store:
        plugin_context['cancel']=True
        return

    params[PARAMS_KEY]={"sensor_id": sensor_id, "value": value, "now": now}

#
# Runs only if the insert was executed. Remembers the stored value.
#
def _after(context, plugin_context, params):
    stored=params.get(PARAMS_KEY, None)
    if stored==None:
        return

    _write_last_stored(context, stored['sensor_id'], stored['value'], stored['now'])
