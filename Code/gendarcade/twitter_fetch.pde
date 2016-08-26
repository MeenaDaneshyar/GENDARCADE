// Function to get a tweet from Twitter to pass to the printer
String getTheTweet(String gend, String searchword){
  
  String lookFor = "";
  String theTweet = "";
  ArrayList<String> twitt = new ArrayList<String>();
  
  // Counters for the different reasons of discarding tweets
  int wrongSent = 0;
  int replies = 0;
  int RTs = 0;
  int links = 0;

  query = new Query(searchword);
  query.setCount(200);
  query.setResultType(Query.RECENT);

  try {
    QueryResult result = twitter.search(query);
    List<Status> tweets = result.getTweets();
    
    // Loop through the returned tweets
    for (Status tw : tweets) {
      String msg = tw.getText(); // Extract the message
      
      String begin = msg.substring(0,2); // Grab the first two characters of the tweet
      if (begin.equals("RT")){ // If the tweet is a manual retweet (RT @somename XXXXXXXXXX)
        //println("This is a retweet so I'm ignoring it");// Discard it
        RTs++;
        continue;
        
      } else if (begin.substring(0,1).equals("@") || begin.equals(".@")){ // If the tweet is a reply
        //println("This is a reply so I'm ignoring it"); // Discard it
        replies++;
        continue;
        
      } else if (msg.contains("http") == true){ // If the tweet has a link in it
        //println("This has a link in it so I'm ignoring it"); // Ignore it
        links++;
        continue;
        
      } else { // If the tweet does not get ignored
        // Do sentiment analysis to find positive or negagtive tweets depending on the gender
        PostRequest post = new PostRequest("http://text-processing.com/api/sentiment/");
        post.addData("text", msg);
        post.send();
        processing.data.JSONObject response;
        try{
          response = parseJSONObject(post.getContent());
        } catch (NullPointerException npe){
          continue;
        }
        
        
        // Change the sentiment of the tweet that is being looked for depending on gender
        // Because male genders lead to looking for negative sentiments, the search parameter should be something like "women" or "feminism" that men would be negative about.
        
        if (gend.equals("m")){
          lookFor = "neg";
        } else if (gend.equals("f")) {
          lookFor = "pos";
        } else if (gend.equals("?")){
          lookFor = "neutral";
        } else {
          lookFor = "neutral";
        }
          
          
        if (response.getString("label").equals(lookFor)) {
          //println(msg.substring(0,2) + " , " + response.getString("label")); // for debugging
          twitt.add(msg); // Add the tweet to the array of tweets
          continue;
        } else {
          //println("I'm ignoring this one as it's the wrong sentiment"); // Ignore it if the wrong sentiment is found
          wrongSent++;
          continue;
        }
      }
    }
    
    if(twitt.size() >0){
      theTweet = twitt.get(int(random(twitt.size()))); // Pick a random tweet from the array that are suitable

    } else {
      theTweet = offlineArray[int(random(offlineArray.length))]; // Print an old saved tweet if no suitable tweets are found
    }
  
  }
  catch (TwitterException te) { // Throw an error if there is no internet connection etc. but don't crash
    println("Couldn't connect: " + te);
    theTweet = offlineArray[int(random(offlineArray.length))]; // Print an old saved tweet if no connection to twitter is available
  } 
  
  println("Wrong sentiment: " + wrongSent + ", Links: " + links + ", Retweets: "+ RTs + ", Replies: " + replies + ". Total useable tweets: " + twitt.size());
  return theTweet;
}