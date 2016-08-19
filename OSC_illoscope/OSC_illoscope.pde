/*
  OSC_illoscope.pde
  Author: Seb Madgwick
  August 2016 - Pehr Hovey expand to be auto-configurable with channel names, colors and ranges
  
  OSC-illoscope for plotting analogue input channels of x-OSC.  Requires oscP5
  library. See: http://www.sojamo.de/libraries/oscP5/

  Tested with Processing 3.0 and oscP5 0.9.8
*/

import oscP5.*;
final int WIDTH = 1280;
final int HEIGHT = 800;

float[] channelMax;
float[] channelMin;

float plotMax=750;
float plotMin=-plotMax;  // keep it square and balanced by default

String plotXLabel="X";
String plotYLabel="Y";


boolean newPlotPoint = false;
float lastPlotX = 0;
float lastPlotY = 0;

float plotMinX, plotMinY, plotMaxX,plotMaxY; // find the centroid
 float plotCenterX; 
    float plotCenterY; 

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
  size(1280,720);
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

final int MODE_SCOPE = 0;
final int MODE_PLOT = 1;
int mode = MODE_SCOPE;

void drawScope(){
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
     text(String.format("%2.2f",val), width - 76 , (i + 0.5) * graphHeight); // middle
     
     
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

final int PLOT_MARGIN = 32;

void drawPlot(){
  if(!newPlotPoint){ return; }  // NOP
  noStroke();
  fill(0);
  // black out previous text area
  rect(0,0,width,PLOT_MARGIN-1);
  rect(0,height-PLOT_MARGIN,width,PLOT_MARGIN+1);
  
  if(lastPlotX < plotMin || lastPlotY < plotMin){
    fill(0,0,200);
  }else if(lastPlotX > plotMax || lastPlotY > plotMax){
    fill(200,0,0);
  }else{
      fill(255,64);//translucent
  }

  noStroke();
  float w = plotWidth();
  pushMatrix();
 
  translate(PLOT_MARGIN,PLOT_MARGIN);
   float xPos = map(lastPlotX, plotMin, plotMax, 0,w );
   float yPos = map(lastPlotY, plotMin, plotMax, 0,w);
   ellipse(xPos,yPos, 4,4);
  
  
    // red or blue if out of range
  text(String.format("%2.2f, %2.2f",lastPlotX,lastPlotY), 0.5*w, -0.5*PLOT_MARGIN  ); // top middle
     
  fill(200);
  
    text(String.format("%2.2f, %.2f",plotMin,plotMin), -20,-20); 
    
     text(String.format("%2.2f, %.2f",plotMax,plotMax),w-2*PLOT_MARGIN ,w + 20); 

// display current centroid

 

     text(String.format("center %2.2f, %.2f",plotCenterX,plotCenterY),0.5*w-8 ,w + 0.5*PLOT_MARGIN); 



  popMatrix();
  





}

float plotWidth(){
  return  min(width,height) - 2*PLOT_MARGIN;
}

void drawPlotBackground(){
  background(0);
  
  
  PFont f = createFont("Arial", 16, true);  // Arial, 16 point, anti-aliasing on
  textFont(f, 18); 
  
  strokeWeight(1);
  noFill();
  stroke(100);
  pushMatrix();
  translate(PLOT_MARGIN,PLOT_MARGIN);
     float w = plotWidth();
     rect(0,0,w,w);
     
    fill(0,200,0);
    ellipse(0.5f*w,0.5f*w,5,5); // mark the center. 0,0 if plot min,max are opposites

    ellipse(0,w,5,5);
    
        ellipse(w,w,5,5);


    ellipse(0,0,5,5);

    ellipse(w,0,5,5);

  popMatrix();
  
  
      float y = 100;
   
    fill(0);
    
    text("X= "+plotXLabel, w+PLOT_MARGIN, y); 
    text("Y= "+plotYLabel, w+PLOT_MARGIN, y+20); 
    text("YTEST", 600,600); 

}

void draw() {
  fill(0);
  if(mode == MODE_SCOPE){
    drawScope();
  }else{
    drawPlot();
    
  }
  
   
}

void restart(){
   previousWidth = width;
    previousHeigth = height;
    xPos = 0;
    drawBackground();
    gotLabels=false;
    
    plotMinX=  0xFFFF;
    plotMinY=  0xFFFF; 
    plotMaxX= -0xFFFF;
    plotMaxY= -0xFFFF;

}

void drawScopeBackground(){
  
  strokeWeight(1);                          // rectangle border width
  float graphHeight = height / selectedChannels.length;

  PFont f = createFont("Arial", 16, true);  // Arial, 16 point, anti-aliasing on
  textFont(f, (int)(0.5*graphHeight)); // big text in bg

  for (int i = 0; i < selectedChannels.length; i++) {

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
    String lbl = nf(selectedChannels[i], 1) + " " + labels[i];
    text(lbl, 10, (i + 1) * graphHeight);
    

  }
}



void drawBackground() {
  if(mode == MODE_SCOPE){
    drawScopeBackground();
  }else if(mode == MODE_PLOT){
    drawPlotBackground(); 
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
  }else if(addrPattern.equals("/inputs/xy")){
    
   
    newPlotPoint = true;
    lastPlotX = theOscMessage.get(0).floatValue();
    lastPlotY =  theOscMessage.get(1).floatValue();
    
    updatePlotCentroid();
  }else if(addrPattern.equals("/inputs/xysetup")){
    plotXLabel = theOscMessage.get(0).stringValue();
    plotYLabel = theOscMessage.get(1).stringValue();
    plotMin = theOscMessage.get(2).floatValue();
    plotMax = theOscMessage.get(3).floatValue();


  }
}

void updatePlotCentroid(){
    if(lastPlotX < plotMinX)
          plotMinX=lastPlotX;
     if(lastPlotY < plotMinY)
          plotMinY=lastPlotY;
          
      if(lastPlotX > plotMaxX)
          plotMaxX=lastPlotX; 
          
       if(lastPlotY > plotMaxY)
          plotMaxY=lastPlotY;    
       
    plotCenterX = 0.5 * (plotMinX + plotMaxX);
    plotCenterY = 0.5 * (plotMinY + plotMaxY);
 
}

boolean paused = false;
void keyPressed(){
  int lastMode = mode;
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
     
     case '1': println("SCOPE");mode = MODE_SCOPE; break;
     case '2': println("PLOT");mode = MODE_PLOT; break;

     
  }
  
  if(mode != lastMode){ restart();}
      
}