//
//    1 - lick_reward
//
//
//
//

bool exp_on = 0;
bool LED_on;
bool lick_state = LOW;
int matlab_data;


///// SETUP ////////////////////////////////
void setup()                   
{
  pinMode(11, OUTPUT);
  Serial.begin(9600);    // initialize serial for output to Processing sketch
}

//////// MAIN LOOP /////////////////////////////////

// logic - if mouse licks during reward stimulus, he gets a reward
void loop()
{
  if (Serial.available()>0)
  {
      matlab_data = Serial.read();
      if (matlab_data == '0')
      {
          exp_on = 0;
          lick_reward = 0;
      }
      else if (matlab_data == '1')
      {
          exp_on = 1;
          lick_reward = 1;
      }
      else if (matlab_data == '2')
      {
          lick_reward = 0;
      } 
  }
  if (exp_on)
  {
      if (lick_reward)
      {
          lick_state = LOW;
          while(lick_reward)
          {
              lick_state = digitalRead(lick_pin);
              if (lick_state == HIGH) 
              {  
                  reward();
                  lick_state = LOW;
                  lick_reward = 0;
              }
              
          }
          lick_state = LOW;
      }
      else
      {
          digitalWrite(11, LOW);
      }
  }
}  // end VOID LOOP()
