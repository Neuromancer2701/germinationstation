#include <DateTime.h>
#include <WProgram.h>
#include <avr/interrupt.h>  
#include <avr/io.h> 
#include <math.h> 
#include <FrequencyTimer2.h>
#include <stdlib.h>
#include "string.h"
#include "ctype.h"

char incomingByte[17] = {""};	// for incoming serial data
char dataflag = 0;

char synctime[] = "ST";
char setP[] =     "SP";
char setI[] =     "SI";
char setD[] =     "SD";

int earth_temp, wind_temp, water, fire = 0;
float duty[4] = {1.11,2.22,3.33,4.44};
unsigned long  time_stamp = 0;

char data_string[15] ={};
char earth_str[6]   ={};
char wind_str[6]    ={};
char water_str[6]   ={};
char fire_str[6]    ={};

unsigned long count1ms = 0;
 void counting(void) {
  count1ms++;
}

void setup() {
	Serial.begin(38400);	// opens serial port, sets data rate to 9600 bps
        FrequencyTimer2::setPeriod(2030);           // 1ms  
        FrequencyTimer2::setOnOverflow(counting);
}

void loop() {
  
  time_stamp = 1234567890; //DateTime.now();
  earth_temp = 68;
  wind_temp  = 77;
  water      = 1000;
  fire       = 650;
  
      /*itoa(earth_temp,earth_str,10);
      ltoa(time_stamp,data_string,10);
      Serial.println(earth_str);      
      Serial.println(data_string);*/
  if(count1ms % 1000 == 0)
  {
      ltoa(time_stamp,data_string,10);
      itoa(earth_temp,earth_str,10);
      padzero(data_string,(4 - strlen(earth_str)));
      strcat(data_string,earth_str);
      
      itoa(wind_temp,wind_str,10);
      padzero(data_string,(4 - strlen(wind_str)));
      strcat(data_string,wind_str);
      
      itoa(water,water_str,10);
      padzero(data_string,(4 - strlen(water_str)));
      strcat(data_string,water_str);

      itoa(fire,fire_str,10);
      padzero(data_string,(4 - strlen(fire_str)));
      strcat(data_string,fire_str);      
      
      //Serial.println(earth_str);      
      Serial.println(data_string);
    
 
    /*
      Serial.print(time_stamp);
      Serial.print(earth_temp);
      Serial.print(wind_temp);
      Serial.print(water);
      Serial.println(fire);
 */
  }
  
  /*
	// send data only when you receive data:
        readSerialString (incomingByte);
        if(dataflag)
        {
         parsedata(incomingByte);
         dataflag = 0;
        }*/
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

void padzero(char* str, int zeros)
{
  
    for(int q = 0; q < zeros; q++)
    {
         strcat(str,"0");
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
  
  
 
