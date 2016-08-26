// By Meena Daneshyar, 2016
// See Sources_Used.pdf for a list of citations

const int led = 3; // LED is on pin 3
const int mainlights = 9; // Circuit for main lights is on pin 9
int brightness = 0;
int fade = 5; // fade amount
unsigned long prevMillis = 0; // Timers
unsigned long mainMillis = 0;
boolean fadeout, blinkfast, blinkslow, steady, off, mainlightson, mainlightsflash = false;
String inString; // Input string from serial
boolean stringComplete = false;
boolean ledOn, mainOn = false;
String compare;

void setup() {
  // Set up pins and start serial
  pinMode(led,OUTPUT);
  pinMode(mainlights, OUTPUT);
  Serial.begin(19200);
}


void loop() {
  if (stringComplete){ // If the message has finished receving
    // Do string comparisons and change the booleans accordingly
    if(compare =="steady"){
      steady = true;
      blinkfast = blinkslow = fadeout = off = false;
    } else if (compare == "blinkslow"){
      blinkslow = true;
      steady = blinkfast = fadeout = off = false;
    } else if (compare == "blinkfast"){
      blinkfast = true;
      blinkslow = steady = fadeout = off = false;
    } else if (compare == "fadeout"){
      fadeout = true;
      blinkslow = blinkfast = steady = off = false;
    } else if (compare == "off"){
      off = true;
      blinkslow = blinkfast = steady = fadeout = false;
    } else if (compare == "mainlightson"){
      mainlightson = true;
      mainlightsflash = false;
    } else if (compare == "mainlightsoff"){
      mainlightson = false;
      mainlightsflash = false;
    } else if (compare == "mainlightsflash"){
      mainlightsflash = true;
      mainlightson = false;
    }
  }

  unsigned long currMillis = millis();

   // Set LED states by checking each boolean
  if(blinkfast){
    if (currMillis - prevMillis > 50){
      prevMillis = currMillis;
      if (ledOn){
        digitalWrite(led,LOW);
        ledOn = false;
      } else {
        digitalWrite(led,HIGH);
        ledOn = true;
      }
    }

  } else if (blinkslow){
    if (currMillis - prevMillis > 500){
      prevMillis = currMillis;
      if (ledOn){
        digitalWrite(led,LOW);
        ledOn = false;
      } else {
        digitalWrite(led,HIGH);
        ledOn = true;
      }
    }

  } else if (fadeout){
    if (currMillis - prevMillis > 30){
      prevMillis = currMillis;
      analogWrite(led,brightness);
      brightness = brightness + fade;
      if (brightness ==0 || brightness == 255){
        fade *= -1;
      }
    }

  } else if (steady){
    digitalWrite(led,HIGH);

  } else if (off) {
    digitalWrite(led,LOW);
  }


  // Second if statement to monitor the main lights separately
  if (mainlightson){
    digitalWrite(mainlights,HIGH);
    mainOn = true;
  } else if (mainlightsflash){
    if(millis()-mainMillis > 2000){
      mainMillis = millis();
      if(mainOn){
        digitalWrite(mainlights,LOW);
        mainOn = false;
      } else if (!mainOn){
        digitalWrite(mainlights,HIGH);
        mainOn = true;
      }
    }
  } else {
    digitalWrite(mainlights,LOW);
  }
}


void serialEvent() {
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    // add it to the inputString:
    if (inChar != '\n'){
      inString += inChar;
    }
    // if the incoming character is a newline, set a flag
    // so the main loop can do something about it:
    if (inChar == '\n') {
      compare = inString;
      Serial.println(inString);
      stringComplete = true;
      inString = "";
    }
  }
}
