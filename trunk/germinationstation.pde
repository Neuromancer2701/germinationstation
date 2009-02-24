#include <DateTime.h>
#include <WProgram.h>
#include <avr/interrupt.h>  
#include <avr/io.h> 
#include <math.h> 
#include <FrequencyTimer2.h>

#define coldco -0.711
#define medco -0.432
#define hotco -0.368
#define Vc  0.0049         // 5V/1024bits
#define PERIOD 100
#define BAUD   9600

#define TIME_MSG_LEN  11   // time sync to PC is HEADER followed by unix time_t as ten ascii digits
#define TIME_HEADER  255   // Header tag for serial time sync message


//Input 
#define WIND_IN   0            //Thermistor of Air temp
#define EARTH_IN  1           //Thermistor of Soil temp
#define FIRE_IN   2           //Photocell
#define WATER_IN  3           //Resistor network for water 

//Output
#define WIND_OUT   7      //hair dryer
#define EARTH_OUT  6      //Heating PAd
#define FAN_OUT    5      //Fan
#define FIRE_OUT   4      //Lights
#define WATER_OUT  3      // Pump/TBD???



enum Elements {Earth, Wind, Fire, Water};

int volts = 0;


// AIR variables
#define set_pt_wind 82
int wind        = 0;
int w_temp     = 0;
int wind_timer  = 0;
int wind_period = 0;

// Earth variables
#define set_pt_earth 82
int earth = 0;                  // variable to store the value coming from the sensor
int e_temp = 0;
int earth_timer  = 0;
int earth_period = 0;

// Fire variables
#define sun 650
int fire = 0;                  // variable to store the value coming from the sensor

// Water variables
#define dry 82
#define wet 82
#define moist 82
int water = 0;                  // variable to store the value coming from the sensor


//PID Arrays
int error[4] ={0,0,0,0};
int error_past[4] = {0,0,0,0};
int duty[4] = {0,0,0,0};
int P[4] = {4,4,4,4};                    //Proportional Constant
int I[4] = {4,4,4,4};                    //Integral Constant
int D[4] = {4,4,4,4};                    //Derivative Constant





unsigned long count100ms = 0;
 void counting(void) {
  count100ms++;
}

void setup() 
{

  Serial.begin(BAUD);                         // use the serial port to send the values back to the computer
  pinMode(WIND_OUT, OUTPUT);  
  digitalWrite(WIND_OUT, LOW);
  
  FrequencyTimer2::setPeriod(2030);           // 1ms  
  FrequencyTimer2::setOnOverflow(counting);
  
}

void loop() 
{
	wind = analogRead(WIND_IN);    				// read the value from the sensor Air Thermistor
	w_temp = calTemp(wind,set_pt_wind);
        PID(



	earth = analogRead(EARTH_IN);    			// read the value from the sensor Soil Thermistor
	e_temp = calTemp(earth,set_pt_earth);

	fire = analogRead(FIRE_IN);    			        // read the value from the sensor PhotoCell
	water = analogRead(WATER_IN);    			// read the value from the sensor Mositure sensor


/*
	if(air_period == (count100ms/1000) )
	{
	  digitalWrite(AIR_OUT, HIGH);
	  air_timer  = duty   + (count100ms/1000);
	  air_period = PERIOD + (count100ms/1000);
	}

	if(air_timer == (count100ms/1000))	digitalWrite(AIR_OUT, LOW);


	if((count100ms % 1000) == 0)
	{
	Serial.print("Seconds: ");
	Serial.println(count100ms/1000);
	Serial.print("Period: ");
	Serial.println(air_period);
	Serial.print("Duty: ");
	Serial.println(air_timer);
	Serial.println(a_temp);
	}
*/
}


boolean getPCtime() 
{
  // if time sync available from serial port, update time and return true
  while(Serial.available() >=  TIME_MSG_LEN )
  {  // time message consists of a header and ten ascii digits
    if( Serial.read() == TIME_HEADER ) 
    {        
      time_t pctime = 0;
      for(int i=0; i < TIME_MSG_LEN -1; i++)
      {   
        char c= Serial.read();          
        if( c >= '0' && c <= '9')
        {   
          pctime = (10 * pctime) + (c - '0') ; // convert digits to a number    
        }
      }   
      DateTime.sync(pctime);   // Sync Arduino clock to the time received on the serial port
      return true;   // return true if time message received on the serial port
    }  
  }
  return false;  //if no message return false
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

  if(error[elem] < 0) error[elem] = 0;

  duty[elem] = P[elem]*error[elem] + (I[elem]*(error[elem] + error_past[elem])/2) +(D[elem]*(error[elem]-error_past[elem])/2);
  if(duty[elem] < 100) duty[elem] = 100;
}
