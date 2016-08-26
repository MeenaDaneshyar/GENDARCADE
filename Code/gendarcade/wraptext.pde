// Function to take a long string of text and wrap it to a given number of characters per line, returned as an array of strings.

String [] wrapText(String input, int len){ // Inputs are a long string to be divided up and the maximum number of characters per line
  String [] split = split(input, " "); // Split the input into an array of individual words every time there is a space.
  
  String currentLine = ""; // New blank string for the current line we're going to add up
  ArrayList<String> wrappedList = new ArrayList<String>(); // New array list that the lines can be added to
  
  for (int i = 0; i<split.length; i++){// Loop through all the individual words in the array
    if(currentLine.length() + split[i].length() + 1 <= len && i != split.length-1){ // See if the current word can be added to the current line without going over the length limit
      currentLine += " "; // If it can be added, add a space (as these got removed)...
      currentLine += split[i]; // ... and then add the word
    } else if (currentLine.length() + split[i].length() +1 <=len && i == split.length-1){ // If the current word is the last one in the array
      currentLine += " "; //.. add it the same as before
      currentLine += split[i];
      wrappedList.add(currentLine); // add the current line to the array list of lines
    } else { // If there isn't room to add the current word to the current line
      try{
        wrappedList.add(currentLine);  // add the line to the array list
        currentLine = ""; // and reset it
        i--; // go back one word in the array (since the current word hasn't been added to anything yet)
      } catch (OutOfMemoryError e){
        wrappedList.clear();
        String [] errorreturn =  {"Don't ask me", "I'm just a" , "girl"};
        return errorreturn;
      }
    }
  }
  
  String [] wrapped = new String [wrappedList.size()]; // Create a new array the same size as the array list
  
  for(int i = 0; i< wrappedList.size();i++){ // Copy the array list values into the new array
    wrapped[i] = wrappedList.get(i);
  }
  
  return wrapped; // Return an array of strings, which are the individual lines to be printed
  
}