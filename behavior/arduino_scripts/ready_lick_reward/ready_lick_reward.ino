

/////////////////////////////////////////////////////////////////////////////////////////////////
//
//      Train and tast script for learing to lick during deviant stimulus 
//
//          Script logic:
//              Matlab script and arduino communicate through serial COM port (USB). At the start of the  
//              experiment and at the start of every trial, matlab sends message to check if arduino is ready,
//              ardunino sends back ready response. If ready matlab starets the trial. Matlab sends either '1'
//              or '0' depending on which type of trial, arduino reads digital input for licks and decides what
//              to do during licks depending on what trial it is. If time out or delay for reward is needed it
//              could be added to arduino script during 'reward' or 'punishment' and matlab will wait until 
//              arduino is finished before starting a new trial.
//
//          To run experiment:
//              Compile and uplode script to arduino.
//              Run voltage_recording_NI_DAQ function to start voltage recording
//              Run vMMN_lick or any other script
//
/////////////////////////////////////////////////////////////////////////////////////////////
///////// Includes ///////////////

///////// Parameters //////////////////////

bool run_exp = 1;    // turn on or off exp

int reward_sol_duration = 30;         // 20ms release 4ul drop.time (in ms) that reward valve is open (80ms for 2p)
int LED_intensity = 30;             // 0 - 255 

int initial_trial_delay = 500;       // wait after initial lick
int trial_window = 5000;
int reward_delay = 1000;              // time given for animal to drink reward water before resuming next trial
int findal_trial_delay = 2000;        // time out after reward

int punish_timeout_duration = 2000;   // in ms

////// Reward cues
int includeSoundRewardCue = 0;
int rewToneDur = 100;

int includeLEDRewardCue = 1;
int rewLEDDur = 1000;

//////// Define pin numbers ////////////////

// Lick pins
int lick_control_pin = 13;         // pin 13 Right or 12 Left is also connected to right lick port

// LED out (for reward cue)
int led_control_pin = 11;       // pwm pin

// defining solenoid pins
int pump_control_pin = 5;     //  6 Right or 5 Left //define pin for turing solenoid valve ON

//Voltage recording pins for NI-DAQ
int led_report_pin = 8; 
int reward_report_pin = 9; 
int punish_report_pin = 10;


// Speaker
//int speakerOut = 11;    // define PWM pin for speaker/tone output
int rewFreq = 8000;
int startTime;




////////////// Serial communication

// messages from matlab
char matlab_start_stop_exp = '5';
char matlab_red_trial = '1';
char matlab_dev_trial = '2';

// messages from arduino
char ready_for_trial = '6';
char ready_to_start_stop = '7';

/////////// initialize
bool lick_state = LOW;
bool trial_ongoing = false;
int matlab_data = 0;
int experiment_started = 0;
int trial_type = 0;   // 0 = no trials, 1 = redundant, 2 = deviant
int trial_start;
int now1;

///// SETUP ////////////////////////////////
void setup()                   
{
    pinMode(lick_control_pin, INPUT);
    
    pinMode(pump_control_pin, OUTPUT);  // sets digital pin for turing solenoid valve ON
    
    pinMode(led_report_pin, OUTPUT);

    pinMode(reward_report_pin, OUTPUT);

    pinMode(led_control_pin, OUTPUT);
    

    //tone1.begin(13);
    
  
//    pinMode(punish_report_pin, OUTPUT); 
//
//    Serial.begin(9600);    // initialize serial for output to Processing sketch
//    
//    randomSeed(analogRead(3));


    //pinMode(13, OUTPUT); // LED on arduino
}

//////// MAIN LOOP /////////////////////////////////

// logic - if mouse licks during reward stimulus, he gets a reward
void loop()
{           
    if (run_exp == true)
    {
      // set light on and trial ready
      lick_state = LOW;
      analogWrite(led_control_pin, LED_intensity);
      digitalWrite(led_report_pin, HIGH);
      //digitalWrite(led_control_pin, HIGH);
      while (lick_state == LOW)
      {
        lick_state = digitalRead(lick_control_pin);      // check for licks to initiate experiment
      }
      analogWrite(led_control_pin, 0);
      digitalWrite(led_report_pin, LOW);
      //digitalWrite(led_control_pin, LOW);                 // reset
  
      // delay before reward
      delay(initial_trial_delay);
      
      // start trial
      trial_start = millis();
      trial_ongoing = true;
      lick_state == LOW;                         // reset
      while(trial_ongoing)
      {
        now1 = millis();
        if ((now1 - trial_start)<trial_window)
        {
          lick_state = digitalRead(lick_control_pin);
          if (lick_state == HIGH) 
          {  
              reward();
              lick_state = LOW;
              trial_ongoing = false;
              delay(reward_delay);
          }
        }
        else
        {
          trial_ongoing = false;
        }
      }
      delay(findal_trial_delay);
    }

}  // end VOID LOOP()


// function for reward administration
void reward()
{
    digitalWrite(pump_control_pin, HIGH);    // open solenoid valve for a short time
    analogWrite(led_control_pin, LED_intensity);
    digitalWrite(reward_report_pin, HIGH);
    digitalWrite(led_report_pin, HIGH);
    delay(reward_sol_duration);
    digitalWrite(pump_control_pin, LOW);
    analogWrite(led_control_pin, 0);  
    digitalWrite(led_report_pin, LOW);
    digitalWrite(reward_report_pin, LOW);
}

//// function for punishment administration 
//void punish()
//{
//    startTime = millis();
//    digitalWrite(punish_report_pin, HIGH);
//    
//    while ((millis() - startTime) < punish_timeout_duration)
//    {
//        tone(speakerOut, random(500, 10000), 1);
//        delay(1);
//    }
//    
//    digitalWrite(punish_report_pin, LOW);
//
//// here include maybe a horrible tone
//
//}
