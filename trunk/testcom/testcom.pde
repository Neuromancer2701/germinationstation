#include "string.h"

char incomingByte[17] = {""};	// for incoming serial data
char dataflag = 0;

char synctime[] = "ST";
char setP[] =     "SP";
char setI[] =     "SI";
char setD[] =     "SD";


void setup() {
	Serial.begin(19200);	// opens serial port, sets data rate to 9600 bps
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
      //Serial.println("Got the G!!! ");
      delay(5);
      while (Serial.available()){            
      strArray[i] = Serial.read();
      delay(5);
       //Serial.print(strArray[(i-1)]);         //optional: for confirmation
      if(i == 16 || (strArray[i]=='\n')) break;
      i++;
    }
       //Serial.println();  
       dataflag = 1;
    }
  }      
}

void parsedata(char *datastr)
{
    char cmd[3]={'QQQ'};
    char data[15];
    int cmdflag;
    
    //Serial.println(datastr);
    strncpy( cmd, datastr, 2 );
    
    //cmdflag = int(strncmp(synctime,cmd,2));
    
    if(!int(strncmp(synctime,cmd,2)))
    {
      //Serial.println("Got the cmd!!! ");
      for(int z = 0; z <= 14; z++)
     {
      data[z] = datastr[z+2];
      if(data[z] =='\n') break;
     } 

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
  
  
 
