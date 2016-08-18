/*
  OSC_illoscope.pde
  Author: Seb Madgwick
  August 2016 - Pehr Hovey expand to be auto-configurable with channel names, colors and ranges
  
  OSC-illoscope for plotting analogue input channels of x-OSC.  Requires oscP5
  library. See: http://www.sojamo.de/libraries/oscP5/

  Tested with Processing 3.0 and oscP5 0.9.8
*/

import oscP5.*;

float[] channelMax;
float[] channelMin;

int[] selectedChannels;// made in setupForSize// = { 1,2,3,4 };
//int[] selectedChannels = { 1, 2, 3, 4, 5, 6, 7, 8 };
//int[] selectedChannels = { 14, 15, 16 };
//int[] selectedChannels = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };

color[] channelColors;

OscP5 oscP5;
float[] analogInputs = new float[16];
float[] previousYPos;// = new float[selectedChannels.length];
float xPos = 0;
int previousWidth, previousHeigth;  // used to detect window resize

String[] labels = new String[16];
PFont valFont;

final int SCOPE_PORT = 8967; 
final String SCOPE_HOST = "EISM-AM02035509.local";

void setupForSize(int n){
  if(n <=0){ n = 1;}
  println("INIT data for size "+n);
  selectedChannels = new int[n];
  previousYPos = new float[n];
  channelMin = new float[n];
  channelMax = new float[n];

  channelColors = new color[n];
  float hueStep = 255.0 / n;
  colorMode(HSB,255);//restore

  for(int i=0; i < n; i++){
    selectedChannels[i] = i+1; //1-based
    channelMax[i] = 100+i;
    channelMin[i] = 0;
    
    channelColors[i] = color(i*hueStep, 128,128); // not full bright
  }
  colorMode(RGB,255);//restore
}

void setup() {
    setupForSize(3);

  oscP5 = new OscP5(this, SCOPE_HOST,SCOPE_PORT, OscP5.UDP);  
  size(1280, 720);
  if (frame != null) {
    frame.setResizable(true);
  }
  drawBackground();
  
  
  for (int i = 0; i < labels.length; i++) {
     labels[i] = ""; 
  }
  
  valFont = createFont("Arial", 16, true); 
}
boolean gotLabels = false;

void draw() {
  fill(0);
  // draw black on side for values 
  noStroke();
  rect(width-80,0,80,height);
  
  // Trace analogue input values
  strokeWeight(1);  // trace width
  //stroke(255);      // trace colour
  float graphHeight = height / selectedChannels.length;
  
  for (int i = 0; i < selectedChannels.length; i++) {
    stroke(channelColors[i]);

    float maxVal = channelMax[i];
    float minVal = channelMin[i];

    float yPos = map(analogInputs[selectedChannels[i] - 1], minVal, maxVal, i * graphHeight + graphHeight, i * graphHeight);
    line(xPos, previousYPos[i], xPos+1, yPos);
    previousYPos[i] = yPos;
    fill(255);
    // try most recent val
    textFont(valFont, (int)16);
    float val = analogInputs[selectedChannels[i] - 1];

    if(val > maxVal){ 
      fill(200,0,0); 
    }else if(val < minVal){
      fill(0,0,200);
    }else{
      fill(channelColors[i]);
    }
    // red or blue if out of range
     text(String.format("%2.1f",val), width - 76 , (i + 0.5) * graphHeight); // middle
     
     
  // ranges are dimmer 
    fill(128);
    text( String.format("%2.1f",maxVal), width - 76 , (i) * graphHeight + 20); // top

     text( String.format("%2.1f",minVal), width - 76 , (i + 1) * graphHeight-20); // bottom


  }
stroke(255); // default white
  // Restart if graph full or window resized
  if (++xPos >= width || previousWidth != width || previousHeigth != height || gotLabels) {
    restart();
   
  }
   
}

void restart(){
   previousWidth = width;
    previousHeigth = height;
    xPos = 0;
    drawBackground();
    gotLabels=false;
}
void drawBackground() {
  strokeWeight(1);                          // rectangle border width
  PFont f = createFont("Arial", 16, true);  // Arial, 16 point, anti-aliasing on
  for (int i = 0; i < selectedChannels.length; i++) {
    float graphHeight = height / selectedChannels.length;

    // Different rectangle border and fill colour for alternate graphs
    if(i % 2 == 0) {
      stroke(0);
      fill(0);
    }
    else {
      stroke(32);
      fill(32);
    }
    rect(0, i * graphHeight, width, graphHeight);

    // Print channel number
    fill(64);
    textFont(f, (int)(0.5*graphHeight)); // big text in bg
    String lbl = nf(selectedChannels[i], 1) + " " + labels[i];
    text(lbl, 10, (i + 1) * graphHeight);
    

  }
}

void oscEvent(OscMessage theOscMessage) {
  String addrPattern = theOscMessage.addrPattern();

  // Print address pattern to terminal
  println(addrPattern);

  // Analogue input values
  if (addrPattern.equals("/inputs/analogue")) {
     int numChannels = theOscMessage.typetag().length();
     if(numChannels != selectedChannels.length){  
        setupForSize(numChannels);
     }
     
    for(int i = 0; i < analogInputs.length; i ++) {
      
      analogInputs[i] = theOscMessage.get(i).floatValue();
    }
    
  }else if(addrPattern.equals("/inputs/labels")) {
    int numLabels = theOscMessage.typetag().length();
    
    setupForSize(numLabels);
    
        for(int i = 0; i < numLabels && i < labels.length; i ++) {
          labels[i] = theOscMessage.get(i).stringValue();
        }
       gotLabels = true;
  }else if(addrPattern.equals("/inputs/range")){
           gotLabels = true;
        println("Set range ");
    int chanNum = theOscMessage.get(0).intValue();
    float minVal = theOscMessage.get(1).floatValue();
    float maxVal = theOscMessage.get(2).floatValue();
    
    if(chanNum < selectedChannels.length){
      channelMax[chanNum] = maxVal;
      channelMin[chanNum] = minVal;
      println("CHAN "+chanNum+" to min "+minVal+" to max "+maxVal);
    }else{
      println("ERROR bad chan "+chanNum);
    }
  }
}

boolean paused = false;
void keyPressed(){
  switch(key){
     case 'q':
     println("SCREENSHOT");
     saveFrame("plot#####.png");
     break;
     case ' ':
     paused = !paused;
     if(paused){ 
       noLoop();
     }else{
       loop();
     }
     
     break;
     case 'c':
     restart();
     break;
     
  }
      
}