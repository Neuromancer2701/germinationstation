import time
import msvcrt
from time import sleep
import serial

start    = 'G'
SyncTime = 'ST'
SetP     = 'SP'
earth    = 1
wind     = 2
tab      = '\t'


class dataset:
    def __init__(self):
        self.ardtime = []
        self.e_temp  = []
        self.w_temp  = []
        self.water   = []
        self.fire    = []
        self.duty_e  = []
        self.duty_w  = []
        self.hour    = []
        
    def parse_data(self,datastream):
        self.ardtime   = datastream[0:10]
        self.e_temp    = datastream[10:14]
        self.w_temp    = datastream[14:18]
        self.water     = datastream[18:22]
        self.fire      = datastream[22:26]
        self.duty_e    = datastream[26:29]
        self.duty_w    = datastream[29:32]
        self.hour      = datastream[32:34]
        
    def printdata(self):
        if len(self.ardtime) > 0 :
            print "The time is:" + self.ardtime
            print "Earth Temp:" + self.e_temp
            print "Wind Temp:" + self.w_temp
            print "Mositure Value:" + self.water
            print "Brightness:" + self.fire
            print  "Earth Duty:" + self.duty_e
            print "Wind Duty:" + self.duty_w
            print "Hour:" + self.hour
        
    def savestr(self):
        return self.ardtime + tab + self.e_temp + tab + self.w_temp + tab + self.water + tab + self.fire +'\n'




def sendtime ():
    seconds = int(time.time())
    timestr = start + SyncTime + str(seconds) +'\n'
    return timestr


    

f = open('C:\\temp\\values.dat', 'a')

arduinodata = dataset()

ser = serial.Serial(3, 38400)


sent_time = sendtime()
print sent_time
ser.write(sendtime())
rec_time = ser.readline()
print rec_time

while True:
    text = ser.readline()
    print text
    arduinodata.parse_data(text)
    arduinodata.printdata()
    time.sleep(1)
    '''
    if msvrt.kbhit():
        if ord(msvcrt.getch()) == 27:
            break

'''   
'''
    f.write(arduinodata.savestr())

f.close()
print "DONE!!"
'''
