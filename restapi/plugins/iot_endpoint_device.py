import iot_common
from core import log
from core.appinfo import AppInfo
from services.jinjatemplate import JinjaTemplate
from core.jinjaenv import JinjaEnvironment

from flask import abort
#from flask import Blueprint
from flask import request, g, abort
from flask_restplus import Resource, Api, reqparse
from core.exceptions import RestApiNotAllowed
from core import log

from plugins.iot_action_device_switch import execute as execute_switch


logger=log.create_logger(__name__)

def create_parser_get():
    parser=reqparse.RequestParser()
    parser.add_argument('internal_device_id',type=str, help='Internal device id', location='query')
    parser.add_argument('value',type=str, help='Value to set', location='query')
    parser.add_argument('command',type=str, help='Device command', location='query')
    return parser

def create_parser_put():
    parser=reqparse.RequestParser()
    return parser

def create_parser_delete():
    parser=reqparse.RequestParser()
    return parser


class IotDevice(Resource):
    api=AppInfo.get_api()

    @api.doc(parser=create_parser_get())
    def post(self,internal_device_id,value,command):
        try:
            create_parser_get().parse_args()
            context=g.context

            params={'input': {}}
            params['output']={}
            plugin_context={"config": {}}
            params['input']['session_id']=context.get_session_id()
            params['input']['command']=command
            params['input']['value']=value
            params['input']['device']=internal_device_id
            execute_switch(context, plugin_context, params)

            result="OK"

            return result

        except RestApiNotAllowed as err:
            abort(400, f"{err}")
        except Exception as err:
            abort(500,f"{err}")

def get_endpoint():
    return IotDevice
