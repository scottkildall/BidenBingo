/*
    Biden Bingo
    Written by Scott Kildall
    www.kildall.com
    
    How it works:
    
    * Draws a 8.5" x 11" sized screen, which may be too high for many displays, and outputs
       numbered PDF files for the Bingo Cards
    * Press the SPACE BAR to generate the PDF Bingo cards
    * Press 'n' to go to the next Bingo card (just for debug use)
    
    
    Files:
    * state_data.csv - database of the PNG filenames, state names (not used, really), and prediction (democrat, republican or swing)
    * letters_data.csv - database of the filenames for the letters so that we can draw them
    
    Directories:
    * generatedCards - where the finished PDFs will be saved
    * us_states - where the PNGs for each state is, which will match the entries in state_data.csv
    * letters - where the PNGs for each letter is, which will match the entries in letters_data.csv
*/


import processing.pdf.*;

// basic control varaibles
boolean recordToPDF = false;

// display variables
int screenWidth = 850;
int screenHeight = 1100;
PFont stateFont;


// Array of indices so that we can shuffle the states, use the shuffle() function to make new cards
IntList bingoIndexList; 

// array of state images, corresponds to the data table
int numStates;
PImage [] stateImages;
String [] stateNames;
String [] predictions;    // "democrat", "swing" or "republican"

int newYorkIndex = 0; // index from the data file, makes NY the center square

// Array of letters for "BIDEN" and "BINGO"
int numLetters;
PImage [] lettersImages;

// Variables for outputting the cards
int outputFileNum;
int numFilesToOutput = 100;

//-- Create font, load the images for titles and states, generate the first card
void setup() {
  stateFont = createFont("luximr.ttf", 24);
 
  // fit onto an 8.5 x 11 sheet
  size(850,1100);
  
  loadStateData();
  loadTitles();
  generateCard();
}

void draw() {
  //-- draw background elements
  background(215);
  fill(0,0,255);
  stroke(127,127,127);
  
  if( recordToPDF ) {
    // saved PDF in the "generatedCards" directory as a numbered sequence
    beginRecord(PDF, "generatedCards/bidenbingo_" + outputFileNum + ".pdf");
    background(255);    // flash to white
  }
  else {
    //-- draw the instructions
      text( "Press SPACE BAR to generate " + numFilesToOutput + " Biden Bingo cards", screenWidth/2,  40);
  
      text( "(will take a couple minutes)", screenWidth/2,  70);
  
   }
  //-- draw data
  drawCard();
  
  if( recordToPDF ) {
    generateCard();
    outputFileNum++;
    endRecord();
    
    if( outputFileNum > numFilesToOutput ) {
      recordToPDF = false;
    }
  } 
}

//-- SPACE BAR to generate files, 'n' to go to the next card (use for debugging)
void keyPressed() {
  if( key == ' ' ) {
    outputFileNum = 1;
    recordToPDF = true;
  }
    
  if( key == 'n' ) {
      generateCard();
  }
}

//-- go through the state_data.csv file and allocate and load images for each, state names and predictions
//-- also allocate the index list for which order the cards appear in
void loadStateData() {
  Table table = loadTable("state_data.csv", "header");
  
  // Allocate the index list for the shuffling of the cards later
  bingoIndexList = new IntList();
  
  //println(table.getRowCount() + " total rows in table"); 
  
  // Allocate arrays
  numStates = table.getRowCount();
  stateImages = new PImage[numStates];
  stateNames = new String[numStates];
  predictions = new String[numStates];
  
  int rowNum = 0;
 
  // Go through the data table and extract into arrays
  for (TableRow row : table.rows()) {
    // build the index list, right now it will be [0,1,2,3...], but this will get shuffled each time
    bingoIndexList.append(rowNum);
     
    stateImages[rowNum] = loadImage("us_states/" + row.getString("Filename"));   
    stateNames[rowNum] = new String(row.getString("State"));
    
    // Check for New York, if we find it, save that index
    if( stateNames[rowNum].equals("New York") )
       newYorkIndex = rowNum;    
    
    predictions[rowNum] = new String(row.getString("Prediction"));
    
    rowNum++;
  }  
}

void loadTitles() {
  Table table = loadTable("letters_data.csv", "header");
  numLetters = table.getRowCount();
  lettersImages = new PImage[numLetters];
   
  int rowNum = 0;
 
  for (TableRow row : table.rows()) {
    lettersImages[rowNum] = loadImage("letters/" + row.getString("Filename"));   
    
    rowNum++;
  }  
}

//-- draws the bingo card itself, which essentially are a bunch of PNG files
//-- the first 25 entries in the bingoIndexList will appear in the card
void drawCard() {
  int drawRowNum = 0;
  int imageWidth = 120;
  
  int drawHeight = 130;
  int hMargin = 10;
  int vMargin = 80 + drawHeight + drawHeight/2;
  int imageXSpace  = 10;
  hMargin = (screenWidth - ((imageWidth * 4) + (imageXSpace * 4))) / 2;
 
  // do this each cycle because of the PDF-saving, which resets these values
  imageMode(CENTER);
  textAlign(CENTER);
  rectMode(CENTER);
  textFont(stateFont);

  // draw card entries
  for( int i = 0; i < 25; i++ ) {
    // increase row number for every 5
    if( i % 5 == 0 )
      drawRowNum++;
      int imageX = hMargin + (i%5 * (imageWidth + imageXSpace));
      int imageY= vMargin + ((drawRowNum-1) * drawHeight);
      image(stateImages[bingoIndexList.get(i)], imageX, imageY, imageWidth, imageWidth);
   }
  
  vMargin -= drawHeight;
  vMargin += 10;
  drawRowNum = 1;
  
  // change image width
  int lettersImageWidth = 75;
  
  // draw upper letters
  for( int i = 0; i < 5; i++ ) {
    int imageX = hMargin + (i%5 * (imageWidth + imageXSpace));
    image(lettersImages[i], imageX, vMargin, lettersImageWidth, lettersImageWidth);
  }
  
  // draw lower letters
  vMargin += (drawHeight * 6);
  vMargin -= 10;
  for( int i = 5; i < 10; i++ ) {
    int imageX = hMargin + (i%5 * (imageWidth + imageXSpace));
    image(lettersImages[i], imageX, vMargin, lettersImageWidth, lettersImageWidth);
  }
}
  
//-- generate a new card by shuffling the bingoIndexList, check to make sure it is a "good" card
//-- place New York at the center
void generateCard() {
  while(true) {
    println("generating card...");
    bingoIndexList.shuffle();
    
    // make New York the center square - this is index 12 from bingoIndexList
    int centerIndexValue = bingoIndexList.get(12);
   
    // look for NY and swap with center one
    for( int i = 0; i < bingoIndexList.size(); i++ ) {
      if( bingoIndexList.get(i) == 29 ) {
        bingoIndexList.set(i, centerIndexValue);
        bingoIndexList.set(12, 29);
      }
    }
    
    // check to see if we have no rows with all dem states and at least two swing-state only rows
    if( goodCard() == true )
      return;
  }
}

//-- check for a goodCard, which is:
// (1) at least 1 swing state for each row/column/diagonal
// (2) ONLY three paths to victory, which means 3 rows/columns/diagonals have NO republican states in them
boolean goodCard() {
   if( checkForDemocratMatch() ) {
      println("all democrat..reshuffling");
      return false;
   }
   
   // ensure at least 3 paths to victory - 10, 11 or 12 republican matches is no good
   if( countAtLeastOneRepublican() != 9 ) {
     println("too many (or too few) all republican");
     return false;
   }
   
   println("good card ");
   return true;
} 

//-- count each possibility, if all 5 in ANY then return true
boolean checkForDemocratMatch() {
  // ROWS
  if( countFive("democrat",0,1,2,3,4) == 5 )
    return true;
    
  if( countFive("democrat",5,6,7,8,9) == 5 )
    return true;
    
   if( countFive("democrat",10,11,12,13,14) == 5 )
    return true;
    
   if( countFive("democrat",15,16,17,18,19) == 5 )
    return true;
    
   if( countFive("democrat",20,21,22,23,24) == 5 )
    return true;
    
  // COLUMNS
  if( countFive("democrat",0,5,10,15,20) == 5 )
    return true;
    
  if( countFive("democrat",1,6,11,16,21) == 5 )
    return true;
    
   if( countFive("democrat",2,7,12,17,22) == 5 )
    return true;
    
   if( countFive("democrat",3,8,13,18,23) == 5 )
    return true;
    
   if( countFive("democrat",4,9,14,19,24) == 5 )
    return true;
    
   // DIAGONALS
   if( countFive("democrat",0,6,12,18,24) == 5 )
    return true;
    
   if( countFive("democrat",4,8,12,16,20) == 5 )
    return true;
    
  return false;
}

//-- return a count of all possibilities where at least one republican state is in there
int countAtLeastOneRepublican() {
  int count = 0;
  // ROWS
  if( countFive("republican",0,1,2,3,4) > 0 )
    count++;
    
  if( countFive("republican",5,6,7,8,9) > 0 )
    count++;
    
   if( countFive("republican",10,11,12,13,14) > 0 )
    count++;
    
   if( countFive("republican",15,16,17,18,19) > 0 )
    count++;
    
   if( countFive("republican",20,21,22,23,24) > 0 )
    count++;
    
  // COLUMNS
  if( countFive("republican",0,5,10,15,20) > 0 )
    count++;
    
  if( countFive("republican",1,6,11,16,21) > 0 )
    count++;
    
   if( countFive("republican",2,7,12,17,22) > 0 )
    count++;
    
   if( countFive("republican",3,8,13,18,23) > 0 )
    count++;
    
   if( countFive("republican",4,9,14,19,24) > 0 )
     count++;
    
   // DIAGONALS
   if( countFive("republican",0,6,12,18,24) > 0 )
    count++;
    
   if( countFive("republican",4,8,12,16,20) > 0 )
    count++;
  
  println("Republican matches = " + count );
  println("Paths to victory = ", 12-count);
  return count;
}

//-- subroutine to do counting
//-- check for number of matches in a given sequence
int countFive(String matchString,int index1, int index2, int index3, int index4, int index5 ) {
  int count = 0;
  
  if( predictions[bingoIndexList.get(index1)].equals(matchString) )
      count++;
  
  if( predictions[bingoIndexList.get(index2)].equals(matchString) )
      count++;
      
  if( predictions[bingoIndexList.get(index3)].equals(matchString) )
      count++;
      
  if( predictions[bingoIndexList.get(index4)].equals(matchString) )
      count++;
      
  if( predictions[bingoIndexList.get(index5)].equals(matchString) )
      count++;
  
       
   return count;
}
