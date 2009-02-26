import time
import serial

ser = serial.Serial(7, 9600,timeout=5)
seconds = int(time.time())
timestr = str(seconds) + '\n'
print timestr 
#print time.ctime(seconds) 


ser.write(timestr)
print(ser.readline())
print(ser.readline())
print(ser.readline())
print(ser.readline())
print(ser.readline())
print(ser.readline())
print(ser.readline())


