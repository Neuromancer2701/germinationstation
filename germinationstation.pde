#include <DateTime.h>
#include <WProgram.h>
#include <avr/interrupt.h>  
#include <avr/io.h> 
#include <math.h> 
#include <FrequencyTimer2.h>
#include "string.h"

char incomingByte[17] = {""};	// for incoming serial data
char dataflag = 0;

char synctime[] = "ST";
char setP[] =     "SP";
char setI[] =     "SI";
char setD[] =     "SD";

#define coldco 		-0.711
#define medco 		-0.432
#define hotco 		-0.368
#define Vc  		0.0049      // 5V/1024bits
#define PERIOD 		100			// All periods will be 100 ticks  Timing with be determined by the Element period
#define BAUD		38400
#define CLOCK      	2030		// 1ms timer does not match the function description

#define TIME_MSG_LEN	11   	// time sync to PC is HEADER followed by unix time_t as ten ascii digits
#define TIME_HEADER		255   	// Header tag for serial time sync message


//Input 
#define WIND_IN   	0           //Thermistor of Air temp
#define EARTH_IN  	1           //Thermistor of Soil temp
#define FIRE_IN   	2           //Photocell
#define WATER_IN  	3           //Resistor network for water 

//Output
#define WIND_OUT   	7      //hair dryer
#define EARTH_OUT  	6      //Heating Pad
#define FIRE_OUT    	5      //Fan
#define FAN_OUT   	4      //Lights
#define WATER_OUT  	3      // Pump/TBD???



enum Elements {Earth, Wind, Fire, Water};

int volts = 0;


// AIR variables
#define set_pt_wind 	75
#define WIND_DIVISOR 	1000
int wind        = 0;
int w_temp     = 0;
int wind_timer  = 0;
int wind_period = 0;			//Wind period = 100sec  = 100 Ticks  1000ms/tick

// Earth variables
#define set_pt_earth 	80
#define EARTH_DIVISOR 	100       //Determines number of 1ms in a tick  there will always be 100 ticks in a period     
int earth = 0;                  // variable to store the value coming from the sensor
int e_temp = 0;
int earth_timer  = 0;			// duty cycle + counter
int earth_period = 0;			//Earth period = 10sec  = 100 Ticks  100ms/tick


// Fire variables
#define SUN 		650		   	//Threshold when the sun comes out, lights go off and vice versa
#define SUN_RISE        11    // 6:00am EST
#define SUN_SET         1    // 8:00pm
int fire = 0;                  	// variable to store the value coming from the sensor

// Water variables
#define dry 		82
#define wet 		82
#define moist 		82
int water = 0;                  // variable to store the value coming from the sensor


//PID Arrays
float error[4] ={0,0,0,0};
float error_past[4] = {0,0,0,0};
float duty[4] = {0,0,0,0};
float P[4] = {4,4,4,4};                    //Proportional Constant
float I[4] = {4,4,4,4};                    //Integral Constant
float D[4] = {4,4,4,4};                    //Derivative Constant





unsigned long count1ms = 0;
 void counting(void) {
  count1ms++;
}

void setup() 
{

  Serial.begin(BAUD);                         // use the serial port to send the values back to the computer
  pinMode(WIND_OUT, OUTPUT);  
  digitalWrite(WIND_OUT, LOW);
  pinMode(EARTH_OUT, OUTPUT);  
  digitalWrite(EARTH_OUT, LOW);
  pinMode(FIRE_OUT, OUTPUT);  
  digitalWrite(FIRE_OUT, LOW);  

  
  FrequencyTimer2::setPeriod(2030);           // 1ms  
  FrequencyTimer2::setOnOverflow(counting);
  
  while( DateTime.status != dtStatusSync)  // Wait until program is synced 
  {
    readSerialString(incomingByte);
    if(dataflag)
    {
      parsedata(incomingByte);
      dataflag = 0;
    }
  }
  
  
        

  
}

void loop() 
{

  
  
        wind = analogRead(WIND_IN);    				// read the value from the sensor Air Thermistor        
        w_temp = calTemp(wind,set_pt_wind);
        PID(set_pt_wind, w_temp, Wind);
        delay(5);

	earth = analogRead(EARTH_IN);    			// read the value from the sensor Soil Thermistor
	e_temp = calTemp(earth,set_pt_earth);
        PID(set_pt_earth, e_temp, Earth);
        delay(5);

	fire = analogRead(FIRE_IN);    			        // read the value from the sensor PhotoCell
        delay(5);
	//water = analogRead(WATER_IN);    			// read the value from the sensor Mositure sensor
        //delay(5);
        
        set_timers();
        set_fire(fire);


        
        
	if((count1ms % 100) == 0)				//Debug/variable feed
	{

  
  /*
	Serial.print("Wind: ");
	Serial.println(w_temp);
	Serial.print("Earth: ");
	Serial.println(e_temp);
	Serial.print("Fire: ");
	Serial.println(fire);
        Serial.print("Hour: ");
	Serial.println(int(DateTime.Hour));
*/
	}

}

int calTemp(int bits, int setpoint)
{
  int temp = 0;
  volts = int (bits * Vc * 100);

  if(volts > 466)
  {
    temp = setpoint;
  }
  else if(volts > 418 && volts <= 466)
  {
    temp = volts*coldco + 347;
  }
  else if(volts > 336 && volts <= 418)
  {
    temp = volts*medco + 230;
  }
  else if(volts > 234 && volts <= 336)
  {
    temp = volts*hotco + 208;
  }
  else
  {
    temp = setpoint;
  }

  return temp;
}


void PID(int setpt, int tempnow, char elem)
{
  duty[elem] = 0;
  
  error_past[elem] = error[elem];
  error[elem] = setpt - tempnow;

  if(error[elem] < 0) 
  {
    if(elem == Wind)
    {}
    else
    {
      error[elem] = 0;
    }
  }

  duty[elem] = P[elem]*error[elem] + (I[elem]*(error[elem] + error_past[elem])/2) +(D[elem]*(error[elem]-error_past[elem])/2);
  if(duty[elem] >  100) duty[elem] =  100;
  if(duty[elem] < -100) duty[elem] = -100;
  
  
}

void set_timers()
{
  int wind_temp = 100;
  
	if(wind_period == (count1ms/WIND_DIVISOR) )
	{
          if(duty[Wind] < 0)
          {
            wind_temp =+ duty[Wind];
            digitalWrite(FAN_OUT, HIGH);
          }
          else
          {
           wind_temp = duty[Wind];
	   digitalWrite(WIND_OUT, HIGH);
          }
          
	  wind_timer  = wind_temp   + (count1ms/WIND_DIVISOR);
	  wind_period = PERIOD + (count1ms/WIND_DIVISOR);
	}

	if(wind_timer == (count1ms/WIND_DIVISOR))	
        {
         digitalWrite(WIND_OUT, LOW);
         digitalWrite(FAN_OUT, LOW);
        }
	
	
	if(earth_period == (count1ms/EARTH_DIVISOR))
	{
	  digitalWrite(EARTH_OUT, HIGH);
	  earth_timer  = duty[Earth]   + (count1ms/EARTH_DIVISOR);
	  earth_period = PERIOD + (count1ms/EARTH_DIVISOR);
	}

	if(earth_timer == (count1ms/EARTH_DIVISOR))	digitalWrite(EARTH_OUT, LOW);
}
void set_fire(int light)  
{

  if((DateTime.Hour >= SUN_RISE && DateTime.Hour <= SUN_SET) && light < SUN)
  {
    digitalWrite(FIRE_OUT, HIGH);
  }
  else
  {
    digitalWrite(FIRE_OUT, LOW);
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
    char data[15]= {""};
    time_t pctime = 0;
    float temp = 0.00;
    
    
    strncpy( cmd, datastr, 2 );
    
    
    if(!int(strncmp(synctime,cmd,2)))
    {
      //Serial.println("Got the cmd!!! ");
      for(int z = 0; z <= 14; z++)
     {
      if(datastr[z+2] =='\n') break;
      
      if( datastr[z+2] >= '0' && datastr[z+2] <= '9')
      {
          pctime = (10 * pctime) + (datastr[z+2] - '0');
      }
      
      
     } 
     
      Serial.println(pctime);
      DateTime.sync(pctime);
      /*
      DateTime.available();
      Serial.println(DateTime.now(),DEC);
      Serial.println(DateTime.Hour,DEC);
      Serial.println(DateTime.Minute,DEC);
      Serial.println(DateTime.Second,DEC);
      */
    } 
    else if (!strcmp(setP,cmd))
    {
      Serial.println(P[Earth]);
     
      for(int q = 0; q <= 2; q++)
      {
        data[q] = datastr[q+3];        
      }
      Serial.println(temp);
      temp = float(int(data)/100);
      switch(int(datastr[2]))
      {
        case Earth:
            P[Earth] = temp;
            Serial.println(P[Earth]*100);
            break;
        case Wind:
            P[Wind] = temp;
            break;
        case Water:
            P[Water] = temp;
            break;    
        case Fire:
            P[Fire] = temp;
            break;
      }
    }
    else if (!strcmp(setI,cmd))
    {}
    else if (!strcmp(setD,cmd))
    {}
    else{}
  
}
