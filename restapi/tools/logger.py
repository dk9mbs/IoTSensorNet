import argparse
import serial
import time
import datetime
import glob
from clientlib import RestApiClient


parser = argparse.ArgumentParser(description='Administrate the restapi.')
parser.add_argument('--username','-u', type=str, help='Restapi username')
parser.add_argument('--password','-p', type=str, help='Restapi password')
parser.add_argument('--url','-U', type=str, help='http://localhost:5000/api')
parser.add_argument('--tag','-t', type=str, help='Field name in iot_log protocol')
args = parser.parse_args()

url=args.url
username=args.username
password=args.password
tag = args.tag

if tag==None:
    tag="Serial DEBUG"

rest=RestApiClient(url)
rest.login(username, password)

ser=None

def _add_log_item(name, message):
    data={"name" : name, "message": message.replace('\'', '\'\''), "source_id":2 }
    rest.create("iot_log",data)

def _get_serport():
    ports = glob.glob('/dev/ttyU[A-Za-z]*')
    while len(ports)==0:
        time.sleep(1.0)
        ports = glob.glob('/dev/ttyU[A-Za-z]*')

    ser = serial.Serial(ports[0], baudrate=115200)
    ser.flushInput()

    print (f"Serialport found: {ports[0]}")
    time.sleep(1.0)
    return ser


while True:
    try:
        if ser==None or ser.isOpen==False:
            print ("waiting for a serialport ...")
            ser=_get_serport()


        #print(ser)
        ser_bytes = ser.readline()
        line=ser_bytes.decode(errors='ignore')
        line=line.replace('\n','')
        print(f"{datetime.datetime.now()} {line}")
        _add_log_item(tag,line)
        with open("/tmp/iotlog.txt","a") as f:
            f.write(f"{datetime.datetime.now()} {line}")
    except Exception as err:
        print(err)
        if ser.isOpen==True:
            ser.close()
        ser=None

