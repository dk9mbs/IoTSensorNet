from flask import g
import datetime

from core.fetchxmlparser import FetchXmlParser
from core import log
from services.database import DatabaseServices
from services.fetchxml import build_fetchxml_by_alias
from services.numerictools import isnumeric

logger=log.create_logger(__name__)

def set_node_last_heard(context, node_name):
    now=datetime.datetime.now()
    fetch=f"""
    <restapi type="update">
        <table name="iot_node"/>
        <fields>
            <field name="last_heard_on" value="{now}"/>
        </fields>
        <filter>
            <condition field="name" value="{node_name}" operator="="/>
        </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)

def set_ip_address(context, node_name, ip_address):
    fetch=f"""
    <restapi type="update">
        <table name="iot_node"/>
        <fields>
            <field name="ip_address" value="{ip_address}"/>
        </fields>
        <filter>
            <condition field="name" value="{node_name}" operator="="/>
        </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)


def set_node_version(context, node_name, node_version):
    if node_version=="":
        node_version="???"

    fetch=f"""
    <restapi type="update">
        <table name="iot_node"/>
        <fields>
            <field name="version" value="{node_version}"/>
        </fields>
        <filter>
            <condition field="name" value="{node_name}" operator="="/>
        </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)


def get_node_by_node_name(context, node_name):
    fetch=f"""
    <restapi type="select">
        <table name="iot_node" alias="n"/>
        <select>
            <field name="id" table_alias="n"/>
            <field name="display_template" table_alias="n"/>
        </select>
        <filter>
            <condition field="name" value="{node_name}" operator="="/>
        </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)
    return rs


def get_numeric_sensor_value(context, sensor_id, field_name, format="", default_value=0):
    value= __get_sensor_by_sensor_id(context,sensor_id,field_name, format=format, default_value=default_value)

    if value==__error_not_found():
        logger.error(f"Error not found:{value}")
        return default_value

    if format!="" and isnumeric(value):
        return format.format(float(value))
    else:
        logger.error(f"Value is not numeric! :{value}")
        return default_value


def get_sensor_value(context, sensor_id, field_name, default_value=""):
    return __get_sensor_by_sensor_id(context,sensor_id,field_name, default_value=default_value)


class IotLocation:
    def __init__(self, context, device_id: str):
        self._location_gateway_url=""
        self._location_gateway_topic=""
        self._location_gateway_protocol="mqtt"
        self._context=context
        self._device_id=device_id
        self._get_location_url()

    def get_location_gateway_topic(self):
        return self._location_gateway_topic

    def get_location_gateway_protocol(self):
        return self._location_gateway_protocol

    def get_location_gateway_url(self):
        return self._location_gateway_url

    def _get_location_url(self) -> bool():
        context=self._context
        device_id=self._device_id
        fetch_xml=f"""<restapi type="select">
        <table name="iot_device" alias="d"/>
        <filter type="or">
            <condition field="internal_device_id" alias="r" value="{device_id}" operator="="/>
        </filter>
        <joins>
            <join type="inner" table="iot_device_routing" alias="r" condition="r.external_device_id=d.id"/>
            <join type="inner" table="iot_location" alias="l" condition="d.location_id=l.id"/>
        </joins>
        <orderby>
            <field name="created_on" alias="d" sort="DESC"/>
        </orderby>
        <select>
            <field name="id" table_alias="d"/>
            <field name="location_id" table_alias="d"/>
            <field name="local_gateway_url" table_alias="l"/>
            <field name="local_gateway_topic" table_alias="l"/>
            <field name="local_gateway_protocol" table_alias="l"/>
        </select>
        </restapi>"""
        fetchparser=FetchXmlParser(fetch_xml, context)
        rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=False)

        if rs.get_eof():
            raise Exception(f"Location for {device_id} not found!")

        loc=rs.get_result()

        if loc['local_gateway_protocol']=="http" and (loc['local_gateway_url'] == '' or loc['local_gateway_url'] == None):
            raise Exception(f"Location url for {device_id} is empty!")

        if loc['local_gateway_protocol']=="mqtt" and (loc['local_gateway_topic'] == '' or loc['local_gateway_topic'] == None):
            raise Exception(f"Location topic for {device_id} is empty!")

        self._location_gateway_protocol=loc['local_gateway_protocol']
        self._location_gateway_topic=loc['local_gateway_topic']
        self._location_gateway_url=loc['local_gateway_url']

        return True


def __get_sensor_by_sensor_id(context, sensor_id, field_name, format="", default_value=""):
    fetch=f"""
    <restapi type="select">
    <table name="iot_sensor" alias="s"/>
    <select>
        <field name="{field_name}" table_alias="s" alias="value"/>
    </select>
    <filter>
        <condition field="id" value="{sensor_id}" operator="="/>
    </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)

    if rs.get_eof():
        rs.close()
        logger.error(f"Error not found:{fetch}")
        return __error_not_found

    value=rs.get_result()['value']
    rs.close()

    if format!="" and isnumeric(value):
        return format.format(float(value))
    else:
        return value

def __error_not_found():
    return "!na"

