
bool LED_on;
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
    if (matlab_data == '1')
    {
      LED_on = 1;
    }
    else if (matlab_data == '2')
    {
      LED_on = 0;
    } 
  }
  if (LED_on)
  {
    digitalWrite(11, HIGH);
  }
  else
  {
    digitalWrite(11, LOW);
  }
}  // end VOID LOOP()
