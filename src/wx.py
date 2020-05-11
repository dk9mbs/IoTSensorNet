#!/usr/bin/python

#Scriptname: aprs_wx

import socket
import sys
import os
import time

TCP_IP = 'cwop.aprs.net'
#TCP_IP = 'rotate.aprs2.net'
#TCP_PORT = 10152
TCP_PORT =  14580
BUFFER_SIZE = 1024

call = sys.argv[1]
passwd = sys.argv[2]
celsius = sys.argv[3]
#dest = "APZ100"
dest = "APRS"

fahrenheit = round( float (  float(celsius) * 1.8 + 32 ))
fahrenheit = int( float(fahrenheit)  )
print "Celsius:" + str(celsius)
print "Fahrenheit:" + str(fahrenheit)

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((TCP_IP, TCP_PORT))
s.send ("user " + call + " pass " + passwd + "rn"+"\r\n")
data = s.recv(BUFFER_SIZE)
print data
time.sleep(2)

record=call + ">" + dest + ",TCPIP*:!5203.64N/01022.93E_.../...g...t0" + str(fahrenheit).zfill(2) + "r...p...P...h..b.....e1w\r\n"
print (record)

s.send (record)
data = s.recv(BUFFER_SIZE)
print data
