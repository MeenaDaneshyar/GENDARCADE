#!/bin/bash
arecord -D plughw:1,0 -d 7 -r 48000 -N /home/pi/test.wav
