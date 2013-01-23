import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import ddf.minim.*; 
import ddf.minim.analysis.*; 
import java.awt.MouseInfo; 
import java.awt.Point; 
import javax.swing.*; 
import java.lang.*; 
import java.io.File; 
import controlP5.*; 
import sojamo.drop.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class pictualizer extends PApplet {



        //MouseInfo and Point are the classes imported in order to implement smooth window dragging. Doing it with frame.getX() and Y with mouseX and mouseY
            //causes some weird feedback loop that causes the image to shake violently instead of smoothly dragging. Found here: https://forum.processing.org/topic/global-mouse.
             //Swing GUI from java imported ONLY to help minimize the program. 
               //Lang lib used for verifying file input from the drag and drop.

               //ControlP5 GUI Library from Processing's site used for creating text input boxes in Config screen.
             //SDrop lib used to incorporate drag and drop file input. Very handy.


//TO DO LIST:
/* USE SKIP INSTEAD OF CUE FOR SEEKING: CHECK IF POS IS CLOSER TO BEGINNING OR CURRENT, AND DECIDE WHETHER TO USE CUE OR SKIP
 * INTEGRATE HAMMING WINDOW
 * CHECK LOGAVERAGES AND SEE IF IMPLEMENTABLE
 */

//Textfield throws ArrayIndexOutOfBounds because text length exceeds text field length; perhaps try changing the text field length as well every time a resize occurs?
//Memory errors: possible fix is to use removeCache(img)



//Reading and processing input songs.
Minim minim;
AudioInput in;
AudioPlayer songPlayer;
AudioMetaData metaData;
float volume = -15;
boolean playerStart = false;
boolean isPaused = false;
boolean audioInputMode = false;
boolean audioPlayerMode = true;
boolean repeatMode;
boolean shuffleMode;

//Queue system/handler for multiple songs.
ArrayList songQueue;
String songPath = "";
int queueIndex;
int queueCycle;
int queueNumWidth = 0;

//FFT data to return amplitudes of specified frequency bands for bars.
FFT fft;
FFT fft2;
float rectHeight;
int fixHeight;
int fixFFTWidth;
int bar;          //Divider length for bars.
MusicBars bars;

//ControlP5 GUI elements (all textfields).
ControlP5 cp5;
ControlP5 seeker;
Textfield seekField;
Textfield volField;
Textfield barField;
Textfield bassField;
Textfield lowField;
Textfield midField;
Textfield highField;
Textfield allField;
Textfield resizeWidthField;
Textfield resizeHeightField;

//Drag and drop core element.
SDrop drop;
PImage inImage;
PImage filterImage;
PImage newImg;
boolean imgResized = false;
boolean changeImg = false;

//Fonts used.
PFont font;
PFont font2;

//Filters for visualization.
FilterHandler filters;
boolean blurMode;
boolean tintMode;
boolean greyTintMode;
boolean blinkMode;

//Modes of visualization.
boolean stretchMode;
boolean centerMode;

//GUI elements.
boolean displayMeta;
boolean optionMode;
boolean imgMode;
boolean songMode;
boolean queueMode;
boolean modeOn;
int alphaVal;

//Modifiable variables from GUI elements.
int barNum;
boolean divideBars;
float bassSensitivity;
float midSensitivity;
float highSensitivity;
float allSensitivity;
boolean alwaysTop;

//Dragging functions for window movement.
Point mouse;                    
int xPos, yPos;
int helper;
boolean dragHelper = true;
int xloc;
int yloc;


//****************************METHODS************************************
//***********************************************************************
public boolean isInteger(String str) 
{
  try 
  {
    Integer.parseInt(str);
    return true;
  } 
  catch (NumberFormatException nfe) {
  }
  return false;
}

public boolean isFloat(String str)
{
  try
  {
    parseFloat(str);
    return true;
  }
  catch (NumberFormatException nfe) {
  }
  return false;
}

//Add parameter to specify how much of a string is needed to be truncated. I need this so that I can have the proper length for the displayMetaData
//and QUEUE menu.
public String truncatePath(String str)
{
  StringBuffer helper = new StringBuffer();
  helper.append(str);
  String fileName = str.substring(helper.lastIndexOf("\\") + 1, helper.lastIndexOf("."));
  helper.delete(0, helper.length());
  if ( ((3 * width)/20 + textWidth(fileName)) > (15 * width)/20 )
  {  
    while ( ( (3 * width)/20 + textWidth(fileName)) > (15 * width)/20 )
    {
      fileName = fileName.substring(0, fileName.length() - 1);
    }
    helper.append(fileName);
    helper.replace(helper.length() - 2, helper.length(), "...");
    fileName = helper.toString();
  }
  return fileName;
}

public String removeChar(String str)
{
  int length = str.length();
  StringBuffer digits = new StringBuffer(length);
  for (int i = 0; i < length; i++)
  {
    char ch = str.charAt(i);
    if ( Character.isDigit(ch) )
    {
      digits.append(ch);
    }
  }
  return digits.toString();
}

public int convertToMillis(int minutesSeconds)
{
  int seconds = minutesSeconds % 100;
  int minutes = minutesSeconds / 100;
  return (minutes*60000) + (seconds*1000);
}

public int millisToSeconds(int milliseconds)
{
  return (milliseconds/1000)%60;
}

public int millisToMinutes(int milliseconds)
{
  return milliseconds/60000;
}


//HELPFUL ADVICE:
//As an example, if you construct a FourierTransform with a timeSize of 1024 and and a sampleRate of 44100 Hz, 
//then the spectrum will contain values for frequencies below 22010 Hz, which is the Nyquist frequency (half the sample rate). 
//If you ask for the value of band number 5, this will correspond to a frequency band centered on 5/1024 * 44100 = 0.0048828125 * 44100 = 215 Hz.

public void init()
{
  // to make a frame not displayable, you can
  // use frame.removeNotify()

  frame.removeNotify();
  frame.setUndecorated(true);

  // addNotify, here i am not sure if you have 
  // to add notify again.  
  frame.addNotify();
  super.init();
}


public void setup()
{ 
  inImage = loadImage("background.jpg");
  if ( ( inImage.width > displayWidth ) || ( inImage.height > displayHeight ) )
  {
    if ( inImage.width > inImage.height )
    {
      inImage.resize(displayWidth, 0);
      if ( inImage.height > displayHeight )
      {
        inImage.resize(0, displayHeight);
      }
    }
    else
    {
      inImage.resize(0, displayHeight);
    }
  }
  size(inImage.width, inImage.height, JAVA2D);

  tintMode = true;
  blinkMode = true;

  stretchMode = true;
  barNum = 9;

  divideBars = true;              
  displayMeta = true;


  bassSensitivity = .0075f;        
  midSensitivity = .02f;
  highSensitivity = .06f;
  allSensitivity = 1;

  minim = new Minim(this);
  in = minim.getLineIn();

  fft = new FFT(in.bufferSize(), in.sampleRate());

  fixFFTWidth = ceil(width - ((width/barNum) * barNum));  //Simple but not advanced hack to eliminate the problem with bars rounding their coordinates and thus
  if (fixFFTWidth < barNum)                                //leaving empty pixels at the very end of the picture.
    fixFFTWidth = 1;
  else
    fixFFTWidth = ceil(fixFFTWidth/barNum);

  songPlayer = minim.loadFile("03-tokyo_jihen-kokoro-jrp.mp3");
  songPlayer.pause();

  songQueue = new ArrayList();

  fft2 = new FFT(songPlayer.bufferSize(), songPlayer.sampleRate());

  font = createFont("Century Gothic", 10, true);
  font2 = createFont("Meiryo", (width + height)/100, true);

  //*************TESTING NEW CLASSES*****************
  filters = new FilterHandler(songPlayer, inImage);
  bars = new MusicBars(songPlayer, inImage, font);
  bars.pauseBars();


  seeker = new ControlP5(this);
  cp5 = new ControlP5(this);
  cp5.hide();
  cp5.disableShortcuts();                //removes annoying ControlP5 "alt"-key feature that moves the textfields, sometimes disabling input for those fields.
  cp5.setMoveable(false);
  seeker.disableShortcuts();
  seeker.setMoveable(false);

  barField = cp5.addTextfield("")
    .setPosition((5 * width)/20 + textWidth(": :bars"), (20 * height)/32 - textAscent() + 1)
      .setSize((4 * width)/80, (int) textAscent())
        .setFont(font)
          .setText(""+bars.getNumBars())           
            .setFocus(false)
              .setInputFilter(ControlP5.INTEGER)
                .setColor(color(255, 255, 255))
                  .setAutoClear(false)
                    .setColorForeground(323232)
                      .setColorBackground(323232)
                        .setColorActive(323232)
                          ;

  bassField = cp5.addTextfield(" ")
    .setPosition((21 * width)/40 + textWidth(": : bass"), (11 * height)/32 - textAscent() + 1)
      .setSize((4 * width)/80, (int) textAscent())
        .setFont(font)
          .setText(""+bars.getBassSensitivity())           
            .setFocus(false)
              .setInputFilter(ControlP5.FLOAT)
                .setColor(color(255, 255, 255))
                  .setAutoClear(false)
                    .setColorForeground(323232)
                      .setColorBackground(323232)
                        .setColorActive(323232)
                          ;
  midField = cp5.addTextfield("  ")
    .setPosition((21 * width)/40 + textWidth(": : bass"), (12 * height)/32 - textAscent() + 1)
      .setSize((4 * width)/80, (int) textAscent())
        .setFont(font)
          .setText(""+bars.getMidSensitivity())            
            .setFocus(false)
              .setInputFilter(ControlP5.FLOAT)
                .setColor(color(255, 255, 255))
                  .setAutoClear(false)
                    .setColorForeground(323232)
                      .setColorBackground(323232)
                        .setColorActive(323232)
                          ;
  highField = cp5.addTextfield("   ")
    .setPosition((21 * width)/40 + textWidth(": : bass"), (13 * height)/32 - textAscent() + 1)
      .setSize((4 * width)/80, (int) textAscent())
        .setFont(font)
          .setText(""+bars.getHiSensitivity())           
            .setFocus(false)
              .setInputFilter(ControlP5.FLOAT)
                .setColor(color(255, 255, 255))
                  .setAutoClear(false)
                    .setColorForeground(323232)
                      .setColorBackground(323232)
                        .setColorActive(323232)
                          ;
  allField = cp5.addTextfield("    ")
    .setPosition((21 * width)/40 + textWidth(": : bass"), (14 * height)/32 - textAscent() + 1)
      .setSize((4 * width)/80, (int) textAscent())
        .setFont(font)
          .setText(""+bars.getAllSensitivity())            
            .setFocus(false)
              .setInputFilter(ControlP5.FLOAT)
                .setColor(color(255, 255, 255))
                  .setAutoClear(false)
                    .setColorForeground(323232)
                      .setColorBackground(323232)
                        .setColorActive(323232)
                          ;

  resizeWidthField = cp5.addTextfield("      ")
    .setPosition((22 * width)/40 + textWidth(": :bass"), (19 * height)/32 - textAscent() + 1)
      .setSize((4 * width)/80, (int) textAscent())
        .setFont(font)
          .setText(""+width)            
            .setFocus(false)
              .setInputFilter(ControlP5.INTEGER)
                .setColor(color(255, 255, 255))
                  .setAutoClear(false)
                    .setColorForeground(323232)
                      .setColorBackground(323232)
                        .setColorActive(323232)
                          ;
  resizeHeightField = cp5.addTextfield("       ")
    .setPosition((22 * width)/40 + textWidth(": :bass"), (20 * height)/32 - textAscent() + 1)
      .setSize((4 * width)/80, (int) textAscent())
        .setFont(font)
          .setText(""+height)            
            .setFocus(false)
              .setInputFilter(ControlP5.INTEGER)
                .setColor(color(255, 255, 255))
                  .setAutoClear(false)
                    .setColorForeground(323232)
                      .setColorBackground(323232)
                        .setColorActive(323232)
                          ;

  textFont(font2, (width + height)/100);
  seekField = seeker.addTextfield("        ")
    .setPosition(textAscent() * 11, textAscent() * 5.1f)
      .setSize((int) textWidth("00:00"), (int) textAscent())
        .setFont(font2)
          .setText("time")
            .setFocus(false)
              .setColor(color(255, 255, 255))
                .setColorBackground(0x00ffffff)
                  .setAutoClear(false)
                    .setColorForeground(0x00ffffff)
                      .setColorBackground(0x00ffffff)
                        .setColorActive(0x00ffffff)
                          ;

  volField = seeker.addTextfield("         ")
    .setPosition(textAscent() * 12.2f, textAscent() * 6.1f)
      .setSize((int) textWidth("00:00"), (int) textAscent())
        .setFont(font2)
          .setText(""+volume)
            .setFocus(false)
              .setColor(color(175, 175, 175))
                .setColorBackground(0x00ffffff)
                  .setAutoClear(false)
                    .setColorForeground(0x00ffffff)
                      .setColorBackground(0x00ffffff)
                        .setColorActive(0x00ffffff)
                          ;

  seeker.hide();

  drop = new SDrop(this);

  frame.setResizable(true);            //Allows the frame to be resized.
  noStroke();
  smooth();
  frameRate(60);
}

public void dropEvent(DropEvent theDropEvent) 
{
  if ( theDropEvent.isImage() ) 
  { 
    if ( imgResized )                //Refresh text input fields, since controlp5's text fields are BUGGY AS SHIT. HOLY FUCK.
    {
      imgResized = false;
    }
    newImg = theDropEvent.loadImage();
    changeImg = true;
    imgResized = true;
  }
  else if ( theDropEvent.isFile() && audioPlayerMode )
  { 
    File myFile = theDropEvent.file();
    if ( myFile.isDirectory() )
    {
      int helper = 0;
      File[] folder = theDropEvent.listFilesAsArray(myFile, true);
      String[] songs = new String[folder.length];
      for ( int i = 0; i < folder.length; i++ )
      {
        songs[i] = folder[i].getPath();
        if ( songs[i].indexOf(".mp3") != -1 || songs[i].indexOf(".wav") != -1 || songs[i].indexOf(".MP3") != -1 || songs[i].indexOf(".WAV") != -1 )
        {
          helper = i;
          songQueue.add(""+songs[i]);
          queueIndex = songQueue.size();
        }
      }
      if ( helper != 0 )
      { 
        if ( queueIndex > 9 )
        {
          queueCycle = queueIndex - 9;
        }
        songPlayer.close();
        minim.stop();
        minim = new Minim(this);
        songPlayer = minim.loadFile(songs[helper]);
        bars.changeSource(songPlayer);
        filters.changeSource(songPlayer, 0);
        metaData = songPlayer.getMetaData();
        songPlayer.setGain(volume);
        songPlayer.play();
        bars.startBars();
        playerStart = true;
        songs = null;
      }
    }
    songPath = ""+theDropEvent.filePath();
    if ( songPath.endsWith(".mp3") || songPath.endsWith(".wav") || songPath.endsWith(".MP3") || songPath.endsWith(".WAV") )
    { 
      if ( queueIndex > 9 )
      {
        queueCycle = queueIndex - 8;
      }
      songPlayer.close();
      minim.stop();
      minim = new Minim(this);
      songPlayer = minim.loadFile(songPath);
      bars.changeSource(songPlayer);
      filters.changeSource(songPlayer, 0);
      metaData = songPlayer.getMetaData();
      songPlayer.setGain(volume);
      songPlayer.play();
      bars.startBars();
      playerStart = true;
      songQueue.add(""+songPath);
      queueIndex = songQueue.size();
    }
  }
}

public void draw()                //My goal is to divide the total frequency spectrum into X bars for visualization. Thus, each bar spans a range of 22050Hz/X.
{ 
  if ( changeImg )                  
  { 
    //SDROP caused me so more trouble than I had ever imagined. 
    //This loop addresses the delay SDROP has with its drop event image processing; if it messes up
    //and still has not loaded the image properly, the frame is redrawn until it has finally loaded it.
    g.removeCache(inImage);
    inImage = null;
    System.gc();
    while ( newImg.get (0, 0) == newImg.get(newImg.width, newImg.height) )        
    {
      redraw();
    }
    inImage = newImg;
    g.removeCache(newImg);
    newImg = null;
    System.gc();
    if ( ( inImage.width > displayWidth ) || ( inImage.height > displayHeight ) )
    {
      if ( inImage.width > inImage.height )
      {
        inImage.resize(displayWidth, 0);
        if ( inImage.height > displayHeight )
        {
          inImage.resize(0, displayHeight);
        }
      }
      else
      {
        inImage.resize(0, displayHeight);
      }
    }
    filters.changeImage(inImage);
    bars.changeImage(inImage);
    frame.setSize(inImage.width, inImage.height);
    changeImg = false;
    fixFFTWidth = ceil(width - ((width/barNum) * barNum));
    if (fixFFTWidth < barNum)
      fixFFTWidth = 1;
    else
      fixFFTWidth = ceil(fixFFTWidth/barNum);
  }   

  image(inImage, 0, 0);
  filters.applyFilters(); 
  bars.drawBars();

  displayGUI();

  if ( audioPlayerMode )
    checkPlayerStatus();
}

public void checkPlayerStatus()
{
  if ( !songPlayer.isPlaying() && !isPaused && playerStart && queueIndex - 1 < songQueue.size() && queueIndex > 0)
  {
    if ( repeatMode )
    {
      songPlayer.close();
      minim.stop();
      minim = new Minim(this);
      songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
      if ( queueIndex > 9 )
      {
        queueCycle = queueIndex - 9;
      }
      filters.changeSource(songPlayer, 0); 
      bars.changeSource(songPlayer);      
      metaData = songPlayer.getMetaData();
      songPlayer.setGain(volume);
      songPlayer.play();
      playerStart = true;
    }
    else if ( shuffleMode )
    { 
      songPlayer.close();
      minim.stop();
      minim = new Minim(this);
      queueIndex = round(random(1, songQueue.size()));
      songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
      if ( queueIndex > 9 )
      {
        queueCycle = queueIndex - 9;
      }
      filters.changeSource(songPlayer, 0);   
      bars.changeSource(songPlayer);    
      metaData = songPlayer.getMetaData();
      songPlayer.setGain(volume);
      songPlayer.play();
      playerStart = true;
    }
    else if ( queueIndex + 1 < songQueue.size() )
    { 
      songPlayer.close();
      minim.stop();
      minim = new Minim(this);
      queueIndex++;
      songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
      filters.changeSource(songPlayer, 0);
      bars.changeSource(songPlayer);      
      metaData = songPlayer.getMetaData();
      songPlayer.setGain(volume);
      songPlayer.play();
      playerStart = true;
      if ( queueIndex > 9 )
      {
        queueCycle = queueIndex - 9;
      }
    }
  }
}

public void displayGUI()
{
  if ( imgResized )                      //PControl textfields are totally NOT friendly with resizing. Apparently setting them up ONCE after resizing doesn't do anything, so I just compromised
  {                                      //by looping their new coordinates during the options screen. Shouldn't really cost any significant CPU or FPS loss anyways..
    barField.setPosition((5 * width)/20 + textWidth(": :   bars"), (20 * height)/32 - textAscent());
    bassField.setPosition((21 * width)/40 + textWidth(": :    bass"), (11 * height)/32 - textAscent() + 1);
    midField.setPosition((21 * width)/40 + textWidth(": :    bass"), (12 * height)/32 - textAscent() + 1);
    highField.setPosition((21 * width)/40 + textWidth(": :    bass"), (13 * height)/32 - textAscent() + 1);
    allField.setPosition((21 * width)/40 + textWidth(": :    bass"), (14 * height)/32 - textAscent() + 1);
    resizeWidthField.setPosition((22 * width)/40 + textWidth(": :  bass"), (19 * height)/32 - textAscent() + 1);
    resizeHeightField.setPosition((22 * width)/40 + textWidth(": :  bass"), (20 * height)/32 - textAscent() + 1);
    textFont(font2, (width + height)/100);
    seekField.setPosition(textAscent() * 11 + queueNumWidth, textAscent() * 5.1f)
      .setSize((int) textWidth("00:00"), (int) textAscent())
        .setFont(font2);
    volField.setPosition(textAscent() * 12.2f + queueNumWidth, textAscent() * 6.1f)
      .setSize((int) textAscent()*5, (int) textAscent())
        .setFont(font2);
  }

  textFont(font, (width + height)/125);
  if ( mouseY < textAscent() * 2.5f)                        //Reveals the task bar on top of the program.
  {                                                 //Triggered by movement of the mouse into the top of the program.
    textFont(font, (width + height)/125);
    textAlign(LEFT);
    fill(50, 50, 50, 50);
    rect(0, 0, width, textAscent() * 2.5f);
    fill(225, 225, 225, alphaVal);
    text("Image", width/15, textAscent() * 1.5f);
    text("Song", width/4, textAscent() * 1.5f);
    text("Display", width/2.35f, textAscent() * 1.5f);
    text("Options", width/1.65f, textAscent() * 1.5f);
    text("Queue", width/1.27f, textAscent() * 1.5f);
    text("---", width/1.075f, textAscent() * 1.5f);
    text("X", width/1.035f, textAscent() * 1.5f);
    if ( alphaVal < 255 )
    {
      alphaVal = alphaVal + 15;
    }  
    if ( ((mouseX > width/15) && (mouseX < width/15 + textWidth("Image"))) 
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5f + textDescent())) )     //Highlights "Image" when it is selected.
    { 
      fill(255, 255, 255);
      text("Image", width/15, textAscent() * 1.5f);
    }
    if ( ((mouseX > width/4) && (mouseX < width/4 + textWidth("Song")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5f + textDescent())) )     //Highlights "Song" when it is selected.
    {
      fill(255, 255, 255);
      text("Song", width/4, textAscent() * 1.5f);
    }
    if ( ((mouseX > width/2.35f) && (mouseX < width/2.35f + textWidth("Display")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5f + textDescent())) )     //Highlights "Display" when it is selected.
    {
      fill(255, 255, 255);
      text("Display", width/2.35f, textAscent() * 1.5f);
    }
    if ( ((mouseX > width/1.65f) && (mouseX < width/1.65f + textWidth("Options")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5f + textDescent())) )     //Highlights "Option" when it is selected.
    { 
      fill(255, 255, 255);
      text("Options", width/1.65f, textAscent() * 1.5f);
    }
    if ( ((mouseX > width/1.27f) && (mouseX < width/1.27f + textWidth("Queue")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5f + textDescent())) )     //Highlights "Queue" when it is selected.
    { 
      fill(255, 255, 255);
      text("Queue", width/1.27f, textAscent() * 1.5f);
    }
    if ( ((mouseX > width/1.075f) && (mouseX < width/1.075f + textWidth("---")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5f + textDescent())) )     //Highlights "---" when it is selected.
    {
      fill(255, 255, 255);
      text("---", width/1.075f, textAscent() * 1.5f);
    }
    if ( ((mouseX > width/1.035f) && (mouseX < width/1.035f + textWidth("X")))   
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5f + textDescent())) )     //Highlights "X" when it is selected.
    {
      fill(255, 255, 255);
      text("X", width/1.035f, textAscent() * 1.5f);
    }
  }
  if ( mouseY > textAscent() * 2.5f )                      //Fades the task bar on the top of the program.
  {                                              //Triggered by removal of the mouse from the top of the program.
    alphaVal = 0;
  }


  if ( audioPlayerMode && playerStart && displayMeta && !modeOn )
  {
    textFont(font2, (width+height)/100);
    textAlign(LEFT);
    if ( ((mouseX > textAscent() * 3) && (mouseX < textAscent() * 6 + textWidth(">>") + queueNumWidth)) && ((mouseY > textAscent() * 2) && (mouseY < textAscent() * 7.5f)) )
    {
      fill(255, 255, 255, 50);
      text("<<", textAscent() * 3 + queueNumWidth/2, textAscent() * 7.5f);
      text(">>", textAscent() * 6 + queueNumWidth/2, textAscent() * 7.5f);
      if ( ((mouseX > textAscent() * 3 + queueNumWidth/2) && (mouseX < textAscent() * 3 + textWidth("<<") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5f) && (mouseY > textAscent() * 6.5f )) )
      {
        fill(255, 255, 255);
        text("<<", textAscent() * 3 + queueNumWidth/2, textAscent() * 7.5f);
      }
      if ( ((mouseX > textAscent() * 6 + queueNumWidth/2) && (mouseX < textAscent() * 6 + textWidth(">>") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5f) && (mouseY > textAscent() * 6.5f )) )
      {
        fill(255, 255, 255);
        text(">>", textAscent() * 6 + queueNumWidth/2, textAscent() * 7.5f);
      }
    }
    if ( ((mouseX > textAscent() * 8.5f + queueNumWidth) && (mouseX < textAscent() * 8.5f + textWidth(truncatePath(metaData.fileName())+" ("
      +millisToMinutes(songPlayer.length())+":0"+millisToSeconds(songPlayer.length())+")")+ queueNumWidth)) 
      && ( (mouseY < textAscent() * 8.5f) && (mouseY > textAscent() * 2.8f )) )  
    { 
      fill(175, 175, 175);
      text("volume:", textAscent() * 8.5f + queueNumWidth, textAscent() * 6.9f);
      volField.show();  
      if ( repeatMode )
      { 
        fill(255, 255, 255);
        text("re /", textAscent() * 8.5f + queueNumWidth, textAscent() * 7.9f);
        fill(175, 175, 175);
        text(" shuff", textAscent() * 8.5f + textWidth("re /") + queueNumWidth, textAscent() * 7.9f);
      }
      else if ( shuffleMode )
      {
        fill(175, 175, 175);
        text("re ", textAscent() * 8.5f + queueNumWidth, textAscent() * 7.9f);
        fill(255, 255, 255);
        text("/ shuff", textAscent() * 8.5f + textWidth("re ") + queueNumWidth, textAscent() * 7.9f);
      }
      else
      {
        fill(175, 175, 175);
        text("re / shuff", textAscent() * 8.5f + queueNumWidth, textAscent() * 7.9f);
      }
    }
    else
      volField.hide();
  }

  if ( imgMode )
  { 
    cp5.hide();
    fill(50, 50, 50, 50);
    rect(width/5, height/4, (3*width)/5, height/2);
    fill(255, 255, 255);
    textFont(font, round(width/30));
    textAlign(LEFT);
    text("SELECT IMAGE", width/5, height/4);      //Automatically adjusted font size based on image width for SELECT IMAGE text.
    textAlign(CENTER);
    textFont(font, 9);
    text("To select an image for visualization,", width/2, height/2);
    text("drag and drop the desired image anywhere inside.", width/2, height/2 + textAscent());
    text("This can be done inside or outside of this option", width/2, height/2 + textAscent() * 2);
    text("during realtime visualization.", width/2, height/2 + textAscent()*3);
  }

  if ( songMode )
  {
    cp5.hide();
    fill(50, 50, 50, 50);
    rect(width/5, height/4, (3*width)/5, height/2);
    fill(255, 255, 255);
    textFont(font, round(width/30));
    textAlign(LEFT);
    text("SELECT SONG", width/5, height/4);
    textAlign(CENTER);
    textFont(font, 9);
    text("To select songs for visualization,", width/2, height/2);
    text("drag and drop the desired song(s) anywhere inside.", width/2, height/2 + textAscent());
    text("This can be done inside or outside of this option", width/2, height/2 + textAscent() * 2);
    text("during realtime visualization.", width/2, height/2 + textAscent()*3);
    textAlign(LEFT);
    textFont(font, 16);  
    text("Modes", (5 * width)/20, (5 * height)/16);
    textFont(font, 10);
    if ( audioInputMode )
    { 
      fill(255, 255, 255);
      text(": :  recording device / audio input", (5 * width)/20, (11 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  recording device / audio input", (5 * width)/20, (11 * height)/32);
    }
    if ( audioPlayerMode )
    {
      fill(255, 255, 255);
      text(": :  music player", (5 * width)/20, (12 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  music player", (5 * width)/20, (12 * height)/32);
    }
  }

  if ( displayMeta && !modeOn )                    //Displays Audio Metadata analyzed by Minim's player.
  { 
    fill(255, 255, 255);
    textFont(font, (height + width)/35);
    textAlign(RIGHT, BASELINE);
    if ( audioPlayerMode && songPlayer.isPlaying() )
    {
      text(": :  PLAYING", width - textAscent(), height - textAscent() * 3.5f);
    }
    else if ( playerStart && audioPlayerMode )
    {
      text(": :  PAUSED", width - textAscent(), height - textAscent() * 3.5f);
    }

    if ( playerStart && audioPlayerMode )
    { 
      seeker.show();
      textFont(font, (height + width)/25);
      textAlign(LEFT);
      if ( queueIndex < 10 )
      {
        text("0"+queueIndex, textAscent() - textDescent(), textAscent() * 1.5f);
      }
      else
      {
        text(""+queueIndex, textAscent() - textDescent(), textAscent() * 1.5f);
        queueNumWidth = (int) textWidth(""+queueIndex) - (int) textWidth("0"+queueIndex%10);
      }
      textFont(font2, (height + width)/100);
      if ( millisToSeconds(songPlayer.length()) < 10 )
      {
        text(""+truncatePath(metaData.fileName())+" ("+millisToMinutes(songPlayer.length())+":0"+millisToSeconds(songPlayer.length())+")", textAscent() * 8.5f + queueNumWidth, textAscent() * 3.8f);
      }
      else
      {
        text(""+truncatePath(metaData.fileName())+" ("+millisToMinutes(songPlayer.length())+":"+millisToSeconds(songPlayer.length())+")", textAscent() * 8.5f + queueNumWidth, textAscent() * 3.8f);
      }
      if ( metaData.author().equals("") )
      {
        text("unknown", textAscent() * 8.5f + queueNumWidth, textAscent() * 4.9f);
      }
      else
      {
        text(""+metaData.author()+"", textAscent() * 8.5f + queueNumWidth, textAscent() * 4.9f);
      }
      textFont(font2, (width + height)/100);
      text("seek:", textAscent() * 8.5f + queueNumWidth, textAscent() * 5.9f);
      seekField.setPosition(textAscent() * 11 + queueNumWidth, textAscent() * 5.1f);
      volField.setPosition(textAscent() * 12.2f + queueNumWidth, textAscent() * 6.1f);
      textFont(font, (width + height)/11);
      fill(255, 255, 255);
      textAlign(RIGHT, BASELINE);
      if ( millisToSeconds(songPlayer.position()) < 10 )
      {
        text(""+millisToMinutes(songPlayer.position())+":0"+millisToSeconds(songPlayer.position()), width - textDescent(), height - textDescent());
      }
      else
      {
        text(""+millisToMinutes(songPlayer.position())+":"+millisToSeconds(songPlayer.position()), width - textDescent(), height - textDescent());
      }
    }
  }
  else
  {
    seeker.hide();
  }  

  if ( optionMode )                    //Displays the Options menu.
  { 
    cp5.show();
    fill(50, 50, 50, 50);
    rect(width/5, height/4, (3*width)/5, height/2);
    fill(255, 255, 255);
    textFont(font, round(width/30));
    textAlign(LEFT);
    text("CONFIGURATION", width/5, height/4);      //Automatically adjusted font size based on image width for CONFIGURATION text.
    textFont(font, 16);

    text("Filters", (5 * width)/20, (5 * height)/16);
    text("Bars", (5 * width)/20, (11 * height)/20);
    text("Misc", (21 * width)/40, (11 * height)/20);
    text("Sensitivity", (21 * width)/40, (5 * height)/16);
    textFont(font, 10);
    if ( blurMode )
    { 
      fill(255, 255, 255);
      text(": :  blur", (5 * width)/20, (11 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  blur", (5 * width)/20, (11 * height)/32);
    }
    if ( bars.getBassSensitivity() != 0 )
    {
      fill(255, 255, 255);
      text(": :  bass", (21 * width)/40, (11 * height)/32);
      bassField.setColor(0xffFFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  bass", (21 * width)/40, (11 * height)/32);
      bassField.setColor(0xff969696);
    }
    if ( greyTintMode )
    {
      fill(255, 255, 255);
      text(": :  gray tint", (5 * width)/20, (12 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  gray tint", (5 * width)/20, (12 * height)/32);
    }
    if ( bars.getMidSensitivity() != 0 )
    {
      fill(255, 255, 255);
      text(": :  mid", (21 * width)/40, (12 * height)/32);
      midField.setColor(0xffFFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  low", (21 * width)/40, (12 * height)/32);
      lowField.setColor(0xff969696);
    }
    if ( tintMode )
    {
      fill(255, 255, 255);
      text(": :  tint", (5 * width)/20, (13 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  tint", (5 * width)/20, (13 * height)/32);
    }
    if ( bars.getHiSensitivity() != 0 )
    {
      fill(255, 255, 255);
      text(": :  high", (21 * width)/40, (13 * height)/32);
      highField.setColor(0xffFFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  mid", (21 * width)/40, (13 * height)/32);
      midField.setColor(0xff969696);
    }
    if ( blinkMode )
    {
      fill(255, 255, 255);
      text(": :  blink", (5 * width)/20, (14 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  blink", (5 * width)/20, (14 * height)/32);
    }
    if ( bars.getAllSensitivity() != 0 )
    {
      fill(255, 255, 255);
      text(": :  all", (21 * width)/40, (14 * height)/32);
      allField.setColor(0xffFFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  high", (21 * width)/40, (14 * height)/32);
      highField.setColor(0xff969696);
    }
    if ( divideBars )
    {
      fill(255, 255, 255);
      text(": :  dividers", (5 * width)/20, (19 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  dividers", (5 * width)/20, (19 * height)/32);
    }
    if ( bars.getNumBars() != 0 )
    {
      fill(255, 255, 255);
      text(": :  bars", (5 * width)/20, (20 * height)/32);
      barField.setColor(0xffFFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  bars", (5 * width)/20, (20 * height)/32);
      barField.setColor(0xff969696);
    }
    if ( bars.getMode() == bars.CENTER_MODE )
    {
      fill(255, 255, 255);
      text(": :  center", (5 * width)/20, (21 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  center", (5 * width)/20, (21* height)/32);
    }
    if ( alwaysTop )
    {
      fill(255, 255, 255);
      text(": :  always on top", (21 * width)/40, (21 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  always on top", (21 * width)/40, (21 * height)/32);
    }     
    fill(255, 255, 255);
    text(": :  width", (21 * width)/40, (19 * height)/32);
    text(": :  height", (21 * width)/40, (20 * height)/32);
  }

  if ( queueMode )
  {
    fill(50, 50, 50, 50);
    rect(width/5, height/4, (3*width)/5, height/2);
    fill(255, 255, 255);
    textFont(font, round(width/30));
    textAlign(LEFT);
    text("SONG QUEUE", width/5, height/4);      //Automatically adjusted font size based on image width for SONG QUEUE text.
    textFont(font2, (width+height)/125);
    fill(100, 100, 100);
    if ( queueCycle < songQueue.size() )
    {
      text(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle)), width/3.5f, height/3);
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle))))
        && (mouseY > height/3 - textAscent() && mouseY < height/3 ) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle)), width/3.5f, height/3);
        }
        else
        { 
          fill(175, 175, 175);
          text(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle)), width/3.5f, height/3);
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3);
          fill(100, 100, 100);
        }
        else
        {
          fill(100, 100, 100);
          text("X", width/3.7f, height/3);
        }
      }
    }
    if ( queueCycle + 1 < songQueue.size() )
    {
      text(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1)), width/3.5f, height/3 + height/25);
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1))))
        && (mouseY > height/3 + height/25 - textAscent() && mouseY < height/3 + height/25 ) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 1))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 1) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1)), width/3.5f, height/3 + height/25);
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1)), width/3.5f, height/3 + height/25);
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3 + height/25);
        }
        fill(100, 100, 100);
        text("X", width/3.7f, height/3 + height/25);
      }
    }
    if ( queueCycle + 2 < songQueue.size() )
    {
      text(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2)), width/3.5f, height/3 + (2 * height/25));
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2))))
        && (mouseY > height/3 + (2 * height/25) - textAscent() && mouseY < height/3 + (2 * height/25 )) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 2))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 2) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2)), width/3.5f, height/3 + (2 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2)), width/3.5f, height/3 + (2 * height/25));
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3 + (2 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7f, height/3 + (2 * height/25));
      }
    }
    if ( queueCycle + 3 < songQueue.size() )
    {
      text(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3)), width/3.5f, height/3 + (3 * height/25));
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3))))
        && (mouseY > height/3 + (3 * height/25) - textAscent() && mouseY < height/3 + (3 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 3))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 3) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3)), width/3.5f, height/3 + (3 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3)), width/3.5f, height/3 + (3 * height/25));
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3 + (3 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7f, height/3 + (3 * height/25));
      }
    }
    if ( queueCycle + 4 < songQueue.size() )
    {
      text(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4)), width/3.5f, height/3 + (4 * height/25));
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4))))
        && (mouseY > height/3 + (4 * height/25) - textAscent() && mouseY < height/3 + (4 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 4))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 4) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4)), width/3.5f, height/3 + (4 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4)), width/3.5f, height/3 + (4 * height/25));
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3 + (4 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7f, height/3 + (4 * height/25));
      }
    }
    if ( queueCycle + 5 < songQueue.size() )
    {
      text(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5)), width/3.5f, height/3 + (5 * height/25));
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5))))
        && (mouseY > height/3 + (5 * height/25) - textAscent() && mouseY < height/3 + (5 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 5))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 5) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5)), width/3.5f, height/3 + (5 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5)), width/3.5f, height/3 + (5 * height/25));
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3 + (5 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7f, height/3 + (5 * height/25));
      }
    }
    if ( queueCycle + 6 < songQueue.size() )
    {
      text(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6)), width/3.5f, height/3 + (6 * height/25));
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6))))
        && (mouseY > height/3 + (6 * height/25) - textAscent() && mouseY < height/3 + (6 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 6))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 6) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6)), width/3.5f, height/3 + (6 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6)), width/3.5f, height/3 + (6 * height/25));
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3 + (6 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7f, height/3 + (6 * height/25));
      }
    }
    if ( queueCycle + 7 < songQueue.size() )
    {
      text(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7)), width/3.5f, height/3 + (7 * height/25));
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7))))
        && (mouseY > height/3 + (7 * height/25) - textAscent() && mouseY < height/3 + (7 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 7))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 7) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7)), width/3.5f, height/3 + (7 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7)), width/3.5f, height/3 + (7 * height/25));
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3 + (7 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7f, height/3 + (7 * height/25));
      }
    }
    if ( queueCycle + 8 < songQueue.size() )
    {
      text(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8)), width/3.5f, height/3 + (8 * height/25));
      if ( (mouseX > width/3.7f && mouseX < width/3.5f + textWidth(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8))))
        && (mouseY > height/3 + (8 * height/25) - textAscent() && mouseY < height/3 + (8 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 8))
      { 
        if (  songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 8) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8)), width/3.5f, height/3 + (8 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8)), width/3.5f, height/3 + (8 * height/25));
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7f, height/3 + (8 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7f, height/3 + (8 * height/25));
      }
    }
    if ( songQueue.size() > 0 )
    { 
      if ( (mouseX > width/4.5f && mouseX < width/4.5f + textWidth("clear")) && (mouseY < height/3 && mouseY > height/3 - textAscent()) )
      {
        fill(175, 175, 175);
        text("clear", width/4.5f, height/3);
      }
      else
      {
        fill(100, 100, 100);
        text("clear", width/4.5f, height/3);
      }
      if ( mouseX > width/4.3f && mouseX < width/4.1f && songQueue.size() > 9)
      {
        if ( mouseY > height/2.82f && mouseY < height/2.75f )
        {
          fill(175, 175, 175);
          triangle(width/4.3f, height/2.75f, width/4.2f, height/2.82f, width/4.1f, height/2.75f);
        }
        else
        {
          fill(100, 100, 100);
          triangle(width/4.3f, height/2.75f, width/4.2f, height/2.82f, width/4.1f, height/2.75f);
        }
        if ( mouseY > height/2.65f && mouseY < height/2.592f )
        {
          fill(175, 175, 175);
          triangle(width/4.3f, height/2.65f, width/4.2f, height/2.592f, width/4.1f, height/2.65f);
        }
        else
        {
          fill(100, 100, 100);
          triangle(width/4.3f, height/2.65f, width/4.2f, height/2.592f, width/4.1f, height/2.65f);
        }
      }
      else if ( songQueue.size() > 9 )
      {
        fill(100, 100, 100);
        triangle(width/4.3f, height/2.75f, width/4.2f, height/2.82f, width/4.1f, height/2.75f);
        triangle(width/4.3f, height/2.65f, width/4.2f, height/2.592f, width/4.1f, height/2.65f);
        fill(175, 175, 175);
      }
    }
  }
}

public void mouseClicked()
{ 
  textFont(font, (width+height)/125);
  if ( (mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5f + textDescent()) )        //Click responses for the general screen.
  {
    if ( (mouseX > width/15) && (mouseX < width/15 + textWidth("Image") ) )  //Select Image.
    {
      if ( imgMode )
      {
        imgMode = false;
        modeOn = false;
        filters.startFilters();
        if ( songPlayer.isPlaying() || audioInputMode )
            bars.startBars();
        tint(170, 50);
      }
      else
      {
        imgMode = true;
        optionMode = false;
        songMode = false;
        queueMode = false;
        modeOn = true;
        filters.pauseFilters();
        bars.pauseBars();
      }
    }
    if ( (mouseX > width/4) && (mouseX < width/4 + textWidth("Song")) )      //Select Song.
    {
      if ( songMode )
      {
        songMode = false;
        modeOn = false;
        tint(170, 50);
        filters.startFilters();
        if ( songPlayer.isPlaying() || audioInputMode ) 
            bars.startBars();
      }
      else
      {
        imgMode = false;
        optionMode = false;
        songMode = true;
        queueMode = false;
        modeOn = true;
        filters.pauseFilters();
        bars.pauseBars();
      }
    }
    if ( (mouseX > width/2.35f) && (mouseX < width/2.35f + textWidth("Display")) )    //Trigger for activating Audio Metadata by clicking the button.
    {
      if ( !displayMeta )
        displayMeta = true;
      else
        displayMeta = false;
    }
    if ( (mouseX > width/1.65f) && (mouseX < width/1.65f + textWidth("Options")) )    //Trigger for activating the OPTIONS screen.
    { 
      if ( !optionMode )
      {
        optionMode = true;
        imgMode = false;
        songMode = false;
        queueMode = false;
        modeOn = true;
        filters.pauseFilters();
        bars.pauseBars();
      }
      else
      {
        optionMode = false;
        modeOn = false;
        tint(170, 50);
        filters.startFilters();
        if ( songPlayer.isPlaying() || audioInputMode )
            bars.startBars();
      }
    }
    if ( (mouseX > width/1.27f) && (mouseX < width/1.27f + textWidth("Queue")) )      //Trigger for activating the QUEUE screen.
    {
      if ( !queueMode )
      {
        queueMode = true;
        imgMode = false;
        songMode = false;
        optionMode = false;
        modeOn = true;
        if ( queueIndex > 9 )
        {
          queueCycle = queueIndex - 9;
        }
        filters.pauseFilters();
        bars.pauseBars();
      }
      else
      {
        queueMode = false;
        modeOn = false;
        tint(170, 50);
        filters.startFilters();
        if ( songPlayer.isPlaying()  || audioInputMode )
            bars.startBars();
      }
    }
    if ( (mouseX > width/1.075f) && (mouseX < width/1.075f + textWidth("---")) )      //Minimizes program if the dash is clicked.
    {
      this.frame.setExtendedState(JFrame.ICONIFIED);
    }
    if ( (mouseX > width/1.035f) && (mouseX < width/1.035f + textWidth("X")) )     //Exits program if the X is clicked.
    {
      exit();
    }
  }

  if ( audioPlayerMode && displayMeta && !modeOn && playerStart )
  { 

    textFont(font, (width+height)/100);
    if ( (mouseX > textAscent() * 8.5f + queueNumWidth && mouseX < textAscent() * 8.5f + queueNumWidth + textWidth("re / shuff"))
      && ( (mouseY > textAscent() * 6.9f && mouseY < textAscent() * 8.9f )) )
    { 
      if ( repeatMode )
      {
        repeatMode = false;
        shuffleMode = true;
      }
      else if ( shuffleMode )
      {
        shuffleMode = false;
      }
      else
      {
        repeatMode = true;
      }
    }
    textFont(font, (width+height)/35);
    if ( (mouseX > width - textAscent() - textWidth(": :  PLAYING")) && (mouseX < width - textAscent()) && songPlayer.isPlaying() )
    {
      if ( (mouseY > height - textAscent() * 4.5f + textDescent() ) && (mouseY < height - textAscent() * 3.5f ) )
      { 
        songPlayer.pause();
        bars.pauseBars();
        isPaused = true;
      }
    }
    else if ( (mouseX > width - textAscent() - textWidth(": :  PAUSED")) && (mouseX < width - textAscent()) )
    {
      if ( (mouseY > height - textAscent() * 4.5f + textDescent() ) && (mouseY < height - textAscent() * 3.5f ) )
      {
        if ( !isPaused )
        { 
          songPlayer.pause();
          songPlayer.play();
          songPlayer.rewind();
        }
        else
        {
          songPlayer.play();
          bars.startBars();
          isPaused = false;
        }
      }
    }

    textFont(font2, (width+height)/100);                //SongQueue system in the flesh. Works out very nicely.
    textAlign(LEFT);
    if ( ((mouseX > textAscent() * 3 + queueNumWidth/2) && (mouseX < textAscent() * 3 + textWidth("<<") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5f) && (mouseY > textAscent() * 6.5f )) )
    { 
      if ( queueIndex - 1 > 0 )
      {
        if ( shuffleMode )
        { 
          songPlayer.close();
          queueIndex = round(random(1, songQueue.size()));
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          if ( queueIndex > 9 )
          {
            queueCycle = queueIndex - 9;
          }
        }
        else
        {
          songPlayer.close();
          queueIndex--;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
        }
        bars.changeSource(songPlayer);
        filters.changeSource(songPlayer, 0);                
        metaData = songPlayer.getMetaData();
        songPlayer.setGain(volume);
        songPlayer.play();
        playerStart = true;
      }
    }
    if ( ((mouseX > textAscent() * 6 + queueNumWidth/2) && (mouseX < textAscent() * 6 + textWidth(">>") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5f) && (mouseY > textAscent() * 6.5f )) )
    {
      if ( queueIndex < songQueue.size() )
      { 
        if ( shuffleMode )
        { 
          songPlayer.close();
          queueIndex = round(random(1, songQueue.size()));
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          if ( queueIndex > 9 )
          {
            queueCycle = queueIndex - 9;
          }
        }
        else
        {
          songPlayer.close();
          queueIndex++;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
        }
        bars.changeSource(songPlayer);
        filters.changeSource(songPlayer, 0);                
        metaData = songPlayer.getMetaData();
        songPlayer.setGain(volume);
        songPlayer.play();
        playerStart = true;
      }
    }
  }

  if ( optionMode )           //Click responses for the configuration screen.
  { 
    cp5.show();
    textFont(font, 10);
    if ( (mouseX > (5 * width)/20) && (mouseX < (5 * width)/20 + textWidth(": :  blur") ) )
    {
      if ( (mouseY > (21 * height)/64) && (mouseY < (22 * height)/64) )
      {
        if ( blurMode )
        {
          blurMode = false;  
          filters.setBlur(false);
        }
        else
        {
          blurMode = true;
          filters.setBlur(true);
        }
      }
    }
    if ( (mouseX > (5 * width)/20) && (mouseX < (5 * width)/20 + textWidth(": :  tint") ) )
    {
      if ( (mouseY > (25 * height)/64) && (mouseY < (26 * height)/64) )
      {
        if ( tintMode )
        {
          tintMode = false;
          filters.setTint(false);
        }
        else
        {
          tintMode = true;
          filters.setTint(true);
        }
      }
    }
    if ( (mouseX > (5 * width)/20) && (mouseX < (5 * width)/20 + textWidth(": :  blink") ) )
    {
      if ( (mouseY > (27 * height)/64) && (mouseY < (28 * height)/64) )
      {
        if ( blinkMode )
        {
          blinkMode = false;
          filters.setBlink(false);
        }
        else
        {
          blinkMode = true;
          filters.setBlink(true);
        }
      }
    }
    if ( (mouseX > (5 * width)/20) && (mouseX < (5 * width)/20 + textWidth(": :  gray tint") ) )
    {
      if ( (mouseY > (23 * height)/64) && (mouseY < (97 * height)/256) )
      {
        if ( greyTintMode )
        {
          greyTintMode = false;
          filters.setGray(false);
        }
        else
        {
          greyTintMode = true;
          filters.setGray(true);
        }
      }
    }
    if ( (mouseX > (5 * width)/20) && (mouseX < (5 * width)/20 + textWidth(": :  dividers") ) )
    {
      if ( (mouseY > (37 * height)/64) && ( mouseY < (38 * height)/64) )
      {
        if ( divideBars )
        {
          divideBars = false;
        }
        else
        {
          divideBars = true;
        }
      }
    }
    if ( (mouseX > (5 * width)/20) && (mouseX < (5 * width)/20 + textWidth(": :  center") ) )
    {
      if ( (mouseY > (41 * height)/64) && ( mouseY < (42 * height)/64) )
      {
        if ( bars.getMode() == bars.CENTER_MODE )
        {
          bars.setMode(bars.STRETCH_MODE);
        }
        else
        {
          bars.setMode(bars.CENTER_MODE);
        }
      }
    }
    if ( (mouseX > (21 * width)/40) && (mouseX < (21 * width)/40 + textWidth(": : always on top")) )
    {
      if ( (mouseY > (41 * height)/64) && ( mouseY < (42 * height)/64) )
      {
        if ( alwaysTop )
        { 
          frame.setAlwaysOnTop(false);
          alwaysTop = false;
        }
        else
        { 
          frame.setAlwaysOnTop(true);
          alwaysTop = true;
        }
      }
    }
  }

  if ( songMode )
  { 
    if ( (mouseX > (5 * width)/20) && (mouseX < (5 * width)/20 + textWidth(": :  recording device / audio input") ) )
    {
      if ( (mouseY > (21 * height)/64) && (mouseY < (22 * height)/64) )
      {
        if ( audioInputMode )
        {
          audioInputMode = false;
          audioPlayerMode = true;
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);
          //Determine if bars needed to be paused upon exiting audio input mode.
          if ( songQueue.isEmpty() )
              bars.pauseBars();
          songPlayer.play();
        }
        else
        {
          audioInputMode = true;
          audioPlayerMode = false;
          bars.changeSource(in);
          filters.changeSource(in, 20);
          songPlayer.pause();
        }
      }
      if ( (mouseY > (23 * height)/64) && (mouseY < (97 * height)/256) )
      {
        if ( audioPlayerMode )
        {
          audioPlayerMode = false;
          audioInputMode = true;
          bars.changeSource(in);
          filters.changeSource(in, 20);
          songPlayer.pause();
        }
        else
        {
          audioPlayerMode = true;
          audioInputMode = false;
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);
          //Determine if bars needed to be paused upon exiting audio input mode.
          if ( songQueue.isEmpty() )
              bars.pauseBars();
          songPlayer.play();
        }
      }
    }
  }  
  else
  {
    barField.setText(""+bars.getNumBars());
    bassField.setText(""+bars.getBassSensitivity());
    midField.setText(""+bars.getMidSensitivity());
    highField.setText(""+bars.getHiSensitivity());
    allField.setText(""+bars.getAllSensitivity());
    resizeWidthField.setText(""+width);
    resizeHeightField.setText(""+height);    
    cp5.hide();
  }

  if ( queueMode )
  {    
    if ( mouseX > width/4.3f && mouseX < width/4.1f )
    {
      if ( mouseY > height/2.82f && mouseY < height/2.75f && queueCycle > 0 )
      {
        queueCycle--;
        fill(255, 255, 255);
        triangle(width/4.3f, height/2.75f, width/4.2f, height/2.82f, width/4.1f, height/2.75f);
      }
      if ( mouseY > height/2.65f && mouseY < height/2.592f && queueCycle + 9 < songQueue.size() )
      {
        queueCycle++;
        fill(255, 255, 255);
        triangle(width/4.3f, height/2.65f, width/4.2f, height/2.592f, width/4.1f, height/2.65f);
      }
    }
    if ( (mouseX > width/4.5f && mouseX < width/4.5f + textWidth("clear")) && (mouseY < height/3 && mouseY > height/3 - textAscent()) )
    {
      fill(255, 255, 255);
      textFont(font2, (width+height)/125);
      text("clear", width/4.5f, height/3);
      songQueue.clear();
      queueIndex = 0;
      queueCycle = 0; 
      queueNumWidth = 0;
    }
    if ( queueCycle < songQueue.size() )
    {
      if ( mouseY > height/3 - textAscent() && mouseY < height/3 )
      {
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle)))
        {
          songPlayer.close();
          queueIndex = queueCycle + 1;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 1 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i, songQueue.get(queueCycle + i + 1));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueCycle + 1 < songQueue.size() )
    {
      if ( mouseY > height/3 + height/25 - textAscent() && mouseY < height/3 + height/25 )
      {
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 1)))
        {
          songPlayer.close();
          queueIndex = queueCycle + 2;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 2 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i + 1, songQueue.get(queueCycle + i + 2));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueCycle + 2 < songQueue.size() )
    {
      if ( mouseY > height/3 + (2 * height/25) - textAscent() && mouseY < height/3 + (2 * height/25 ) )
      { 
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 2)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 3;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 3 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i + 2, songQueue.get(queueCycle + i + 3));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueCycle + 3 < songQueue.size() )
    {
      if ( mouseY > height/3 + (3 * height/25) - textAscent() && mouseY < height/3 + (3 * height/25) )
      { 
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 3)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 4;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 4 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i + 3, songQueue.get(queueCycle + i + 4));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueCycle + 4 < songQueue.size() )
    {
      if ( mouseY > height/3 + (4 * height/25) - textAscent() && mouseY < height/3 + (4 * height/25) ) 
      { 
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 4)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 5;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 5 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i + 4, songQueue.get(queueCycle + i + 5));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueCycle + 5 < songQueue.size() )
    {
      if ( mouseY > height/3 + (5 * height/25) - textAscent() && mouseY < height/3 + (5 * height/25) )
      { 
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 5)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 6;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 6 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i + 5, songQueue.get(queueCycle + i + 6));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueCycle + 6 < songQueue.size() )
    {
      if ( mouseY > height/3 + (6 * height/25) - textAscent() && mouseY < height/3 + (6 * height/25) )
      {
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6)))) 
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 6)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 7;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 7 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i + 6, songQueue.get(queueCycle + i + 7));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueCycle + 7 < songQueue.size() )
    {
      if ( mouseY > height/3 + (7 * height/25) - textAscent() && mouseY < height/3 + (7 * height/25) )
      {
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 7)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 8;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 8 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i + 7, songQueue.get(queueCycle + i + 8));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueCycle + 8 < songQueue.size() )
    {
      if ( mouseY > height/3 + (8 * height/25) - textAscent() && mouseY < height/3 + (8 * height/25) )
      { 
        if ( (mouseX > width/3.5f && mouseX < width/3.5f + textWidth(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 8)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 9;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 0);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
          playerStart = true;
        }
        if ( mouseX > width/3.7f && mouseX < width/3.7f + textWidth("X") )
        {
          for ( int i = 0; i < songQueue.size() - 9 - queueCycle; i++ )
          {
            songQueue.set(queueCycle + i + 8, songQueue.get(queueCycle + i + 9));
          }
          if ( queueIndex > 1 ) { 
            queueIndex = queueIndex - 1;
          }
          songQueue.remove(songQueue.size() - 1);
          songQueue.trimToSize();
        }
      }
    }
    if ( queueIndex > 9 )
    { 
      queueNumWidth = (int) textWidth("0"+queueIndex);
    }
    else
      queueNumWidth = (int) textWidth(""+queueIndex);
  }
}

public void mouseDragged()                                  //Implementing smooth dragging was problematic. Bless the folks who contribute in the processing forums:
{                                                    //Method found here: http://processing.org/discourse/beta/num_1266149435.html. 
  mouse = MouseInfo.getPointerInfo().getLocation();
  if ( dragHelper )
  {
    xloc = mouseX;
    yloc = mouseY;
    dragHelper = false;
  }
  if ( keyPressed && key == CODED )
  {
    if ( keyCode == SHIFT )      //Holding down SHIFT button magnets the frame to the display screen's boundaries. Useful feature.
    {
      if ( (frame.getLocation().getX() <= 0) && (frame.getLocation().getY() <= 0) )
      {
        frame.setLocation(0, 0);
      }
      else if ( (frame.getLocation().getX() <= 0) && (frame.getLocation().getY() + height >= displayHeight) )
      {
        frame.setLocation(0, displayHeight - height);
      }
      else if ( (frame.getLocation().getX() + width >= displayWidth) && (frame.getLocation().getY() <= 0) )
      {
        frame.setLocation(displayWidth - width, 0);
      }
      else if ( (frame.getLocation().getX() + width >= displayWidth) && (frame.getLocation().getY() + height >= displayHeight) )
      {
        frame.setLocation(displayWidth - width, displayHeight - height);
      }
      else if ( frame.getLocation().getX() <= 0 )
      {
        frame.setLocation(0, mouse.y - yloc);
      }
      else if ( frame.getLocation().getX() + width >= displayWidth )
      {
        frame.setLocation(displayWidth - width, mouse.y - yloc);
      }
      else if ( frame.getLocation().getY() <= 0 )
      {
        frame.setLocation(mouse.x - xloc, 0);
      }
      else if ( frame.getLocation().getY() + height >= displayHeight )
      {
        frame.setLocation(mouse.x - xloc, displayHeight - height);
      }
      else
      {
        xPos = mouse.x - xloc;
        yPos = mouse.y - yloc;
        frame.setLocation(xPos, yPos);
      }
    }
  }
  else
  {
    xPos = mouse.x - xloc;
    yPos = mouse.y - yloc;
    frame.setLocation(xPos, yPos);
  }
}

public void mouseReleased()
{
  dragHelper = true;
}

public void controlEvent(ControlEvent theEvent) 
{ 

  if (theEvent.isAssignableFrom(Textfield.class)) 
  { 
    if ( theEvent.getName().equals(barField.getName()) )
    {
      if ( !isInteger(theEvent.getStringValue()) )
      {
        bars.setNumBars(0);
      }
      else
      {
        bars.setNumBars(Integer.parseInt(theEvent.getStringValue()));
      }
    }
  }
  if ( theEvent.getName().equals(bassField.getName()) )
  {
    if ( !isFloat(theEvent.getStringValue()) )
    {
      bars.setBassSensitivity(0);
    }
    else
    {
      bars.setBassSensitivity(parseFloat(theEvent.getStringValue()));
    }
  }
  if ( theEvent.getName().equals(midField.getName()) )
  {
    if ( !isFloat(theEvent.getStringValue()) )
    {
      bars.setMidSensitivity(0);
    }
    else
    {
      bars.setMidSensitivity(parseFloat(theEvent.getStringValue()));
    }
  }
  if ( theEvent.getName().equals(highField.getName()) )
  {
    if ( !isFloat(theEvent.getStringValue()) )
    {
      bars.setHiSensitivity(0);
    }
    else
    {
      bars.setHiSensitivity(parseFloat(theEvent.getStringValue()));
    }
  }
  if ( theEvent.getName().equals(allField.getName()) )
  {
    if ( !isFloat(theEvent.getStringValue()) )
    {
      bars.setAllSensitivity(0);
    }
    else
    {
      bars.setAllSensitivity(parseFloat(theEvent.getStringValue()));
    }
  }
  if ( theEvent.getName().equals(resizeWidthField.getName()) )
  {
    if ( !isInteger(theEvent.getStringValue()) )
    {
      width = width;
    }
    else
    { 
      if ( imgResized )
      {
        imgResized = false;
      }
      if ( changeImg )
      {
        changeImg = false;
      }
      inImage.resize(Integer.parseInt(theEvent.getStringValue()), 0);
      frame.setSize(inImage.width, inImage.height);
      imgResized = true;
      resizeHeightField.setText(""+inImage.height);
      inImage = inImage.get();
      bars.changeImage(inImage);
      filters.changeImage(inImage);
      fixFFTWidth = ceil(width - ((width/barNum) * barNum));
      if (fixFFTWidth < barNum)
        fixFFTWidth = 1;
      else
        fixFFTWidth = ceil(fixFFTWidth/barNum);
    }
  }
  if ( theEvent.getName().equals(resizeHeightField.getName()) )
  {
    if ( !isInteger(theEvent.getStringValue()) )
    {
      height = height;
    }
    else
    { 
      if ( imgResized )
      {
        imgResized = false;
      }
      if ( changeImg )
      {
        changeImg = false;
      }
      inImage.resize(0, Integer.parseInt(theEvent.getStringValue()));
      frame.setSize(inImage.width, inImage.height);
      imgResized = true;
      resizeWidthField.setText(""+inImage.width);
      inImage = inImage.get();
      bars.changeImage(inImage);
      filters.changeImage(inImage);
      fixFFTWidth = ceil(width - ((width/barNum) * barNum));
      if (fixFFTWidth < barNum)
        fixFFTWidth = 1;
      else
        fixFFTWidth = ceil(fixFFTWidth/barNum);
    }
  }
  if ( theEvent.getName().equals(seekField.getName()) )
  {
    if ( !isInteger(removeChar(theEvent.getStringValue())) || (convertToMillis(Integer.parseInt(removeChar(theEvent.getStringValue()))) > songPlayer.length() ) )
    {
      seekField.setValue("n/a");
    }
    else
    {
      songPlayer.cue(convertToMillis(Integer.parseInt(removeChar(theEvent.getStringValue()))));
    }
  }
  if ( theEvent.getName().equals(volField.getName()) )
  {
    if ( !isFloat(theEvent.getStringValue()) )
    {
      volField.setValue(""+volume);
    }
    else
    {
      volume = parseFloat(theEvent.getStringValue());
      songPlayer.setGain(volume);
    }
  }
}

public void keyPressed() 
{
  if (key == ESC) 
  {
    key = 0;
  }
}

public void stop()          //Always stop Minim when the program is finished.
{ 
  songPlayer.close();
  minim.stop();
  super.stop();
}


/**
 *  class: BeatListener
 *  transfers audio buffer information from song/microphone input to 
 *  a BeatDetect object
*/

class BeatListener implements AudioListener {
  
    private BeatDetect beat;
    private AudioSource source;
 
    BeatListener(BeatDetect beat, AudioSource source) {
        this.source = source;
        this.source.addListener(this);
        this.beat = beat;
    }
    
    public void samples(float[] samps) {
        beat.detect(source.mix);
    }
 
    public void samples(float[] sampsL, float[] sampsR) {
        beat.detect(source.mix);
    }    
}


/**
 *  class: FilterHandler
 *  draws all the filters associated with the visualizer.
 *  filters: Blink, Tint, Grey Tint, and Blur.
*/


class FilterHandler {
  
    private BeatDetect musicBeat;
    private BeatListener musicBeatListener;
    private PImage srcImg;
    private PImage blurImg;
    private boolean blinkMode;
    private boolean tintMode;
    private boolean grayMode;
    private boolean blurMode;
    private boolean display;
  
    public FilterHandler(AudioSource source, PImage img) {
        musicBeat = new BeatDetect(source.bufferSize(), source.sampleRate());
        musicBeatListener = new BeatListener(musicBeat, source);
        srcImg = img;
        blurImg = srcImg.get();
        blurImg.filter(BLUR, 6);
        tintMode = true;
        blinkMode = true;
        grayMode = false;
        blurMode = false;
        display = true;
    }
    
    public void changeSource(AudioSource source, int sensitivity) {
        musicBeat = new BeatDetect(source.bufferSize(), source.sampleRate());
        musicBeatListener = new BeatListener(musicBeat, source);
        musicBeat.setSensitivity(sensitivity);
    }
    
    public void changeImage(PImage srcImg) {
        //Current memory leak with processing's PImage class; attempt to lessen effect.
        g.removeCache(srcImg);
        g.removeCache(blurImg);
        this.srcImg = srcImg;
        blurImg = srcImg.get();
        blurImg.filter(BLUR, 6);
    }
    
    public void applyFilters() {
      if ( display ) {
          if ( tintMode )
              tintFilter();
          if ( blurMode )
              blurFilter();
          if ( grayMode )
              grayFilter();
      }
    }
    
    public void pauseFilters() {
        display = false;
    }
    
    public void startFilters() {
        display = true;
    }
    
    public void setTint(boolean mode) {
        tintMode = mode;
    }
    
    public boolean checkTint() {
        return tintMode;
    }
    
    public void setBlink(boolean mode) {
        blinkMode = mode;
    }
    
    public boolean checkBlink() {
        return blinkMode;
    }
    
    public void setGray(boolean mode) {
        grayMode = mode;
    }
    
    public boolean checkGray() {
        return grayMode;
    }
    
    public void setBlur(boolean mode) {
        blurMode = mode;
    }
    
    public boolean checkBlur() {
        return blurMode;
    }
  
    private void tintFilter() {
        if ( musicBeat.isKick() && blinkMode ) {
            tint(135, 45);
        }
        else
            tint(105, 60);
    }
  
    private void grayFilter() {
        filter(GRAY);
    }
  
    private void blurFilter() {
        if ( musicBeat.isKick() ) 
            image(blurImg, 0, 0);
    }

}

/**
 *  class: MusicBar
 *  draws all visualization bars in visualizer using FFT data from
 *  an AudioSource
*/


class MusicBars {
  
  private PImage srcImg;
  private PFont font;
  private int fontSize;
  private AudioSource source;
  private FFT audioData;
  private boolean debugMode;
  private boolean display;
  private int[] amps;
  private int[] debug;
  private int[] debugFrame;
  private int debugFrameCount;
  private double debugDec;
  public static final int STRETCH_MODE = 0;
  public static final int CENTER_MODE = 1;
  private int mode;
  private float bass;
  private float mid;
  private float hi;
  private float all;
  
  public MusicBars(AudioSource source, PImage img, PFont font) {
      this.source = source;
      this.font = font;
      srcImg = img;
      audioData = new FFT(source.bufferSize(), source.sampleRate());
      audioData.window(FFT.HAMMING);
      mode = STRETCH_MODE;
      debugMode = true;
      display = true;
      amps = new int[9];
      debug = new int[amps.length];
      debugFrame = new int[amps.length];
      debugFrameCount = 0;
      debugDec = 1;
      bass = 0.005f;
      mid = 0.020f;
      hi = 0.060f;
      all = 1.000f;
      fontSize = getScaledFontSize();
  }
  
  
  private int getScaledFontSize() {
      int tempSize = 20;
      textFont(font, tempSize);
      while ( textWidth("0000 - 0000 Hz") > width/amps.length - width/200 || tempSize > 9 ) {
          tempSize--;
          textFont(font, tempSize);
      }
      return tempSize;
  }
  
  
  public void changeSource(AudioSource source) {
    this.source = source;
    audioData = new FFT(source.bufferSize(), source.sampleRate());
    audioData.window(FFT.HAMMING);
  }
  
  public void changeImage(PImage img) {
      //Current memory leak with Processing's PImage class; attempt to lessen effect.
      g.removeCache(srcImg);
      srcImg = img;
      fontSize = getScaledFontSize();
  }
  
  public void startBars() {
      display = true;
  }
  
  public void pauseBars() {
      display = false;
  }
   
  public int getNumBars() {
      return amps.length;
  }
  
  public void setNumBars(int numBars) {
      amps = new int[numBars];
      debug = new int[amps.length];
      debugFrame = new int[amps.length];
      fontSize = getScaledFontSize();
  }
  
  public int getMode() {
      return mode;
  }
  
  public void setMode(int mode) {
      this.mode = mode;
  }
  
  public float getAllSensitivity() {
      return all;
  }
  
  public void setAllSensitivity(float all) {
      this.all = all;
  }
  
  public float getBassSensitivity() {
      return bass;
  }
  
  public void setBassSensitivity(float bass) {
      this.bass = bass;
  }
  
  public float getMidSensitivity() {
      return mid;
  }
  
  public void setMidSensitivity(float mid) {
      this.mid = mid;
  }
  
  public float getHiSensitivity() {
      return hi;
  }
  
  public void setHiSensitivity(float hi) {
      this.hi = hi;
  }
       
  public void drawBars() {
      if ( display )
          if ( mode == STRETCH_MODE )
              drawStretchBars();
          else if ( mode == CENTER_MODE )
              drawCenterBars();
  }
  
  private void drawStretchBars() {
      audioData.forward(source.mix);
      int barWidth = width/amps.length - width/200;
      if ( debugMode ) {
          textFont(font, fontSize);
          textAlign(LEFT); 
      }
      for ( int i = 0; i < amps.length; i++ ) {
          //divider keeps all 3 ranges in their respective frequencies.
          int divider = i % (amps.length / 3);
          //BASS Range: 0Hz - 300Hz
          if ( i < amps.length/3 ) { 
              amps[i] = (int) (all * bass * height * audioData.calcAvg((900/amps.length)*divider, (900/amps.length)*(divider+1)));
              if ( debugMode )
                  text(""+((900/amps.length)*divider)+"- "+((900/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
          }
          //MID Range: 300Hz - 1200Hz          
          else if ( i >= amps.length/3 && i < (2 * amps.length)/3 ) {
              amps[i] = (int) (all * mid * height * audioData.calcAvg(300+(2700/amps.length)*divider, 300+(2700/amps.length)*(divider+1)));
              if ( debugMode )
                  text(""+(300+(2700/amps.length)*divider)+"- "+(300+(2700/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
          }
          //HI Range: 1200Hz - 6000Hz
          else {
              amps[i] = (int) (all * hi * height * audioData.calcAvg(1200+(15000/amps.length)*divider, 1200+(15000/amps.length)*(divider+1)));
              if ( debugMode )
                  text(""+(1200+(15000/amps.length)*divider)+"- "+(1200+(15000/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
          }
          
          if ( amps[i] > height )
              amps[i] = height;
              
          /*
          //Draw the extended debug text.
          if ( debugMode ) {
              if ( amps[i] > debug[i] ) {
                  debug[i] = amps[i];   
                  debugFrame[i] = frameCount;
                  debugDec = 2;
              }
              if ( frameCount - debugFrame[i] > 5 ) {
                  if ( debugDec < height/25 )
                      debugDec += debugDec;
                  debug[i] -= debugDec;
              }
              //Draw the line.
              stroke(215, 215, 215);
              noTint();
              line((width/amps.length+1) * i, height - debug[i], (width/amps.length+1) * i + barWidth - 1, height - debug[i]);
              tint(90, 60);
              noStroke();
          }
          */
          //Draw the bars.
          copy(srcImg, (width/amps.length+1) * i, height, barWidth, -amps[i], (width/amps.length+1) * i, height, barWidth, -amps[i]);
      }
  }
  
  private void drawCenterBars() {
      audioData.forward(source.mix);
      int barWidth = (3*width)/(5*amps.length) - width/200;
      for ( int i = 0; i < amps.length; i++ ) {
          //divider keeps all 3 ranges in their respective frequencies.
          int divider = i % (amps.length / 3);
          //BASS Range: 0Hz - 300Hz
          if ( i < amps.length/3 ) 
              amps[i] = (int) (.6f * all * bass * height * audioData.calcAvg((900/amps.length)*divider, (900/amps.length)*(divider+1)));
          //MID Range: 300Hz - 1200Hz          
          else if ( i >= amps.length/3 && i < (2 * amps.length)/3 ) 
              amps[i] = (int) (.6f * all * mid * height * audioData.calcAvg(300+(2700/amps.length)*divider, 300+(2700/amps.length)*(divider+1)));
          //HI Range: 1200Hz - 6000Hz
          else 
              amps[i] = (int) (.6f * all * hi * height * audioData.calcAvg(1200+(15000/amps.length)*divider, 1200+(15000/amps.length)*(divider+1)));
          if ( amps[i] > height * .6f )
              amps[i] = (int) (height * .6f);
          copy(srcImg, width/5+((3*width)/(5*amps.length)+1)*i, height * 4/5, barWidth, -amps[i], width/5+((3*width)/(5*amps.length)+1)*i, height * 4/5, barWidth, -amps[i]);
      }
  }
       
    
}

/**
 *  class: TextButton
 *  basic GUI element that creates interactive text with 
 *  basic functionalities such as being clicked on or highlighted.
*/


class TextButton {
  
  private PFont font;
  private int size;
  private String text;
  
  public TextButton(PFont font, int size, String text) {
    this.font = font;
    this.size = size;
    this.text = text;
  }
  
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "pictualizer" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
