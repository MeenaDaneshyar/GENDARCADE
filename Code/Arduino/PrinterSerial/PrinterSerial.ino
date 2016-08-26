// By Meena Daneshyar, 2016
// See Sources_Used.pdf for a list of citations

// Bitmap data is converted into a .h file by the processing sketch included in the Adafruit_Thermal library

// Import libraries and define pins
#include <SoftwareSerial.h>;
#include "Adafruit_Thermal.h"
#include "gendarcade.h"
#define TX_PIN 6
#define RX_PIN 5

// Variables:
//byte letter;
String inString;
String printthis = "";
boolean lineComplete = false; // Is the current line of the message finished?

// Set up Software Serial as the regular serial pins are talking to the computer
SoftwareSerial mySerial(RX_PIN, TX_PIN); // digital pins that we'll use for soft serial RX & TX
Adafruit_Thermal printer (&mySerial);

void setup() {
  //  Set baud rates:
  Serial.begin(19200);
  mySerial.begin(19200);
  printer.begin();
  printer.justify('C');
}

void loop() {
  printer.justify('C');
  if(lineComplete && printthis == "~~HEADER~~\n" && printthis != "~~FOOTER~~\n"){ // If the special header string is received
    //print the header
    printer.println("");
    printer.println("");
    printer.println("");
    printer.println(F("~~~~~~~~~~~~~~~~~~~~"));
    printer.println("");
    printer.printBitmap(gendarcade_width, gendarcade_height, gendarcade_data); // Data comes from gendarcade.h
    printer.println("");
    lineComplete = false;
  } else if (lineComplete && printthis!= "~~HEADER~~\n" && printthis == "~~FOOTER~~\n"){ // If the special footer string is received
    printer.println("");
    printer.println("");
    printer.println(F("~~~~~~~~~~~~~~~~~~~~"));
    printer.println("");
    printer.println("");
    printer.println("");
    printer.println(F("~~~~~~CUT~HERE~~~~~~"));
    printer.println("");
    printer.println("");
    printer.println("");
    printer.println("");
    lineComplete = false;
  } else if (lineComplete && printthis != "~~HEADER~~\n" && printthis != "~~FOOTER~~\n"){ // Print a normal line
    printthis = printthis.substring(0,printthis.length()-1);
    printer.println(printthis);
    lineComplete = false;
  }
}

void serialEvent() { // Receive serial
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    inString += inChar; // Add up the message character by character
    if (inChar == '\n') { // If there is a new line character
      printthis = inString; // Save the string for use in the main loop
      Serial.println(inString);  // echo it back
      lineComplete = true;
      inString = "";
    }
  }
}
