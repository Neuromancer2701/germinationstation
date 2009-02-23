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

//Input 
#define AIR   0            //Thermistor of Air temp
#define EARTH 1           //Thermistor of Soil temp
#define FIRE  2           //Photocell
#define WATER 3           //Resistor network for water 

//Output
#define AIR_OUT    7      //hair dryer
#define EARTH_OUT  6      //Heating PAd
#define FAN_OUT    5      //Fan
#define FIRE_OUT   4      //Lights
#define WATER_OUT  3      // Pump/TBD???



int volts = 0;
// AIR variables
int air        = 0;
int a_temp     = 0;
int setpoint_a = 80;
int air_timer  = 0;
int air_period = 0;
int duty = 0;



// Earth PID variables
int error = 0;
int error_past = 0;

int earth = 0;                  // variable to store the value coming from the sensor
int etemp = 0;
volatile int duty_e = 0;        // Live duty cycle
int P = 4;                    //Proportional Constant
int I = 4;                    //Integral Constant
int D = 4;                    //Derivative Constant
int setpoint_e = 82;


unsigned long count100ms = 0;
 void counting(void) {
  count100ms++;
}

                  
int calTemp(int bits, int setpoint){
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




int PIDe(int setpt, int tempnow)
{
  int duty_cycle = 0;
  
  error_past = error;
  error = setpt - tempnow;

  if(error < 0) error = 0;

  duty_cycle = P*error + (I*(error + error_past)/2) +(D*(error-error_past)/2);
  if(duty_cycle < 255) duty_cycle = 255;
  
  return duty_cycle;
}



void setup() {

  Serial.begin(9600);                         // use the serial port to send the values back to the computer
  pinMode(AIR_OUT, OUTPUT);
  pinMode(13, OUTPUT);
  
  digitalWrite(AIR_OUT, LOW);
  digitalWrite(13, LOW);
  
  
FrequencyTimer2::setPeriod(2030);           // 1000ms  
FrequencyTimer2::setOnOverflow(counting);


air_timer  = duty   + count100ms;
air_period = PERIOD + count100ms;

}

void loop() {
  

  
air = analogRead(AIR);    // read the value from the sensor
a_temp = calTemp(air,setpoint_a);

error_past = error;
error = setpoint_a - a_temp;
duty  = (4 * error) + 4 * ((error + error_past)/2);

if(duty > PERIOD) duty = PERIOD;

if(duty < 0) duty = 0;



if(air_period == (count100ms/1000) )
{
  digitalWrite(AIR_OUT, HIGH);
  digitalWrite(13, HIGH);
  air_timer  = duty   + (count100ms/1000);
  air_period = PERIOD + (count100ms/1000);


}

if(air_timer == (count100ms/1000))
{
  digitalWrite(AIR_OUT, LOW);
  digitalWrite(13, LOW);
}


if((count100ms % 1000) == 0)
{
Serial.print("Seconds: ");
Serial.println(count100ms/1000);
Serial.print("Period: ");
Serial.println(air_period);
Serial.print("Duty: ");
Serial.println(air_timer);
//Serial.println(count100ms);
//Serial.println(duty);
Serial.println(a_temp);
}




}
