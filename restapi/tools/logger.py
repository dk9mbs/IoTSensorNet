import serial
import time
import datetime

ser = serial.Serial('/dev/ttyUSB0', baudrate=115200)
ser.flushInput()

while True:
    try:
        ser_bytes = ser.readline()
        line=ser_bytes.decode(errors='ignore')
        print(line.replace('\n',''))
        with open("/tmp/iotlog.txt","a") as f:
            f.write(f"{datetime.datetime.now()} {line}")
    except Exception as err:
        print(err)

