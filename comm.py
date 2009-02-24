import time
import serial

ser = serial.Serial(1, 38400)
seconds = int(time.time())
timestr = str(seconds) + '\n'
print(timestr)
print(time.ctime(seconds))
ser.write(str(int(time.time())))
