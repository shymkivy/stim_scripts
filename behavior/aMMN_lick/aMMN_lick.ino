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


// reward parameters
bool require_lick = false;            // is licking required for deviance reward
int reward_sol_duration = 22;         // time solenoid valve is open, proportional to drink amount (20, 25)
int drink_duration = 1000;            // time given for animal to drink reward water before resuming next trial

// punishment parameters
bool punish_failed = true;           // do you want to punish wrong licks
int punish_timeout_duration = 4000;   // in ms


//////// Define pin numbers ////////////////

// Lick pins
int lick_pin = 13;         // pin 13 Right or 12 Left is also connected to right lick port

// defining solenoid pins
int reward_sol_pin = 5;     //  6 Right or 5 Left //define pin for turing solenoid valve ON

//Voltage recording pins for NI-DAQ
int reward_out_pin = 8; 
int punish_out_pin = 9;

// Speaker
int speakerOut = 11;    // define PWM pin for speaker/tone output
int rewFreq = 8000;
int rewToneDur = 100;
int pun_tone_duration = 500;
unsigned long startTime;

////////////// Serial communication

// messages from matlab
char matlab_start_stop_exp = '5';
char matlab_red_trial = '1';
char matlab_dev_trial = '2';

// messages from arduino
char arduino_ready = '6';

/////////// initialize
bool lick_state = LOW;
bool reward_state = false;
int matlab_data = 0;
int experiment_started = 0;
int trial_type = 0;   // 0 = no trials, 1 = redundant, 2 = deviant

///// SETUP ////////////////////////////////
void setup()                   
{
    pinMode(lick_pin, INPUT);
    
    pinMode(reward_sol_pin, OUTPUT);  // sets digital pin for turing solenoid valve ON
    
    pinMode(reward_out_pin, OUTPUT);

    pinMode(punish_out_pin, OUTPUT);

    Serial.begin(9600);    // initialize serial for output to Processing sketch
    
    randomSeed(analogRead(3));


    //pinMode(13, OUTPUT); // LED on arduino
}

//////// MAIN LOOP /////////////////////////////////

// logic - if mouse licks during reward stimulus, he gets a reward
void loop()
{           
    digitalWrite(punish_out_pin, LOW);
    
    if (experiment_started == 0)
    {
        if(Serial.available()>0)
        {
            
            matlab_data = Serial.read();
            if (matlab_data == matlab_start_stop_exp)
            {
                Serial.println(arduino_ready);
                experiment_started = 1;
            }
            
            // reset var
            matlab_data = 0;
        }
    }
    else
    {
        if (Serial.available()>0)
        {
            matlab_data = Serial.read();

            if (matlab_data == matlab_dev_trial)
            {
                Serial.println(arduino_ready);
                trial_type = 2;
                reward_state = false;     // reset the reward state at start of every deviant trial
            }
            else if (matlab_data == matlab_red_trial)
            {
                Serial.println(arduino_ready);
                trial_type = 1;
            }
            else if (matlab_data == matlab_start_stop_exp)
            {
                Serial.println(arduino_ready);
                trial_type = 0;
                experiment_started = 0;
            }
        
            // reset var
            matlab_data = 0;
        }
        
        // check for licks during experiment
        lick_state = digitalRead(lick_pin);
        
        // do you want to use lick or not
        if (require_lick == true)
        {
            
            // if there was a lick
            if (lick_state == HIGH) // add || lick_state == 0 to make reward available for every deviant trial
            {  
                
                // if correct trial, reward
                if (trial_type == 2) 
                {
                    reward();
                }
                else if (punish_failed == true)
                {
                    punish();
                }
            }
        }
        else if (require_lick == false)
        {
            // if correct trial, reward
            if (trial_type == 2) 
            {
                reward();
            }
        }
        
        lick_state = LOW;
        
    }
}  // end VOID LOOP()


// function for reward administration
void reward()
{   
    // to prevent rewarding twice in one trial, use reward state that is reset at start of deviant trials
    if (reward_state == false)
    {
        // REWARD SEQUENCE
        // go through reward/vacuum solenoid sequence
        digitalWrite(reward_sol_pin, HIGH);    // open solenoid valve for a short time
        digitalWrite(reward_out_pin, HIGH);
        reward_state = true;
        // PLAY TONE
        //tone(speakerOut, rewFreq, rewToneDur);
        delay(reward_sol_duration);                  // 8ms ~= 8uL of reward liquid (on box #4 011811)
        digitalWrite(reward_sol_pin, LOW);
        digitalWrite(reward_out_pin, LOW);
        
        delay(drink_duration);
    }
}

// function for punishment administration
void punish()
{
    startTime = millis();
    
    digitalWrite(punish_out_pin, HIGH);
    
    // play horrible tone
    while ((millis() - startTime) < pun_tone_duration)
    {
        tone(speakerOut, random(500, 10000), 1);
        delay(1);
    }
    delay(punish_timeout_duration);
    
    digitalWrite(punish_out_pin, LOW);

// here include maybe a horrible tone

}

