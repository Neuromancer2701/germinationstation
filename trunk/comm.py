import time
import serial

ser = serial.Serial(2, 9600)
seconds = int(time.time())
timestr = str(seconds) + '\n'
print timestr 
print time.ctime(seconds) 


ser.write(timestr)
print(ser.readline())

