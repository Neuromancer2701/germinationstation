/* Analog Read Send
 * ---------------- 
 *
 * turns on and off a light emitting diode(LED) connected to digital  
 * pin 13. The amount of time the LED will be on and off depends on
 * the value obtained by analogRead(). In the easiest case we connect
 * a potentiometer to analog pin 2. Sends the data back to a computer
 * over the serial port.
 *
 * Created 1 December 2005
 * copyleft 2005 DojoDave <http://www.0j0.org>
 * http://arduino.berlios.de
 *
 */
#include <avr/interrupt.h>  
#include <avr/io.h> 
#include <math.h> 


#define INIT_TIMER_COUNT 1  
#define RESET_TIMER2 TCNT0 = INIT_TIMER_COUNT 
#define coldco -0.711
#define medco -0.432
#define hotco -0.368


int water = 0;
int volts = 0;
float Vc = 0.0049;             // 5V/1024bits



int error = 0;
int error_past = 0;
int PWM_out_e = 11;
int earth = 0;                  // variable to store the value coming from the sensor
int etemp = 0;
volatile int duty_e = 0;        // Live duty cycle
int P = 4;                    //Proportional Constant
int I = 4;                    //Integral Constant
int D = 4;                    //Derivative Constant
int setpoint_e = 82;
                   
int error_a = 0;
int error_past_a = 0;
int PWM_out_a = 10;
int air = 0;
int atemp = 0;
volatile int duty_a = 0;        // Live duty cycle
int Pa = 4;                    //Proportional Constant
int Ia = 4;                    //Integral Constant
int Da = 4;                    //Derivative Constant
int setpoint_a = 77;

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

int PIDe(int setpt, int tempnow){
  int duty_cycle = 0;
  
  error_past = error;
  error = setpt - tempnow;

  if(error < 0) error = 0;

  duty_cycle = P*error + (I*(error + error_past)/2) +(D*(error-error_past)/2);
  if(duty_cycle < 255) duty_cycle = 255;
  
  return duty_cycle;
}

int PIDa(int setpt, int tempnow){    //PID loop for air sensor
int duty_cycle = 0;
  
  error_past_a = error_a;
  error_a = setpt - tempnow;

  if(error_a < 0) error_a = 0;

  duty_cycle = Pa*error_a + (Ia*(error_a + error_past_a)/2) +(Da*(error_a-error_past_a)/2);
  if(duty_cycle < 255) duty_cycle = 255;
  
  return duty_cycle;
}


void setup() {

  Serial.begin(9600);             // use the serial port to send the values back to the computer
  pinMode(PWM_out_a, OUTPUT);      // sets the digital pin as output
  pinMode(PWM_out_e, OUTPUT);

}

void loop() {
  earth = analogRead(2);    // read the value from the sensor
  delay(5);                 //wait 5ms between reads
  //air   = analogRead(1);    //read thermistor in the air
  delay(5);                 //wait 5ms between reads
  //water = analogRead(0);    //read water sensor
  delay(5);                 //wait 5ms between reads just in case the loop runs fast than 5 ms
//Serial.println(earth);
etemp = calTemp(earth,setpoint_e);
Serial.println(earth);
Serial.println(etemp);
//atemp = calTemp(air,setpoint_a);




analogWrite(PWM_out_e, PIDe(etemp,setpoint_e));
analogWrite(PWM_out_a, PIDa(atemp,setpoint_a));




  //Serial.println(temp);           // print the value to the serial port
  //Serial.println(0x00);  
  //Serial.println(duty);  
}
