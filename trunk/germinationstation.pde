#include <DateTime.h>
#include <WProgram.h>
#include <avr/interrupt.h>  
#include <avr/io.h> 
#include <math.h> 
#include <FrequencyTimer2.h>

#define coldco 		-0.711
#define medco 		-0.432
#define hotco 		-0.368
#define Vc  		0.0049      // 5V/1024bits
#define PERIOD 		100			// All periods will be 100 ticks  Timing with be determined by the Element period
#define BAUD		9600
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
#define FAN_OUT    	5      //Fan
#define FIRE_OUT   	4      //Lights
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
#define SUN_RISE        6     // 6:00am
#define SUN_SET        20    // 8:00pm
int fire = 0;                  	// variable to store the value coming from the sensor

// Water variables
#define dry 		82
#define wet 		82
#define moist 		82
int water = 0;                  // variable to store the value coming from the sensor


//PID Arrays
int error[4] ={0,0,0,0};
int error_past[4] = {0,0,0,0};
int duty[4] = {0,0,0,0};
int P[4] = {4,4,4,4};                    //Proportional Constant
int I[4] = {4,4,4,4};                    //Integral Constant
int D[4] = {4,4,4,4};                    //Derivative Constant





unsigned long count1ms = 0;
 void counting(void) {
  count1ms++;
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
  
        while( !getPCtime());                                   // Wait until program is synced
  
        Serial.print("Clock synced at: ");
        Serial.println(DateTime.now(),DEC);
  
  
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



	if((count1ms % 1000) == 0)				//Debug/variable feed
	{
	Serial.print("Seconds: ");
	Serial.println(count1ms/1000);
	Serial.print("Period: ");
	Serial.println(wind_period);
	Serial.print("Duty: ");
	Serial.println(wind_timer);
	Serial.println(w_temp);
	}

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

void set_timers()
{
	if(wind_period == (count1ms/WIND_DIVISOR) )
	{
	  digitalWrite(WIND_OUT, HIGH);
	  wind_timer  = duty[Wind]   + (count1ms/WIND_DIVISOR);
	  wind_period = PERIOD + (count1ms/WIND_DIVISOR);
	}

	if(wind_timer == (count1ms/WIND_DIVISOR))	digitalWrite(WIND_OUT, LOW);
	
	
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

  if( (DateTime.Hour >= SUN_RISE && DateTime.Hour <= SUN_SET) && light < SUN)
  {
    digitalWrite(FIRE_OUT, HIGH);
  }
  else
  {
    digitalWrite(FIRE_OUT, LOW);
  }
  
}

