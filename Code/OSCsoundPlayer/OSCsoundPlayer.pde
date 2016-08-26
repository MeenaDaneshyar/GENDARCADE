// By Meena Daneshyar, 2016
// See Sources_Used.pdf for a list of citations

// Import libraries
import processing.io.*;
import oscP5.*;
import netP5.*;
import beads.*;
import java.util.Arrays;


boolean messageReceived = false;
String theMessage; // To store the received message
// Locations of the sound samples
String idlesample = "/home/pi/sketchbook/OSCsoundPlayer/girls-cut2.mp3";
String wakesample = "/home/pi/sketchbook/OSCsoundPlayer/wakeup.wav";
String ticksample = "/home/pi/sketchbook/OSCsoundPlayer/ticktock.wav";
String dingsample = "/home/pi/sketchbook/OSCsoundPlayer/ding.wav";
// Four different sample players for the samples
SamplePlayer idlemusic;
SamplePlayer wakeupsound;
SamplePlayer ticktock;
SamplePlayer ding;

// OSC objects and beads object
OscP5 osc;
NetAddress netAddress;
AudioContext ac;


void setup(){
  GPIO.pinMode(RPI.PIN11, GPIO.INPUT); // Set up the "Cyndi Lauper off switch"

  osc = new OscP5(this,12000);
  netAddress = new NetAddress("192.168.0.10", 12000); // IP address of the main raspberry pi
  
  // Set up beads
  ac = new AudioContext();
  
  idlemusic = new SamplePlayer(ac, SampleManager.sample(idlesample)); // For a sample that is long, this causes an out of memory error on the Pi. Make a shorter sound to fix this and loop it.
  idlemusic.pause(true);
  idlemusic.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS); // Loop the idle music
  
  wakeupsound = new SamplePlayer(ac, SampleManager.sample(wakesample));
  wakeupsound.setKillOnEnd(false);
  wakeupsound.pause(true);
  
  ticktock = new SamplePlayer(ac, SampleManager.sample(ticksample));
  ticktock.pause(true);
  ticktock.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS); // Loop the tick tock sample
  
  ding = new SamplePlayer(ac, SampleManager.sample(dingsample));
  ding.setKillOnEnd(false);
  ding.pause(true);
  
  // Patch everything
  Gain g = new Gain(ac, 2, 0.2);
  g.addInput(idlemusic);
  g.addInput(wakeupsound);
  g.addInput(ticktock);
  g.addInput(ding);
  ac.out.addInput(g);
  ac.start();
}

void draw(){
  if (GPIO.digitalRead(RPI.PIN11) == GPIO.HIGH){ // If the switch is flipped, don't play the idle music
    idlemusic.pause(true);
  }
  
  if(messageReceived){
    if(theMessage.equals("idlemusic") && GPIO.digitalRead(RPI.PIN11) == GPIO.LOW){
      // Stop everything else playing
      wakeupsound.pause(true);
      ticktock.pause(true);
      ding.pause(true);
      // Play the idle music
      idlemusic.setPosition(0);
      idlemusic.pause(false);
      // Reset the message
      theMessage = "";
      
    } else if (theMessage.equals("wakeupsound")){
      // Stop everything else playing
      idlemusic.pause(true);
      ticktock.pause(true);
      ding.pause(true);
      // Play the wake up sound
      wakeupsound.reTrigger();
      wakeupsound.pause(false);
      // Reset the message
      
      theMessage = "";
    } else if (theMessage.equals("ticktock")){
      // Stop everything else playing
      idlemusic.pause(true);
      wakeupsound.pause(true);
      ding.pause(true);
      // Play the tick tock sample
      ticktock.setPosition(0);
      ticktock.pause(false);
      // Reset the message
      theMessage = "";
      
    } else if (theMessage.equals("ding")){
      // Stop everything else playing
      idlemusic.pause(true);
      wakeupsound.pause(true);
      ticktock.pause(true);
      // Play the ding sample
      ding.reTrigger();
      ding.pause(false);
      // Reset the message
      theMessage = "";
      
    } else if (theMessage.equals("stopall")){
      // Pause everything
      idlemusic.pause(true);
      wakeupsound.pause(true);
      ticktock.pause(true);
      ding.pause(true);
      // Reset the message
      theMessage = "";
    }
    messageReceived = false;
  }  
}


void oscEvent(OscMessage message) { // OSC message monitor
  println("Message received:");// print it to console
  if(message.checkAddrPattern("/play")==true) { // check it's the right type
    theMessage = message.get(0).stringValue(); // get the string value
    println(theMessage);
    messageReceived = true;
  } else {
    println("Message address pattern incorrect.");
  }
}