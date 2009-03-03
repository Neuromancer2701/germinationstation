import time
from time import sleep
import serial

ser = serial.Serial(3, 9600)
seconds = int(time.time())
timestr = str(seconds) + '\n'
print "Unix Time:"
print timestr 
#print time.ctime(seconds) 


ser.write(timestr)
sleep(1) #sleeps for 1 seconds
print "Arduino Time:"
print(ser.readline())

