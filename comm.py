import time
from time import sleep
import serial

start    = 'G'
SyncTime = 'ST'
SetP     = 'SP'
earth    = 1
wind     = 2

ser = serial.Serial(14, 38400)
seconds = int(time.time())
timestr = start + SyncTime + str(seconds) +'\n'
print "Unix Time:"
print timestr 
#print time.ctime(seconds)

print start + SetP + str(earth) + "312" + '\n'
'''
ser.write(start + SetP + str(earth) + "312" + '\n')
print "Before: "
print(ser.readline())
print "After: "
print(ser.readline())


ser.write(timestr)
sleep(1) #sleeps for 1 seconds
print "data buff: "
print(ser.readline())
print "Arduino Time: "
print(ser.readline())
print "Hour: "
print(ser.readline())
print "Minute: "
print(ser.readline())
print "Second: "
print(ser.readline())
'''





