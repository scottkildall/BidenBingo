/*
    Biden Bingo
    Written by Scott Kildall
    www.kildall.com
*/


import processing.pdf.*;


boolean recordToPDF = false;
int numStates;
int newYorkIndex = 31;    // always make NY the center square

IntList bingoIndexList;      // random array 
int screenWidth = 850;
int screenHeight = 1100;

// array of state images, corresponds to the data table
PImage [] stateImages;
String [] stateNames;
String [] predictions;    // "democrat", "swing" or "republican"

PFont stateFont;

int outputFileNum;
int numFilesToOutput = 100;

int numLetters;
PImage [] lettersImages;


void setup() {
  
  
  stateFont = createFont("luximr.ttf", 14);
  

  // fit onto an 8.5 x 11 sheet
  size(850,1100);
  
  loadStateData();
  loadTitles();
  generateCard();
}

void draw() {
  //-- draw background elements
  background(255);
  fill(0,0,255);
  stroke(127,127,127);
  
  if( recordToPDF ) {
    beginRecord(PDF, "bidenbingo_" + outputFileNum + ".pdf");
    background(255);    // flash to white
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

void loadStateData() {
  Table table = loadTable("state_data.csv", "header");
  bingoIndexList = new IntList();
  println(table.getRowCount() + " total rows in table"); 
  
  numStates = table.getRowCount();
  stateImages = new PImage[numStates];
  stateNames = new String[numStates];
  predictions = new String[numStates];
  
  int rowNum = 0;
 
  for (TableRow row : table.rows()) {
    // build the index list
    bingoIndexList.append(rowNum);
     
    stateImages[rowNum] = loadImage("us_states/" + row.getString("Filename"));   
    stateNames[rowNum] = new String(row.getString("State"));
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

void drawCard() {
   drawSquares();  
}

void drawSquares() {
  int drawRowNum = 0;
  int imageWidth = 120;
  
  int drawHeight = 130;
  int hMargin = 10;
  int vMargin = 80 + drawHeight + drawHeight/2;
  int imageXSpace  = 10;
  hMargin = (screenWidth - ((imageWidth * 4) + (imageXSpace * 4))) / 2;
 
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
       int textOffset = 10;
       
      image(stateImages[bingoIndexList.get(i)], imageX, imageY, imageWidth, imageWidth);
       
       // text beneath the state
      //   fill(0);
      // text( stateNames[bingoIndexList.get(i)], imageX,  10 + imageY + imageWidth/2);
  
        //noFill();
        //stroke(0);
        //strokeWeight(2);
       //rect(imageX, imageY + textOffset, imageWidth + 20, imageWidth + 20, 5);
  }
  
  vMargin -= drawHeight;
  vMargin += 10;
  drawRowNum = 1;
  
  // change image width
  int lettersImageWidth = 75;
  // draw letters entries
  for( int i = 0; i < 5; i++ ) {
    int imageX = hMargin + (i%5 * (imageWidth + imageXSpace));
    
    image(lettersImages[i], imageX, vMargin, lettersImageWidth, lettersImageWidth);
    
   // if( i == 5 )
    //  vMargin += drawHeight * 5;
  }
  
  vMargin += (drawHeight * 6);
  vMargin -= 10;
  for( int i = 5; i < 10; i++ ) {
    int imageX = hMargin + (i%5 * (imageWidth + imageXSpace));
    
    image(lettersImages[i], imageX, vMargin, lettersImageWidth, lettersImageWidth);
    
   // if( i == 5 )
    //  vMargin += drawHeight * 5;
  }
}
  

void generateCard() {
  while(true) {
    println("generating card...");
    bingoIndexList.shuffle();
    
    // make New York the center square - this is index 12 from bingoIndexList
    
    int centerIndexValue = bingoIndexList.get(12);
   
   //  // NY already center, just return
   // if( centerIndexValue == 31 )
   //    return;
    
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

boolean goodCard() {
   if( checkForDemocratMatch() ) {
      println("all democrat..reshuffling");
      println("bad card");
      return false;
   }
  
   // ensure at least 3 paths to victory - 10, 11 or 12 republican matches is no good
   if( countAtLeastOneRepublican() != 9 ) {
     println("too many (or too few) all republican");
     println("bad card");
      return false;
   }
   
   println("good card ");
   return true;
} 

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

// return 0 if we have just 1 or 2 swing states
// return 1 if we are all democrat
// return -1 if we are all republican or 3 or more swing states
int checkRow(int startIndex) {
  // check all democrat
  boolean allDemocrat = true;
  for(int i = startIndex; i < startIndex+5; i++ ) {
     if( predictions[bingoIndexList.get(i)].equals("democrat") == false ) {
       allDemocrat = false;
       break;
     }
  }
  
  if( allDemocrat )
    return 1;
    
  return 0;
}

void keyPressed() {
  if( key == 'r' ) {
    outputFileNum = 1;
    recordToPDF = true;
  }
    
  if( key == ' ' ) {
      generateCard();
  }
}
