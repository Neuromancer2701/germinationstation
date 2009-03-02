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
  pinMode(EARTH_OUT, OUTPUT);  
  digitalWrite(EARTH_OUT, LOW);
  pinMode(FIRE_OUT, OUTPUT);  
  digitalWrite(FIRE_OUT, LOW);  

  
  FrequencyTimer2::setPeriod(2030);           // 1ms  
  FrequencyTimer2::setOnOverflow(counting);
  
  while( !getPCtime());                                   // Wait until program is synced 
  
  long l_time = 1235948670;
  DateTime.sync(l_time);
        

  
}

void loop() 
{
    //Serial.print("Clock synced at: ");
    //Serial.println(DateTime.now());
  
  
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


        //Serial.println(count1ms/1000);
        
	if((count1ms % 100) == 0)				//Debug/variable feed
	{
	Serial.print("Wind: ");
	Serial.println(w_temp);
	Serial.print("Earth: ");
	Serial.println(e_temp);
	Serial.print("Fire: ");
	Serial.println(fire);
        Serial.print("Hour: ");
	Serial.println(int(DateTime.Hour));
	}

}


boolean getPCtime() 
{
   
   char c;
   char pctime[TIME_MSG_LEN];
 
  // if time sync available from serial port, update time and return true
  //Serial.println("before the read\n");      // time message consists of a header and ten ascii digits  
  for(int i = 0; i++; i < TIME_MSG_LEN)  
  {        c = Serial.read();                     if( c >= '0' && c <= '9')
        {   
          pctime[i] = c; 
        }
  }         
           
    Serial.println(pctime);      
           
    DateTime.sync(long(pctime));   // Sync Arduino clock to the time received on the serial port            
           
    if( DateTime.status == dtStatusSync) return true;   // return true if time message received on the serial port      
    else return false;  //if no message return false}
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

  if(/* (DateTime.Hour >= SUN_RISE && DateTime.Hour <= SUN_SET) &&*/ light < SUN)
  {
    digitalWrite(FIRE_OUT, HIGH);
  }
  else
  {
    digitalWrite(FIRE_OUT, LOW);
  }
  
}

