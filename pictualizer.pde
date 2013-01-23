import ddf.minim.*;
import ddf.minim.analysis.*;
import java.awt.MouseInfo;        //MouseInfo and Point are the classes imported in order to implement smooth window dragging. Doing it with frame.getX() and Y with mouseX and mouseY
import java.awt.Point;            //causes some weird feedback loop that causes the image to shake violently instead of smoothly dragging. Found here: https://forum.processing.org/topic/global-mouse.
import javax.swing.*;             //Swing GUI from java imported ONLY to help minimize the program. 
import java.lang.*;               //Lang lib used for verifying file input from the drag and drop.
import java.io.File;
import controlP5.*;               //ControlP5 GUI Library from Processing's site used for creating text input boxes in Config screen.
import sojamo.drop.*;             //SDrop lib used to incorporate drag and drop file input. Very handy.


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
boolean isInteger(String str) 
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

boolean isFloat(String str)
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
String truncatePath(String str)
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

String removeChar(String str)
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

int convertToMillis(int minutesSeconds)
{
  int seconds = minutesSeconds % 100;
  int minutes = minutesSeconds / 100;
  return (minutes*60000) + (seconds*1000);
}

int millisToSeconds(int milliseconds)
{
  return (milliseconds/1000)%60;
}

int millisToMinutes(int milliseconds)
{
  return milliseconds/60000;
}


//HELPFUL ADVICE:
//As an example, if you construct a FourierTransform with a timeSize of 1024 and and a sampleRate of 44100 Hz, 
//then the spectrum will contain values for frequencies below 22010 Hz, which is the Nyquist frequency (half the sample rate). 
//If you ask for the value of band number 5, this will correspond to a frequency band centered on 5/1024 * 44100 = 0.0048828125 * 44100 = 215 Hz.

void init()
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


void setup()
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


  bassSensitivity = .0075;        
  midSensitivity = .02;
  highSensitivity = .06;
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
    .setPosition(textAscent() * 11, textAscent() * 5.1)
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
    .setPosition(textAscent() * 12.2, textAscent() * 6.1)
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

void dropEvent(DropEvent theDropEvent) 
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

void draw()                //My goal is to divide the total frequency spectrum into X bars for visualization. Thus, each bar spans a range of 22050Hz/X.
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

void checkPlayerStatus()
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

void displayGUI()
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
    seekField.setPosition(textAscent() * 11 + queueNumWidth, textAscent() * 5.1)
      .setSize((int) textWidth("00:00"), (int) textAscent())
        .setFont(font2);
    volField.setPosition(textAscent() * 12.2 + queueNumWidth, textAscent() * 6.1)
      .setSize((int) textAscent()*5, (int) textAscent())
        .setFont(font2);
  }

  textFont(font, (width + height)/125);
  if ( mouseY < textAscent() * 2.5)                        //Reveals the task bar on top of the program.
  {                                                 //Triggered by movement of the mouse into the top of the program.
    textFont(font, (width + height)/125);
    textAlign(LEFT);
    fill(50, 50, 50, 50);
    rect(0, 0, width, textAscent() * 2.5);
    fill(225, 225, 225, alphaVal);
    text("Image", width/15, textAscent() * 1.5);
    text("Song", width/4, textAscent() * 1.5);
    text("Display", width/2.35, textAscent() * 1.5);
    text("Options", width/1.65, textAscent() * 1.5);
    text("Queue", width/1.27, textAscent() * 1.5);
    text("---", width/1.075, textAscent() * 1.5);
    text("X", width/1.035, textAscent() * 1.5);
    if ( alphaVal < 255 )
    {
      alphaVal = alphaVal + 15;
    }  
    if ( ((mouseX > width/15) && (mouseX < width/15 + textWidth("Image"))) 
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5 + textDescent())) )     //Highlights "Image" when it is selected.
    { 
      fill(255, 255, 255);
      text("Image", width/15, textAscent() * 1.5);
    }
    if ( ((mouseX > width/4) && (mouseX < width/4 + textWidth("Song")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5 + textDescent())) )     //Highlights "Song" when it is selected.
    {
      fill(255, 255, 255);
      text("Song", width/4, textAscent() * 1.5);
    }
    if ( ((mouseX > width/2.35) && (mouseX < width/2.35 + textWidth("Display")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5 + textDescent())) )     //Highlights "Display" when it is selected.
    {
      fill(255, 255, 255);
      text("Display", width/2.35, textAscent() * 1.5);
    }
    if ( ((mouseX > width/1.65) && (mouseX < width/1.65 + textWidth("Options")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5 + textDescent())) )     //Highlights "Option" when it is selected.
    { 
      fill(255, 255, 255);
      text("Options", width/1.65, textAscent() * 1.5);
    }
    if ( ((mouseX > width/1.27) && (mouseX < width/1.27 + textWidth("Queue")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5 + textDescent())) )     //Highlights "Queue" when it is selected.
    { 
      fill(255, 255, 255);
      text("Queue", width/1.27, textAscent() * 1.5);
    }
    if ( ((mouseX > width/1.075) && (mouseX < width/1.075 + textWidth("---")))
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5 + textDescent())) )     //Highlights "---" when it is selected.
    {
      fill(255, 255, 255);
      text("---", width/1.075, textAscent() * 1.5);
    }
    if ( ((mouseX > width/1.035) && (mouseX < width/1.035 + textWidth("X")))   
      && ((mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5 + textDescent())) )     //Highlights "X" when it is selected.
    {
      fill(255, 255, 255);
      text("X", width/1.035, textAscent() * 1.5);
    }
  }
  if ( mouseY > textAscent() * 2.5 )                      //Fades the task bar on the top of the program.
  {                                              //Triggered by removal of the mouse from the top of the program.
    alphaVal = 0;
  }


  if ( audioPlayerMode && playerStart && displayMeta && !modeOn )
  {
    textFont(font2, (width+height)/100);
    textAlign(LEFT);
    if ( ((mouseX > textAscent() * 3) && (mouseX < textAscent() * 6 + textWidth(">>") + queueNumWidth)) && ((mouseY > textAscent() * 2) && (mouseY < textAscent() * 7.5)) )
    {
      fill(255, 255, 255, 50);
      text("<<", textAscent() * 3 + queueNumWidth/2, textAscent() * 7.5);
      text(">>", textAscent() * 6 + queueNumWidth/2, textAscent() * 7.5);
      if ( ((mouseX > textAscent() * 3 + queueNumWidth/2) && (mouseX < textAscent() * 3 + textWidth("<<") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5) && (mouseY > textAscent() * 6.5 )) )
      {
        fill(255, 255, 255);
        text("<<", textAscent() * 3 + queueNumWidth/2, textAscent() * 7.5);
      }
      if ( ((mouseX > textAscent() * 6 + queueNumWidth/2) && (mouseX < textAscent() * 6 + textWidth(">>") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5) && (mouseY > textAscent() * 6.5 )) )
      {
        fill(255, 255, 255);
        text(">>", textAscent() * 6 + queueNumWidth/2, textAscent() * 7.5);
      }
    }
    if ( ((mouseX > textAscent() * 8.5 + queueNumWidth) && (mouseX < textAscent() * 8.5 + textWidth(truncatePath(metaData.fileName())+" ("
      +millisToMinutes(songPlayer.length())+":0"+millisToSeconds(songPlayer.length())+")")+ queueNumWidth)) 
      && ( (mouseY < textAscent() * 8.5) && (mouseY > textAscent() * 2.8 )) )  
    { 
      fill(175, 175, 175);
      text("volume:", textAscent() * 8.5 + queueNumWidth, textAscent() * 6.9);
      volField.show();  
      if ( repeatMode )
      { 
        fill(255, 255, 255);
        text("re /", textAscent() * 8.5 + queueNumWidth, textAscent() * 7.9);
        fill(175, 175, 175);
        text(" shuff", textAscent() * 8.5 + textWidth("re /") + queueNumWidth, textAscent() * 7.9);
      }
      else if ( shuffleMode )
      {
        fill(175, 175, 175);
        text("re ", textAscent() * 8.5 + queueNumWidth, textAscent() * 7.9);
        fill(255, 255, 255);
        text("/ shuff", textAscent() * 8.5 + textWidth("re ") + queueNumWidth, textAscent() * 7.9);
      }
      else
      {
        fill(175, 175, 175);
        text("re / shuff", textAscent() * 8.5 + queueNumWidth, textAscent() * 7.9);
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
      text(": :  PLAYING", width - textAscent(), height - textAscent() * 3.5);
    }
    else if ( playerStart && audioPlayerMode )
    {
      text(": :  PAUSED", width - textAscent(), height - textAscent() * 3.5);
    }

    if ( playerStart && audioPlayerMode )
    { 
      seeker.show();
      textFont(font, (height + width)/25);
      textAlign(LEFT);
      if ( queueIndex < 10 )
      {
        text("0"+queueIndex, textAscent() - textDescent(), textAscent() * 1.5);
      }
      else
      {
        text(""+queueIndex, textAscent() - textDescent(), textAscent() * 1.5);
        queueNumWidth = (int) textWidth(""+queueIndex) - (int) textWidth("0"+queueIndex%10);
      }
      textFont(font2, (height + width)/100);
      if ( millisToSeconds(songPlayer.length()) < 10 )
      {
        text(""+truncatePath(metaData.fileName())+" ("+millisToMinutes(songPlayer.length())+":0"+millisToSeconds(songPlayer.length())+")", textAscent() * 8.5 + queueNumWidth, textAscent() * 3.8);
      }
      else
      {
        text(""+truncatePath(metaData.fileName())+" ("+millisToMinutes(songPlayer.length())+":"+millisToSeconds(songPlayer.length())+")", textAscent() * 8.5 + queueNumWidth, textAscent() * 3.8);
      }
      if ( metaData.author().equals("") )
      {
        text("unknown", textAscent() * 8.5 + queueNumWidth, textAscent() * 4.9);
      }
      else
      {
        text(""+metaData.author()+"", textAscent() * 8.5 + queueNumWidth, textAscent() * 4.9);
      }
      textFont(font2, (width + height)/100);
      text("seek:", textAscent() * 8.5 + queueNumWidth, textAscent() * 5.9);
      seekField.setPosition(textAscent() * 11 + queueNumWidth, textAscent() * 5.1);
      volField.setPosition(textAscent() * 12.2 + queueNumWidth, textAscent() * 6.1);
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
      bassField.setColor(#FFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  bass", (21 * width)/40, (11 * height)/32);
      bassField.setColor(#969696);
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
      midField.setColor(#FFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  low", (21 * width)/40, (12 * height)/32);
      lowField.setColor(#969696);
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
      highField.setColor(#FFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  mid", (21 * width)/40, (13 * height)/32);
      midField.setColor(#969696);
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
      allField.setColor(#FFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  high", (21 * width)/40, (14 * height)/32);
      highField.setColor(#969696);
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
      barField.setColor(#FFFFFF);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  bars", (5 * width)/20, (20 * height)/32);
      barField.setColor(#969696);
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
      text(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle)), width/3.5, height/3);
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle))))
        && (mouseY > height/3 - textAscent() && mouseY < height/3 ) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle)), width/3.5, height/3);
        }
        else
        { 
          fill(175, 175, 175);
          text(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle)), width/3.5, height/3);
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3);
          fill(100, 100, 100);
        }
        else
        {
          fill(100, 100, 100);
          text("X", width/3.7, height/3);
        }
      }
    }
    if ( queueCycle + 1 < songQueue.size() )
    {
      text(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1)), width/3.5, height/3 + height/25);
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1))))
        && (mouseY > height/3 + height/25 - textAscent() && mouseY < height/3 + height/25 ) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 1))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 1) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1)), width/3.5, height/3 + height/25);
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1)), width/3.5, height/3 + height/25);
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3 + height/25);
        }
        fill(100, 100, 100);
        text("X", width/3.7, height/3 + height/25);
      }
    }
    if ( queueCycle + 2 < songQueue.size() )
    {
      text(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2)), width/3.5, height/3 + (2 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2))))
        && (mouseY > height/3 + (2 * height/25) - textAscent() && mouseY < height/3 + (2 * height/25 )) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 2))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 2) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2)), width/3.5, height/3 + (2 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2)), width/3.5, height/3 + (2 * height/25));
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3 + (2 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7, height/3 + (2 * height/25));
      }
    }
    if ( queueCycle + 3 < songQueue.size() )
    {
      text(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3)), width/3.5, height/3 + (3 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3))))
        && (mouseY > height/3 + (3 * height/25) - textAscent() && mouseY < height/3 + (3 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 3))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 3) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3)), width/3.5, height/3 + (3 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3)), width/3.5, height/3 + (3 * height/25));
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3 + (3 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7, height/3 + (3 * height/25));
      }
    }
    if ( queueCycle + 4 < songQueue.size() )
    {
      text(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4)), width/3.5, height/3 + (4 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4))))
        && (mouseY > height/3 + (4 * height/25) - textAscent() && mouseY < height/3 + (4 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 4))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 4) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4)), width/3.5, height/3 + (4 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4)), width/3.5, height/3 + (4 * height/25));
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3 + (4 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7, height/3 + (4 * height/25));
      }
    }
    if ( queueCycle + 5 < songQueue.size() )
    {
      text(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5)), width/3.5, height/3 + (5 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5))))
        && (mouseY > height/3 + (5 * height/25) - textAscent() && mouseY < height/3 + (5 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 5))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 5) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5)), width/3.5, height/3 + (5 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5)), width/3.5, height/3 + (5 * height/25));
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3 + (5 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7, height/3 + (5 * height/25));
      }
    }
    if ( queueCycle + 6 < songQueue.size() )
    {
      text(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6)), width/3.5, height/3 + (6 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6))))
        && (mouseY > height/3 + (6 * height/25) - textAscent() && mouseY < height/3 + (6 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 6))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 6) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6)), width/3.5, height/3 + (6 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6)), width/3.5, height/3 + (6 * height/25));
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3 + (6 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7, height/3 + (6 * height/25));
      }
    }
    if ( queueCycle + 7 < songQueue.size() )
    {
      text(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7)), width/3.5, height/3 + (7 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7))))
        && (mouseY > height/3 + (7 * height/25) - textAscent() && mouseY < height/3 + (7 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 7))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 7) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7)), width/3.5, height/3 + (7 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7)), width/3.5, height/3 + (7 * height/25));
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3 + (7 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7, height/3 + (7 * height/25));
      }
    }
    if ( queueCycle + 8 < songQueue.size() )
    {
      text(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8)), width/3.5, height/3 + (8 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8))))
        && (mouseY > height/3 + (8 * height/25) - textAscent() && mouseY < height/3 + (8 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 8))
      { 
        if (  songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 8) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8)), width/3.5, height/3 + (8 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8)), width/3.5, height/3 + (8 * height/25));
        }
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
        {
          fill(175, 175, 175);
          text("X", width/3.7, height/3 + (8 * height/25));
        }
        fill(100, 100, 100);
        text("X", width/3.7, height/3 + (8 * height/25));
      }
    }
    if ( songQueue.size() > 0 )
    { 
      if ( (mouseX > width/4.5 && mouseX < width/4.5 + textWidth("clear")) && (mouseY < height/3 && mouseY > height/3 - textAscent()) )
      {
        fill(175, 175, 175);
        text("clear", width/4.5, height/3);
      }
      else
      {
        fill(100, 100, 100);
        text("clear", width/4.5, height/3);
      }
      if ( mouseX > width/4.3 && mouseX < width/4.1 && songQueue.size() > 9)
      {
        if ( mouseY > height/2.82 && mouseY < height/2.75 )
        {
          fill(175, 175, 175);
          triangle(width/4.3, height/2.75, width/4.2, height/2.82, width/4.1, height/2.75);
        }
        else
        {
          fill(100, 100, 100);
          triangle(width/4.3, height/2.75, width/4.2, height/2.82, width/4.1, height/2.75);
        }
        if ( mouseY > height/2.65 && mouseY < height/2.592 )
        {
          fill(175, 175, 175);
          triangle(width/4.3, height/2.65, width/4.2, height/2.592, width/4.1, height/2.65);
        }
        else
        {
          fill(100, 100, 100);
          triangle(width/4.3, height/2.65, width/4.2, height/2.592, width/4.1, height/2.65);
        }
      }
      else if ( songQueue.size() > 9 )
      {
        fill(100, 100, 100);
        triangle(width/4.3, height/2.75, width/4.2, height/2.82, width/4.1, height/2.75);
        triangle(width/4.3, height/2.65, width/4.2, height/2.592, width/4.1, height/2.65);
        fill(175, 175, 175);
      }
    }
  }
}

void mouseClicked()
{ 
  textFont(font, (width+height)/125);
  if ( (mouseY > textAscent() - textDescent() * 2) && (mouseY < textAscent() * 1.5 + textDescent()) )        //Click responses for the general screen.
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
    if ( (mouseX > width/2.35) && (mouseX < width/2.35 + textWidth("Display")) )    //Trigger for activating Audio Metadata by clicking the button.
    {
      if ( !displayMeta )
        displayMeta = true;
      else
        displayMeta = false;
    }
    if ( (mouseX > width/1.65) && (mouseX < width/1.65 + textWidth("Options")) )    //Trigger for activating the OPTIONS screen.
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
    if ( (mouseX > width/1.27) && (mouseX < width/1.27 + textWidth("Queue")) )      //Trigger for activating the QUEUE screen.
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
    if ( (mouseX > width/1.075) && (mouseX < width/1.075 + textWidth("---")) )      //Minimizes program if the dash is clicked.
    {
      this.frame.setExtendedState(JFrame.ICONIFIED);
    }
    if ( (mouseX > width/1.035) && (mouseX < width/1.035 + textWidth("X")) )     //Exits program if the X is clicked.
    {
      exit();
    }
  }

  if ( audioPlayerMode && displayMeta && !modeOn && playerStart )
  { 

    textFont(font, (width+height)/100);
    if ( (mouseX > textAscent() * 8.5 + queueNumWidth && mouseX < textAscent() * 8.5 + queueNumWidth + textWidth("re / shuff"))
      && ( (mouseY > textAscent() * 6.9 && mouseY < textAscent() * 8.9 )) )
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
      if ( (mouseY > height - textAscent() * 4.5 + textDescent() ) && (mouseY < height - textAscent() * 3.5 ) )
      { 
        songPlayer.pause();
        bars.pauseBars();
        isPaused = true;
      }
    }
    else if ( (mouseX > width - textAscent() - textWidth(": :  PAUSED")) && (mouseX < width - textAscent()) )
    {
      if ( (mouseY > height - textAscent() * 4.5 + textDescent() ) && (mouseY < height - textAscent() * 3.5 ) )
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
    if ( ((mouseX > textAscent() * 3 + queueNumWidth/2) && (mouseX < textAscent() * 3 + textWidth("<<") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5) && (mouseY > textAscent() * 6.5 )) )
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
    if ( ((mouseX > textAscent() * 6 + queueNumWidth/2) && (mouseX < textAscent() * 6 + textWidth(">>") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5) && (mouseY > textAscent() * 6.5 )) )
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
    if ( mouseX > width/4.3 && mouseX < width/4.1 )
    {
      if ( mouseY > height/2.82 && mouseY < height/2.75 && queueCycle > 0 )
      {
        queueCycle--;
        fill(255, 255, 255);
        triangle(width/4.3, height/2.75, width/4.2, height/2.82, width/4.1, height/2.75);
      }
      if ( mouseY > height/2.65 && mouseY < height/2.592 && queueCycle + 9 < songQueue.size() )
      {
        queueCycle++;
        fill(255, 255, 255);
        triangle(width/4.3, height/2.65, width/4.2, height/2.592, width/4.1, height/2.65);
      }
    }
    if ( (mouseX > width/4.5 && mouseX < width/4.5 + textWidth("clear")) && (mouseY < height/3 && mouseY > height/3 - textAscent()) )
    {
      fill(255, 255, 255);
      textFont(font2, (width+height)/125);
      text("clear", width/4.5, height/3);
      songQueue.clear();
      queueIndex = 0;
      queueCycle = 0; 
      queueNumWidth = 0;
    }
    if ( queueCycle < songQueue.size() )
    {
      if ( mouseY > height/3 - textAscent() && mouseY < height/3 )
      {
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 1)+"  "+truncatePath((String)songQueue.get(queueCycle))))
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 2)+"  "+truncatePath((String)songQueue.get(queueCycle + 1))))
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 3)+"  "+truncatePath((String)songQueue.get(queueCycle + 2))))
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 4)+"  "+truncatePath((String)songQueue.get(queueCycle + 3))))
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 5)+"  "+truncatePath((String)songQueue.get(queueCycle + 4))))
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 6)+"  "+truncatePath((String)songQueue.get(queueCycle + 5))))
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 7)+"  "+truncatePath((String)songQueue.get(queueCycle + 6)))) 
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 8)+"  "+truncatePath((String)songQueue.get(queueCycle + 7))))
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 9)+"  "+truncatePath((String)songQueue.get(queueCycle + 8))))
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
        if ( mouseX > width/3.7 && mouseX < width/3.7 + textWidth("X") )
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

void mouseDragged()                                  //Implementing smooth dragging was problematic. Bless the folks who contribute in the processing forums:
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

void mouseReleased()
{
  dragHelper = true;
}

void controlEvent(ControlEvent theEvent) 
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

void keyPressed() 
{
  if (key == ESC) 
  {
    key = 0;
  }
}

void stop()          //Always stop Minim when the program is finished.
{ 
  songPlayer.close();
  minim.stop();
  super.stop();
}

