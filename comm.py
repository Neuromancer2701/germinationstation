import time
import msvcrt
from time import sleep
import serial

start    = 'G'
SyncTime = 'ST'
SetP     = 'SP'
getdata  = 'GD'
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
        self.earth_timer   = []
        self.earth_period  = []
        self.wind_timer    = []
        self.wind_period   = []
        
    def parse_data(self,datastream):
        self.ardtime   = datastream[0:10]
        self.e_temp    = datastream[10:14]
        self.w_temp    = datastream[14:18]
        self.water     = datastream[18:22]
        self.fire      = datastream[22:26]
        self.duty_e    = datastream[26:29]
        self.duty_w    = datastream[29:32]
        self.hour      = datastream[32:34]
        self.earth_timer   = datastream[34:44]
        self.earth_period  = datastream[44:54]
        self.wind_timer    = datastream[54:64]
        self.wind_period   = datastream[64:74]
        
    def printdata(self):
        if str.isalnum(self.ardtime):
            print "The time is:" + self.ardtime
            print "Earth Temp:" + self.e_temp
            print "Wind Temp:" + self.w_temp
            print "Mositure Value:" + self.water
            print "Brightness:" + self.fire
            print  "Earth Duty:" + self.duty_e
            print "Wind Duty:" + self.duty_w
            print "Hour:" + self.hour
            print "Earth Timer:" + self.earth_timer
            print "Earth Period:" + self.earth_period
            print "Wind Timer:" + self.wind_timer
            print "Wind Period:" + self.wind_period
            
    def savestr(self):
        return self.ardtime + tab + self.e_temp + tab + self.w_temp + tab + self.water + tab + self.fire +'\n'




def sendtime ():
    seconds = int(time.time())
    timestr = start + SyncTime + str(seconds) +'\n'
    return timestr

def checkkeypress(): 
    """
    Waits for the user to press a key. Returns the ascii code 
    for the key pressed or zero for a function key pressed.
    """                             
    import msvcrt               
    if msvcrt.kbhit():              # Key pressed?
        a = ord(msvcrt.getch())     # get first byte of keyscan code     
        if a == 'S':      # is it a function key?
            return True
    else:
        return False
    
def iswaiting(ser_device):
    if ser_device.isOpen():
        data = ser_device.readline()
        if data.find("Waiting"):
            return True
    else:
        return False
        
    
    
    
    




    

#f = open('C:\\temp\\values.dat', 'a')

arduinodata = dataset()

print "Set Serial"
ser = serial.Serial(3, 38400)

'''
while not iswaiting(ser):
    print "waiting for Sync"
    
sent_time = sendtime()
print sent_time
ser.write(sendtime())
rec_time = ser.readline()
print rec_time
'''

while True:
    ser.write(start+getdata)
    text = ser.readline()
    print text
    arduinodata.parse_data(text)
    arduinodata.printdata()
    sleep(3)
