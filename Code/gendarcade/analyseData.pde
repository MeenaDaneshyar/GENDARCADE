// Function to analyse the summed FFT data and guess a gender based on it
String analyseData(float[] input){
  String guess = "";
  int maxBand = 0;
  float maxAmp = 0;
  for (int i = 0; i<input.length; i++){
    if(input[i]>maxAmp){ 
      maxAmp = input[i]; // If the current peak is bigger than the last peak which was stored, overwrite it
      maxBand = i; // Store the band which the peak belongs to
    }
  }
  
  println(maxBand + " " + maxAmp);
  
  if (maxBand <= 7){
    guess = "m";
  } else if (maxBand >7 && maxBand<40){
    guess = "f";
  } else {
    guess = "?"; // there's probably an error of some sort
  }
  return guess;
}