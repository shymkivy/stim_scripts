/////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Goal is to transfer most control to matlab. Arduino will execute minimal commands
//    1. LED on
//    2. LED off
//    3. Give water
//
/////////////////////////////////////////////////////////////////////////////////////////////

///////// Parameters //////////////////////

int sol_control_pin = 5;                //  6 Right or 5 Left //define pin for turing solenoid valve ON
int reward_sol_duration = 40;           // 20ms release 4ul drop.time (in ms) that reward valve is open (80ms for 2p)

int led_control_pin = 11;               // LED out (for reward cue)
int LED_intensity = 30;                 // 0 - 255 


///// SETUP ////////////////////////////////
void setup()                   
{
    pinMode(sol_control_pin, OUTPUT);  // sets digital pin for turing solenoid valve ON

    pinMode(led_control_pin, OUTPUT);
        
    Serial.begin(9600);    // initialize serial for output to Processing sketch

}

//////// MAIN LOOP /////////////////////////////////

// logic - if mouse licks during reward stimulus, he gets a reward
void loop()
{     
    if(Serial.available())
    {
        matlab_data = Serial.read();
        if (matlab_data == '1')
        {
            analogWrite(led_control_pin, LED_intensity);
        }
        else if (matlab_data == '2')
        {
            analogWrite(led_control_pin, 0);
        }
        else if (matlab_data == '3')
        {
            digitalWrite(reward_sol_pin, HIGH);
            delay(reward_sol_duration);
            digitalWrite(reward_sol_pin, LOW);
        }
    }

}  // end VOID LOOP()
