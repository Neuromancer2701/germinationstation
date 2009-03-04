#include "string.h"

char incomingByte[17] = {"1234567890"};	// for incoming serial data
char dataflag = 0;

char synctime[] = "ST";
char setP[] =     "SP";
char setI[] =     "SI";
char setD[] =     "SD";


void setup() {
	Serial.begin(9600);	// opens serial port, sets data rate to 9600 bps
}

void loop() {

	// send data only when you receive data:
        readSerialString (incomingByte);
        if(dataflag)
        {
         parsedata(incomingByte);
         dataflag = 0;
        }
}


void readSerialString (char *strArray) 
{
  int i = 0;
  int data = 0;
  if(Serial.available()) {    
    //Serial.print("reading Serial String: ");  //optional: for confirmation
    data = Serial.read();
    if(data == 'G')
    {
      Serial.println("Got the G!!! ");
      while (Serial.available()){            
      strArray[i] = Serial.read();
      i++;
       //Serial.print(strArray[(i-1)]);         //optional: for confirmation
       if(i == 14) break;
      }
       //Serial.println();  
       dataflag = 1;
    }
  }      
}

void parsedata(char *datastr)
{
    char cmd[3]={'QQQ'};
    char data[11];
    int cmdflag;
    strncpy( cmd, datastr, 2 );

    Serial.print("Command: ");
    Serial.println(cmd);
    Serial.println(synctime);
    cmdflag = int(strncmp(synctime,cmd,2));
    Serial.println(cmdflag);
    Serial.println(!cmdflag);
    
    if(!cmdflag)
    {
      Serial.println("Got the cmd!!! ");
      strncpy( cmd, datastr, 2 );

      Serial.println(data);
    } 
    else if (!strcmp(setP,cmd))
    {}
    else if (!strcmp(setI,cmd))
    {}
    else if (!strcmp(setD,cmd))
    {}
    else{}
  
}
  
  
 
