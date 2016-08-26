// Import libraries
import processing.serial.*; // Serial library
import processing.io.*; // GPIO library
import http.requests.*; // For the sentiment analysis API
import twitter4j.conf.*; // For Twitter API
import twitter4j.api.*;
import twitter4j.*;
import java.util.List; // To enable the Twitter API to work
import beads.*; // For FFT
import java.util.Arrays;
import oscP5.*;
import netP5.*;

// Variable declaration
String theText = "Press green button to record"; 
String [] record = {"/home/pi/testthing.sh"}; // Path to the bash script that records using "arecord"
int index = 0; // Stores the position in the ledControl array
boolean finishedRecording = false; // Stores if the recording script has finished
boolean loadedFile = false; // has the audio file been reloaded
boolean genderAnalysed = false; // has the gender been analysed
boolean wokenUp = true; // Boolean to save whether the machine is in idle mode or active
boolean init = true; // should i wake up and run the routine?

String [] offlineArray = {"I hate it when people ask me why I'm a feminist. If you ask that question you probably don't know what feminism means", "My room mate doesn't like me liking women and thinks it's a \"gimmick\" even tho he's had exactly one girlfriend like how the hell would u know", "How long until women's bathrooms have urinals to accommodate trans gender men women who don't want to sit down to pee...?", "To be honest, women don't have racial loyalty. Women are not loyal in general. Only loyal to their own interests. That goes for ANY race." , "To be trill w you guys get slut shamed more than women but we don't let it get to us", "men talk as much as women nowadays... i can't take u lot serious!", "There is no reason for women to put other women down and tear them apart. I don't understand it. We're all supposed to be on the same team?", "I wish I had an audience who listened to me so I could say to the guys \"Don't sexually assault women\" instead I'm saying it to you", "If shorty in your top anything as far as women go you my friend don't know women at all!", "I hate being in Europe at times because I don't have that skinny body that they think is the only body type women should have"}; 

// Set up some timer objects
long recordMillis = -9000; // Allow the recording script time to run
long buttonMillis = -1000; // Set a delay for how quickly the LED button can be pressed
long lastEndTime = -30000; // Save the last time the sketch ran so that the machine can enter "idle mode" when nothing has happened for a while


// For the FFT
int binSize = 2048; // Stores the bin size for the FFT
String recordedFilePath = "/home/pi/test.wav"; // The path to the file that the bash script records to
String gender;

Serial printer; // Serial objects for printer and LEDs
Serial LEDs;

ConfigurationBuilder   cb;
Query query;
Twitter twitter;

FFT fft;
AudioContext ac;
Sample sample;
SamplePlayer player;
Gain g;

OscP5 osc;
NetAddress netaddr;

void setup() {
  // Set up drawing canvas
  size(300, 500);
  background(40);
  textSize(20);
  fill(255);
  textAlign(CENTER);

  // Set up OSC
  osc  = new OscP5(this, 12000);
  netaddr=  new NetAddress("192.168.0.4", 12000); // change this to 192.168.0.4 with the second Raspberry Pi connected via eth0

  // Set up serial ports
  printer = new Serial(this, "/dev/ttyS0", 19200); // Built in serial port talks to the printer
  LEDs = new Serial(this, "/dev/ttyUSB0", 19200); // USB serial port talks to the Arduino nano

  GPIO.pinMode(RPI.PIN11, GPIO.INPUT); // Red button, normally pulled high, pressing shorts to ground
  GPIO.pinMode(RPI.PIN13, GPIO.INPUT); // Green button, normally pulled high, pressing shorts to ground

  //Authenticate with Twitter and set up the object
  cb = new ConfigurationBuilder();
  cb.setOAuthConsumerKey("M4tnraK0Bfiic663MOl6CrI3c");
  cb.setOAuthConsumerSecret("T0p5MIGxLU2vt7zWqtFiq8hiamQxgFoKRPMRmFxoGkWwvPemuL");
  cb.setOAuthAccessToken("758061069285912576-TkT8GwUU4po7IcdyzVhm7j3eNbm39xQ");
  cb.setOAuthAccessTokenSecret("lLizrWwQO2xJtKjBwWmmyAO7AFlDEqJrUJarw6d6n1voE");
  twitter = new TwitterFactory(cb.build()).getInstance();

  fft = new FFT();
  ac = new AudioContext(binSize);
  sample = SampleManager.sample(recordedFilePath);
  player = new SamplePlayer(ac, sample);
  g = new Gain(ac, 2, 0.2);

  g.addInput(player);
  ac.out.addInput(g);
  ShortFrameSegmenter sfs = new ShortFrameSegmenter(ac);
  sfs.addInput(ac.out);
  sfs.addListener(fft);
  ac.out.addDependent(sfs);
  ac.start();
  player.pause(true);
}


void draw() {
  background(40);
  text(theText, width/2, height/2);

  if (GPIO.digitalRead(RPI.PIN13) == GPIO.LOW && !wokenUp && !init)   { // if the green button has been pressed while in idle mode
    // Wake up
    wokenUp =  true;
    println("Waking up...");
    // Send a message to play the wake up noise
    OscMessage message = new OscMessage("/play");
    message.add("wakeupsound");
    osc.send(message,netaddr);

    LEDs.write("mainlightson\n");
    delay(200);
    LEDs.write("blinkfast\n");
    lastEndTime = millis();
    

  }


  if (GPIO.digitalRead(RPI.PIN11) == GPIO.LOW && wokenUp && !finishedRecording && !genderAnalysed && !loadedFile) { // Check if the red (talk) button has been pressed but only when the machine is awake
    if (millis() - recordMillis > 9000) { // If it has been over 9 seconds since the last recorded input
      init = true;
      // Stop all noises from playing...      
      OscMessage message = new OscMessage("/play");
      message.add("stopall");
      osc.send(message,netaddr);
      // Set the eyes to steady
      LEDs.write("steady\n");
      launch(record); // Record a new sample by launching the recording script
      theText = "Recording...";
      println("Loop 1a");
      recordMillis = millis();
      finishedRecording = true;
    } else {
      theText = "Recording...";
      println("Loop 1b");
    }
  } else if   (finishedRecording && !loadedFile && !genderAnalysed && wokenUp) {
    if (millis() - recordMillis > 9000) {
      // Play the tick tock sound while the analysis runs
      OscMessage message = new OscMessage("/play");
      message.add("ticktock");
      osc.send(message,netaddr);
      SampleManager.removeSample(recordedFilePath);
      sample = SampleManager.sample(recordedFilePath); // Reload the audio sample with the new one
      player = new SamplePlayer(ac, sample);
      player.setKillOnEnd(false);
      g.addInput(player);
      ac.out.addInput(g);
      ShortFrameSegmenter sfs = new ShortFrameSegmenter(ac);
      sfs.addInput(ac.out);
      sfs.addListener(fft);
      ac.out.addDependent(sfs);
      ac.start();
      player.reset();
      player.pause(true);  

      finishedRecording = false;
      loadedFile = true;
      println("Loop 2");
    }
  } else if (loadedFile && !finishedRecording && !genderAnalysed && wokenUp) {
    if (millis() - recordMillis > 9000) { // If it has been over 9 seconds since the last recorded input
      theText = "Press green button to record";

      //// Set up the FFT and prepare to analyse the audio
      float [] totalData = new float [binSize/2]; // To save the FFT information as a running total

      player.pause(false); // Just in case...

      // Start adding up the data to record later...
      float [] features = fft.getFeatures()[0];
      if (features!=null) {
        for (int i = 0; i<features.length/2; i++) {
          totalData[i] += features[i];
        }
      }
      
      println("Analysing...");

      if (sample.getLength() - player.getPosition() < 50) { 
        player.pause(true);
        gender = analyseData(totalData);
        println("Gender is " + gender);
        loadedFile = false;
        genderAnalysed = true;
      }

    }
  } else if (genderAnalysed && !loadedFile && !finishedRecording && wokenUp) {
    // Go grab a tweet!
    String tweet = getTheTweet(gender, "women");
    String [] lines = wrapText(tweet, 20);
    delay(200);
    printer.write("~~HEADER~~\n"); // Print the header out
    delay(5000); // wait while the header prints
    for (int i = 0; i<lines.length; i++) { // Loop through the lines
      printer.write(lines[i] + "\n"); // Print each line plus a new line character for the arduino's benefit
      println(lines[i]);
      delay(1500); // wait for the last line to finish printing
    }
    printer.write("~~FOOTER~~\n"); // Print the footer 
    delay(7000);

    // Play the "ding" sound to indicate the sequence is complete
    OscMessage message = new OscMessage("/play");
    message.add("ding");
    osc.send(message,netaddr);


    genderAnalysed = false;
    lastEndTime = millis(); // Save the time when the routine finishes running
  } else if (millis() - lastEndTime > 10000 && !genderAnalysed && !loadedFile && !finishedRecording && wokenUp && init) {
    //Machine idle sequence
    init = false;
    wokenUp= false;
    println("Sleeping...");
    // Turn the main lights on
    LEDs.write("mainlightsflash\n");
    
    // Send an OSC message to play the idle music
    OscMessage message = new OscMessage("/play");
    message.add("idlemusic");
    osc.send(message, netaddr);

    // Set the eye LEDS to fade in and out
    LEDs.write("fadeout\n");
  }
  
}