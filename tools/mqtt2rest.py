import sys
import json

import paho.mqtt.client as mqtt
from clientlib import RestApiClient

mqtt_username=sys.argv[1]
mqtt_password=sys.argv[2]
mqtt_broker=sys.argv[3]
rest_username=sys.argv[4]
rest_password=sys.argv[5]

rest=RestApiClient("http://localhost:5000/api")
rest.login(rest_username, rest_password)

# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("dk9mbs/iot/sensor/garden")
    client.subscribe("temp/sensor")

# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    print(msg.topic+" "+str(msg.payload))
    #{"temp":19.44, "address":"28AA13DA4F140142"}
    data=json.loads(msg.payload)
    value=0
    address=""
    if 'temp' in data:
        value=data['temp']
    if 'value' in data:
        value=data['value']
    if 'address' in data:
        address=data['address']

    if address != "":
        data={"sensor_id":address, "sensor_value": value, "sensor_namespace":"restapi"}
        try:
            print(rest.add("iot_sensor_data", data))
        except NameError as err:
            print(f"{err}")

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.username_pw_set(mqtt_username, mqtt_password)
client.connect(mqtt_broker, 1883, 60)

# Blocking call that processes network traffic, dispatches callbacks and
# handles reconnecting.
# Other loop*() functions are available that give a threaded interface and a
# manual interface.
client.loop_forever()


