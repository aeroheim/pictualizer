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
 * USE CIRCULAR SEEK AROUND QUEUE INDEX INSTEAD OF SEEK BAR
 * REPLACE SEEK BAR WITH PLAY << AND PAUSE <<
 * ALLOW DRAGGING OF TIME AND SONG ELEMENTS
 */

//Textfield throws ArrayIndexOutOfBounds because text length exceeds text field length; perhaps try changing the text field length as well every time a resize occurs?
//Memory errors: possible fix is to use removeCache(img)



//Reading and processing input songs.
Minim minim;
AudioInput in;
AudioPlayer songPlayer;
AudioMetaData metaData;
float volume = -15;

/* Control states for audio */
int audioMode;
int playerMode;
boolean playerPaused;

//Queue system/handler for multiple songs.
ArrayList songQueue;
int queueIndex;
int queueCycle;
int queueNumWidth = 0;

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
PImage img;
PImage filterImage;
boolean imgResized = false;

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

/* Control state & positioning elements for GUI */
int menuState;
boolean displayAudioMetaData;
float[] accessBarTextXPositions;
String[] accessBarTexts;
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


  //Add parameter to specify how much of a string is needed to be truncated. I need this so that I can have the proper length for the displayAudioMetaDataData
  //and QUEUE menu.
  //Truncates a String based on its width to given specifications.
  String truncPath(String str)
  {
    StringBuffer helper = new StringBuffer();
    helper.append(str);   
    //Obtain the name of the file name before the extension, marked by "."
    String fileName = str.substring(helper.lastIndexOf("\\") + 1, helper.lastIndexOf("."));   
    //Clear the StringBuffer so that it may be reused later on.
    helper.delete(0, helper.length());   
    if ( ((3 * width)/20 + textWidth(fileName)) > (15 * width)/20 )
    {  
      //Continuously cut off the last char until the String meets specified dimensions.
      while ( ( (3 * width)/20 + textWidth(fileName)) > (15 * width)/20 )
      {
        fileName = fileName.substring(0, fileName.length() - 1);
      }
      helper.append(fileName);
      //Add "..." to indicate that the file path was concatenated.
      helper.replace(helper.length() - 2, helper.length(), "...");
      fileName = helper.toString();
    }
    return fileName;
  }

  //Automatically resize a large image to fit the current screen's dimensions.
  void resizeToScreen(PImage img)
  {
    if ( ( img.width > displayWidth ) || ( img.height > displayHeight ) )
      if ( img.width > img.height )
      {
        img.resize(displayWidth, 0);
        if ( img.height > displayHeight )
          img.resize(0, displayHeight);
      }
      else
        img.resize(0, displayHeight);
  }
  
  //Changes the pictualizer picture.
  void changeImg(PImage img)
  {
    resizeToScreen(img);
    frame.setSize(img.width, img.height);
    /*
    while( pixels.length != img.pixels.length )
        frame.setSize(img.width, img.height);
    */
    filters.pauseFilters();
    filters.changeImage(img);
    bars.pauseBars();
    bars.changeImage(img);
    accessBarTextXPositions = setAccessBarTextPosition(img.width, img.height);
  }
  
  //Calls all necessary commands to load a new song into the pictualizer.
  void loadSong(String songPath)
  {
     songPlayer.close();
     minim.stop();
     minim = new Minim(this);
     songPlayer = minim.loadFile(songPath);
     bars.changeSource(songPlayer);
     filters.changeSource(songPlayer, 15);
     metaData = songPlayer.getMetaData();
     songPlayer.setGain(volume);
     songPlayer.play();
     bars.startBars();
  }

//HELPFUL ADVICE:
//As an example, if you construct a FourierTransform with a timeSize of 1024 and and a sampleRate of 44100 Hz, 
//then the spectrum will contain values for frequencies below 22010 Hz, which is the Nyquist frequency (half the sample rate). 
//If you ask for the value of band number 5, this will correspond to a frequency band centered on 5/1024 * 44100 = 0.0048828125 * 44100 = 215 Hz.


    /* 
     * setAccessBarTextPosition determines the X coordinates that will be used to display the text from the access bar.
     * The coordinates are stored in the global array accessBarTextXPositions[].
     * The coordinates will always be scaled based on the width of the screen.
    */
    float[] setAccessBarTextPosition(int screenWidth, int screenHeight)
    {
        float[] result = new float[accessBarTexts.length];
        /* Set font size for textWidth() usage */
        textFont(font, scaleFontSize(font, 10, screenWidth/15));
        float textWidthOffset = screenWidth/15;
        float textWidthSpace = screenWidth * 9/10;
        float textWidthBuffer = textWidth(getLongestStrFromArr(accessBarTexts));
          
        /* Determine the X coordinates of the access bar texts to be displayed */
        float xPosition = textWidthOffset;
        for( int textNum = 0; textNum < accessBarTexts.length - 2; textNum++ )
        {
            float bufferDiff = (xPosition + textWidth(accessBarTexts[textNum])) - (xPosition + textWidthBuffer);
            result[textNum] = xPosition;
            xPosition += bufferDiff + textWidthSpace/(accessBarTexts.length - 2);
        }
      
        /* Determine the X coordinates of the last two texts, which will ALWAYS be "---" & "X" */
        textWidthSpace = screenWidth/30; 
        xPosition = screenWidth * 37/40;
        for( int textNum = accessBarTexts.length - 2; textNum < accessBarTexts.length; textNum++ )
        {
            result[textNum] = xPosition;
            xPosition += textWidthSpace;
        }
        return result;
    }
    
    /* 
     * getLongestStrFromArr returns the longest string in a String array.
    */
    String getLongestStrFromArr(String[] strArr)
    {
        String longestStr = "";
        for(int i = 0; i < strArr.length; i++)
            if ( strArr[i].length() > longestStr.length() )
                longestStr = strArr[i];
        return longestStr;
    }

    /* 
     * setMenuStates handles changes in the menu states accessed from the access bar.
     * It takes in the current menu state and the new proposed menu state, 
     * and returns the appropriate new state when necessary.
    */
    int setMenuState(int prevState, int newState)
    {
        switch(newState)
        {
            case MenuStates.DISPLAY: 
                displayAudioMetaData = !displayAudioMetaData; return prevState;
            case MenuStates.MINIMIZE:
                this.frame.setExtendedState(JFrame.ICONIFIED); return prevState;
            case MenuStates.EXIT:
                exit();
            default:
            {    
                /* If currently on a menu and selecting another, switch to the new menu */
                if ( newState != prevState )
                {
                    if ( menuState == MenuStates.QUEUE && queueIndex > 9 )
                        queueCycle = queueIndex - 9;
                    return newState;
                }
                /* Otherwise click the current menu on the access bar again to exit back to main screen */
                else
                {
                    tint(170, 50);
                    filters.startFilters();
                    if ( songPlayer.isPlaying() || audioMode == AudioStates.INPUT )
                            bars.startBars();
                    return MenuStates.NONE;
                }
            }   
        }
    }
    
void init()
{
  // to make a frame not displayable, you can
  // use frame.removeNotify()
  frame.removeNotify();
  frame.setUndecorated(true);
  frame.addNotify();
  super.init();
}


void setup()
{ 
  img = loadImage("background.jpg");
  resizeToScreen(img);
  
  size(img.width, img.height, JAVA2D);
  tintMode = true;
  blinkMode = true;
  blurMode = true;
  stretchMode = true;
  barNum = 9;
  divideBars = true;              
  displayAudioMetaData = true;
  
  menuState = MenuStates.NONE;
  
  bassSensitivity = 0.03;        
  midSensitivity = 0.03;
  highSensitivity = 0.06;
  allSensitivity = 3.0;

  minim = new Minim(this);
  in = minim.getLineIn();

  songPlayer = minim.loadFile("Quest_Complete.mp3");
  audioMode = AudioStates.OFF;
  playerMode = AudioStates.NONE;
  playerPaused = false;
  //songPlayer.pause();

  songQueue = new ArrayList<String>();

  font = createFont("Century Gothic", 10, true);
  font2 = createFont("Meiryo", (width + height)/100, true);

  filters = new FilterHandler(songPlayer, img);
  bars = new MusicBars(songPlayer, img, font);
  bars.pauseBars();
  
  /* Initialize manually drawn GUI elements */
  accessBarTexts = new String[] {"Image", "Song", "Display", "Options", "Queue", "---", "X"};
  accessBarTextXPositions = setAccessBarTextPosition(width, height);


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
      //Why does this cause ArrayIndexOutOfBounds error? Fucking ControlP5 is always buggy as fuck.
      //.setSize((4 * width)/80, (int) textAscent())
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
  //Allows the frame to be resized.
  frame.setResizable(true);
  noStroke();
  smooth();
  frameRate(60);
}

//******************************************************************************************************
//Drag n' Drop event handler. Allows the pictualizer to load new images and songs that are dragged to it.
//******************************************************************************************************
//******************************************************************************************************
void dropEvent(DropEvent theDropEvent) {
  //If the DropEvent is an image.
  if ( theDropEvent.isImage() ) { 
    if ( imgResized )                //Refresh text input fields, since controlp5's text fields are BUGGY AS SHIT. HOLY FUCK.
      imgResized = false;
    img = loadImage(theDropEvent.filePath());
    changeImg(img);
    imgResized = true;
    bars.startBars();
    filters.startFilters();
  }
  else if ( theDropEvent.isFile() ) { 
    File theFile = theDropEvent.file();
    if ( theFile.isDirectory() ) {
      File[] folder = theDropEvent.listFilesAsArray(theFile, true);
      for ( int i = 0; i < folder.length; i++ ) {
        if ( folder[i].getPath().toLowerCase().indexOf(".mp3") != -1 || folder[i].getPath().toLowerCase().indexOf(".wav") != -1 ) {
          songQueue.add(folder[i].getPath());
          queueIndex++;
        }
      }
      if ( !songQueue.isEmpty() ) { 
        if ( queueIndex > 9 )
          queueCycle = queueIndex - 9;
        loadSong((String)songQueue.get(songQueue.size() - 1));
      }
      audioMode = AudioStates.PLAYER;
    }
    else if ( theDropEvent.filePath().toLowerCase().endsWith(".mp3") || theDropEvent.filePath().toLowerCase().endsWith(".wav") ) {
      songQueue.add(theDropEvent.filePath());
      queueIndex++;
      if ( !songQueue.isEmpty() ) { 
        if ( queueIndex > 9 )
          queueCycle = queueIndex - 9;
        loadSong((String)songQueue.get(songQueue.size() - 1));
      }
      audioMode = AudioStates.PLAYER;
    }
  }
}


//******************************************************************************************************
//Main draw loop that runs the pictualizer.
//******************************************************************************************************
//******************************************************************************************************
void draw()
{ 
  try { image(img, 0, 0); } catch(ArrayIndexOutOfBoundsException e) { redraw(); }
  filters.applyFilters(); 
  bars.drawBars();
  displayGUI();
  if ( audioMode == AudioStates.PLAYER )
    checkPlayerStatus();
}


void checkPlayerStatus()
{
  if ( !songPlayer.isPlaying() && !playerPaused && queueIndex - 1 < songQueue.size() && queueIndex > 0)
  {
    if ( playerMode == AudioStates.REPEAT )
    {
      songPlayer.close();
      minim.stop();
      minim = new Minim(this);
      songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
      if ( queueIndex > 9 )
      {
        queueCycle = queueIndex - 9;
      }
      filters.changeSource(songPlayer, 15); 
      bars.changeSource(songPlayer);      
      metaData = songPlayer.getMetaData();
      songPlayer.setGain(volume);
      songPlayer.play();
    }
    else if ( playerMode == AudioStates.SHUFFLE )
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
      filters.changeSource(songPlayer, 15);   
      bars.changeSource(songPlayer);    
      metaData = songPlayer.getMetaData();
      songPlayer.setGain(volume);
      songPlayer.play();
    }
    else if ( queueIndex + 1 < songQueue.size() )
    { 
      songPlayer.close();
      minim.stop();
      minim = new Minim(this);
      queueIndex++;
      songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
      filters.changeSource(songPlayer, 15);
      bars.changeSource(songPlayer);      
      metaData = songPlayer.getMetaData();
      songPlayer.setGain(volume);
      songPlayer.play();
      if ( queueIndex > 9 )
      {
        queueCycle = queueIndex - 9;
      }
    }
  }
}

  int scaleFontSize(PFont font, int maxSize, int heightLimit) 
  {
      int fontSize = 1; 
      textFont(font, fontSize);
      int textHeight = (int) textAscent();
      while ( fontSize < maxSize && textHeight < heightLimit ) 
      {
          fontSize++;
          textHeight = (int) textAscent(); 
      }
      return fontSize;
  }


void displayGUI()
{
  //PControl textfields are totally NOT friendly with resizing. Apparently setting them up ONCE after resizing doesn't do anything, so I just compromised
  //by looping their new coordinates during the options screen. Shouldn't really cost any significant CPU or FPS loss anyways..
  if ( imgResized )                    
  {
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

  textFont(font, scaleFontSize(font, 10, height/15));
  
    /*
     * Access Bar GUI
     * Draws an access bar on top of the program that appears when the mouse hovers over the top of the program.
     * The access bar allows access to all of the program's interactive options, namely:
     * Image, Song, Display(Toggle), Options, Queue, Minimize, and Exit.
    */
    if ( mouseY < textAscent() * 2.5)
    {   
        /* DEFAULT TEXT ALIGNMENT & SIZE */
        textAlign(LEFT); textFont(font, scaleFontSize(font, 10, height/15));
        /* Draw the gray bar first */
        fill(50, 50, 50, 50); rect(0, 0, width, textAscent() * 2.5);
             
        /* Define the height to display the access bar text at */
        float textHeightPosition = textAscent() * 1.5;
            
        for( int i = 0; i < accessBarTextXPositions.length; i++ )
        {
            /* Add fade for appearing text */
            fill(225, 225, 225, alphaVal);
            text(accessBarTexts[i], accessBarTextXPositions[i], textHeightPosition);
            
            /* Highlight the access bar texts if mouse hovers over them */
            if ( ((mouseY > textAscent() - textDescent()*2) && (mouseY < textDescent() + textAscent()*1.5)) &&
                 ((mouseX > accessBarTextXPositions[i]) && (mouseX < accessBarTextXPositions[i] + textWidth(accessBarTexts[i]))) )
            {
                fill(255, 255, 255);
                text(accessBarTexts[i], accessBarTextXPositions[i], textHeightPosition); 
            }               
        }   
        /* Increase the alpha value used by text to create a fading in effect */    
        if ( alphaVal < 255 )
            alphaVal = alphaVal + 15;    
    }
  
    /* Fades the access bar on top of the screen when the mouse does not hover over it */
    if ( mouseY > textAscent() * 2.5 )        
        alphaVal = 0;


  if ( (audioMode == AudioStates.PLAYER) && displayAudioMetaData && (menuState == MenuStates.NONE) )
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
    if ( ((mouseX > textAscent() * 8.5 + queueNumWidth) && (mouseX < textAscent() * 8.5 + textWidth(truncPath(metaData.fileName())+" ("
      +Methods.millisToMinutes(songPlayer.length())+":0"+Methods.millisToSeconds(songPlayer.length())+")")+ queueNumWidth)) 
      && ( (mouseY < textAscent() * 8.5) && (mouseY > textAscent() * 2.8 )) )  
    { 
      fill(175, 175, 175);
      text("volume:", textAscent() * 8.5 + queueNumWidth, textAscent() * 6.9);
      volField.show();  
      if ( playerMode == AudioStates.REPEAT )
      { 
        fill(255, 255, 255);
        text("re /", textAscent() * 8.5 + queueNumWidth, textAscent() * 7.9);
        fill(175, 175, 175);
        text(" shuff", textAscent() * 8.5 + textWidth("re /") + queueNumWidth, textAscent() * 7.9);
      }
      else if ( playerMode == AudioStates.SHUFFLE )
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

  if ( menuState == MenuStates.IMAGE )
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

  if ( menuState == MenuStates.SONG )
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
    if ( audioMode == AudioStates.INPUT )
    { 
      fill(255, 255, 255);
      text(": :  recording device / audio input", (5 * width)/20, (11 * height)/32);
    }
    else
    {
      fill(150, 150, 150);
      text(": :  recording device / audio input", (5 * width)/20, (11 * height)/32);
    }
    if ( audioMode == AudioStates.PLAYER )
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

  if ( displayAudioMetaData && (menuState == MenuStates.NONE) )                    //Displays Audio Metadata analyzed by Minim's player.
  { 
    fill(255, 255, 255);
    textFont(font, (height + width)/35);
    textAlign(RIGHT, BASELINE);
    if ( (audioMode == AudioStates.PLAYER) && songPlayer.isPlaying() )
    {
      text(": :  PLAYING", width - textAscent(), height - textAscent() * 3.5);
    }
    else if ( audioMode == AudioStates.PLAYER )
    {
      text(": :  PAUSED", width - textAscent(), height - textAscent() * 3.5);
    }

    if ( audioMode == AudioStates.PLAYER )
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
      if ( Methods.millisToSeconds(songPlayer.length()) < 10 )
      {
        text(""+truncPath(metaData.fileName())+" ("+Methods.millisToMinutes(songPlayer.length())+":0"+Methods.millisToSeconds(songPlayer.length())+")", textAscent() * 8.5 + queueNumWidth, textAscent() * 3.8);
      }
      else
      {
        text(""+truncPath(metaData.fileName())+" ("+Methods.millisToMinutes(songPlayer.length())+":"+Methods.millisToSeconds(songPlayer.length())+")", textAscent() * 8.5 + queueNumWidth, textAscent() * 3.8);
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
      if ( Methods.millisToSeconds(songPlayer.position()) < 10 )
      {
        text(""+Methods.millisToMinutes(songPlayer.position())+":0"+Methods.millisToSeconds(songPlayer.position()), width - textDescent(), height - textDescent());
      }
      else
      {
        text(""+Methods.millisToMinutes(songPlayer.position())+":"+Methods.millisToSeconds(songPlayer.position()), width - textDescent(), height - textDescent());
      }
    }
  }
  else
  {
    seeker.hide();
  }  

  if ( menuState == MenuStates.OPTIONS )                    //Displays the Options menu.
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

  if ( menuState == MenuStates.QUEUE )
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
      text(""+(queueCycle + 1)+"  "+truncPath((String)songQueue.get(queueCycle)), width/3.5, height/3);
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 1)+"  "+truncPath((String)songQueue.get(queueCycle))))
        && (mouseY > height/3 - textAscent() && mouseY < height/3 ) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 1)+"  "+truncPath((String)songQueue.get(queueCycle)), width/3.5, height/3);
        }
        else
        { 
          fill(175, 175, 175);
          text(""+(queueCycle + 1)+"  "+truncPath((String)songQueue.get(queueCycle)), width/3.5, height/3);
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
      text(""+(queueCycle + 2)+"  "+truncPath((String)songQueue.get(queueCycle + 1)), width/3.5, height/3 + height/25);
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 2)+"  "+truncPath((String)songQueue.get(queueCycle + 1))))
        && (mouseY > height/3 + height/25 - textAscent() && mouseY < height/3 + height/25 ) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 1))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 1) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 2)+"  "+truncPath((String)songQueue.get(queueCycle + 1)), width/3.5, height/3 + height/25);
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 2)+"  "+truncPath((String)songQueue.get(queueCycle + 1)), width/3.5, height/3 + height/25);
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
      text(""+(queueCycle + 3)+"  "+truncPath((String)songQueue.get(queueCycle + 2)), width/3.5, height/3 + (2 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 3)+"  "+truncPath((String)songQueue.get(queueCycle + 2))))
        && (mouseY > height/3 + (2 * height/25) - textAscent() && mouseY < height/3 + (2 * height/25 )) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 2))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 2) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 3)+"  "+truncPath((String)songQueue.get(queueCycle + 2)), width/3.5, height/3 + (2 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 3)+"  "+truncPath((String)songQueue.get(queueCycle + 2)), width/3.5, height/3 + (2 * height/25));
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
      text(""+(queueCycle + 4)+"  "+truncPath((String)songQueue.get(queueCycle + 3)), width/3.5, height/3 + (3 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 4)+"  "+truncPath((String)songQueue.get(queueCycle + 3))))
        && (mouseY > height/3 + (3 * height/25) - textAscent() && mouseY < height/3 + (3 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 3))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 3) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 4)+"  "+truncPath((String)songQueue.get(queueCycle + 3)), width/3.5, height/3 + (3 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 4)+"  "+truncPath((String)songQueue.get(queueCycle + 3)), width/3.5, height/3 + (3 * height/25));
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
      text(""+(queueCycle + 5)+"  "+truncPath((String)songQueue.get(queueCycle + 4)), width/3.5, height/3 + (4 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 5)+"  "+truncPath((String)songQueue.get(queueCycle + 4))))
        && (mouseY > height/3 + (4 * height/25) - textAscent() && mouseY < height/3 + (4 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 4))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 4) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 5)+"  "+truncPath((String)songQueue.get(queueCycle + 4)), width/3.5, height/3 + (4 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 5)+"  "+truncPath((String)songQueue.get(queueCycle + 4)), width/3.5, height/3 + (4 * height/25));
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
      text(""+(queueCycle + 6)+"  "+truncPath((String)songQueue.get(queueCycle + 5)), width/3.5, height/3 + (5 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 6)+"  "+truncPath((String)songQueue.get(queueCycle + 5))))
        && (mouseY > height/3 + (5 * height/25) - textAscent() && mouseY < height/3 + (5 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 5))
      { 
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 5) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 6)+"  "+truncPath((String)songQueue.get(queueCycle + 5)), width/3.5, height/3 + (5 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 6)+"  "+truncPath((String)songQueue.get(queueCycle + 5)), width/3.5, height/3 + (5 * height/25));
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
      text(""+(queueCycle + 7)+"  "+truncPath((String)songQueue.get(queueCycle + 6)), width/3.5, height/3 + (6 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 7)+"  "+truncPath((String)songQueue.get(queueCycle + 6))))
        && (mouseY > height/3 + (6 * height/25) - textAscent() && mouseY < height/3 + (6 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 6))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 6) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 7)+"  "+truncPath((String)songQueue.get(queueCycle + 6)), width/3.5, height/3 + (6 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 7)+"  "+truncPath((String)songQueue.get(queueCycle + 6)), width/3.5, height/3 + (6 * height/25));
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
      text(""+(queueCycle + 8)+"  "+truncPath((String)songQueue.get(queueCycle + 7)), width/3.5, height/3 + (7 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 8)+"  "+truncPath((String)songQueue.get(queueCycle + 7))))
        && (mouseY > height/3 + (7 * height/25) - textAscent() && mouseY < height/3 + (7 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 7))
      {
        if ( songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 7) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 8)+"  "+truncPath((String)songQueue.get(queueCycle + 7)), width/3.5, height/3 + (7 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 8)+"  "+truncPath((String)songQueue.get(queueCycle + 7)), width/3.5, height/3 + (7 * height/25));
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
      text(""+(queueCycle + 9)+"  "+truncPath((String)songQueue.get(queueCycle + 8)), width/3.5, height/3 + (8 * height/25));
      if ( (mouseX > width/3.7 && mouseX < width/3.5 + textWidth(""+(queueCycle + 9)+"  "+truncPath((String)songQueue.get(queueCycle + 8))))
        && (mouseY > height/3 + (8 * height/25) - textAscent() && mouseY < height/3 + (8 * height/25)) || songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 8))
      { 
        if (  songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 8) )
        {
          fill(255, 255, 255);
          text(""+(queueCycle + 9)+"  "+truncPath((String)songQueue.get(queueCycle + 8)), width/3.5, height/3 + (8 * height/25));
        }
        else
        {
          fill(175, 175, 175);
          text(""+(queueCycle + 9)+"  "+truncPath((String)songQueue.get(queueCycle + 8)), width/3.5, height/3 + (8 * height/25));
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
    /* 
     * Click controller for the Access Bar.
     * Handles the click events for the following buttons on the access bar:
     * Image, Song, Display, Options, Queue, Minimize(---), and Exit(X)
     * FOR NOW: The access bar text height is centered at textAscent() * 1.5
    */
    textFont(font, scaleFontSize(font, 10, height/15));
    if ( (mouseY > textAscent() - textDescent()*2) && (mouseY < textDescent() + textAscent()*1.5) )
    {
        /* Loop and check all possible menu states accessible from the access bar */
        for( int i = 0; i < accessBarTexts.length; i++ )
        {
            if ( (mouseX > accessBarTextXPositions[i]) && (mouseX < accessBarTextXPositions[i] + textWidth(accessBarTexts[i])) )
                menuState = setMenuState(menuState, i);
        }
    }  
      


  if ( (audioMode == AudioStates.PLAYER) && displayAudioMetaData && (menuState == MenuStates.NONE) )
  { 

    textFont(font, (width+height)/100);
    if ( (mouseX > textAscent() * 8.5 + queueNumWidth && mouseX < textAscent() * 8.5 + queueNumWidth + textWidth("re / shuff"))
      && ( (mouseY > textAscent() * 6.9 && mouseY < textAscent() * 8.9 )) )
    { 
      if ( playerMode == AudioStates.REPEAT )
      {
        playerMode = AudioStates.SHUFFLE;
      }
      else if ( playerMode == AudioStates.SHUFFLE )
      {
        playerMode = AudioStates.NONE;
      }
      else
      {
        playerMode = AudioStates.REPEAT;
      }
    }
    textFont(font, (width+height)/35);
    if ( (mouseX > width - textAscent() - textWidth(": :  PLAYING")) && (mouseX < width - textAscent()) && songPlayer.isPlaying() )
    {
      if ( (mouseY > height - textAscent() * 4.5 + textDescent() ) && (mouseY < height - textAscent() * 3.5 ) )
      { 
        songPlayer.pause(); playerPaused = true;
        bars.pauseBars();
      }
    }
    else if ( (mouseX > width - textAscent() - textWidth(": :  PAUSED")) && (mouseX < width - textAscent()) )
    {
      if ( (mouseY > height - textAscent() * 4.5 + textDescent() ) && (mouseY < height - textAscent() * 3.5 ) )
      {
        /* If the player has finished playing the last song, rewind the last song if PAUSED is pressed again */
        if ( !playerPaused )
        { 
          songPlayer.pause();
          songPlayer.play();
          songPlayer.rewind();
        }
        else
        {
          playerPaused = false;
          songPlayer.play();
          bars.startBars();
        }
      }
    }

    textFont(font2, (width+height)/100);                //SongQueue system in the flesh. Works out very nicely.
    textAlign(LEFT);
    if ( ((mouseX > textAscent() * 3 + queueNumWidth/2) && (mouseX < textAscent() * 3 + textWidth("<<") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5) && (mouseY > textAscent() * 6.5 )) )
    { 
      if ( queueIndex - 1 > 0 )
      {
        if ( playerMode == AudioStates.SHUFFLE )
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
        filters.changeSource(songPlayer, 15);                
        metaData = songPlayer.getMetaData();
        songPlayer.setGain(volume);
        songPlayer.play();
        bars.startBars();
      }
    }
    if ( ((mouseX > textAscent() * 6 + queueNumWidth/2) && (mouseX < textAscent() * 6 + textWidth(">>") + queueNumWidth/2)) && ( (mouseY < textAscent() * 7.5) && (mouseY > textAscent() * 6.5 )) )
    {
      if ( queueIndex < songQueue.size() )
      { 
        if ( playerMode == AudioStates.SHUFFLE )
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
        filters.changeSource(songPlayer, 15);                
        metaData = songPlayer.getMetaData();
        songPlayer.setGain(volume);
        songPlayer.play();
        bars.startBars();
      }
    }
  }

  if ( menuState == MenuStates.OPTIONS )           //Click responses for the configuration screen.
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

  if ( menuState == MenuStates.SONG )
  { 
    if ( (mouseX > (5 * width)/20) && (mouseX < (5 * width)/20 + textWidth(": :  recording device / audio input") ) )
    {
      if ( (mouseY > (21 * height)/64) && (mouseY < (22 * height)/64) )
      {
        if ( audioMode == AudioStates.INPUT )
        {
          audioMode = AudioStates.PLAYER;
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);
          //Determine if bars needed to be paused upon exiting audio input mode.
          if ( songQueue.isEmpty() )
              bars.pauseBars();
          songPlayer.play();
        }
        else
        {
          audioMode = AudioStates.INPUT;
          bars.changeSource(in);
          filters.changeSource(in, 20);
          songPlayer.pause();
        }
      }
      if ( (mouseY > (23 * height)/64) && (mouseY < (97 * height)/256) )
      {
        if ( audioMode == AudioStates.PLAYER )
        {
          audioMode = AudioStates.INPUT;
          bars.changeSource(in);
          filters.changeSource(in, 20);
          songPlayer.pause();
        }
        else
        {
          audioMode = AudioStates.PLAYER;
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);
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

  if ( menuState == MenuStates.QUEUE )
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 1)+"  "+truncPath((String)songQueue.get(queueCycle))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle)))
        {
          songPlayer.close();
          queueIndex = queueCycle + 1;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 2)+"  "+truncPath((String)songQueue.get(queueCycle + 1))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 1)))
        {
          songPlayer.close();
          queueIndex = queueCycle + 2;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 3)+"  "+truncPath((String)songQueue.get(queueCycle + 2))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 2)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 3;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 4)+"  "+truncPath((String)songQueue.get(queueCycle + 3))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 3)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 4;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 5)+"  "+truncPath((String)songQueue.get(queueCycle + 4))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 4)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 5;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 6)+"  "+truncPath((String)songQueue.get(queueCycle + 5))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 5)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 6;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 7)+"  "+truncPath((String)songQueue.get(queueCycle + 6)))) 
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 6)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 7;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 8)+"  "+truncPath((String)songQueue.get(queueCycle + 7))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 7)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 8;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
        if ( (mouseX > width/3.5 && mouseX < width/3.5 + textWidth(""+(queueCycle + 9)+"  "+truncPath((String)songQueue.get(queueCycle + 8))))
          && !(songQueue.get(queueIndex - 1) == songQueue.get(queueCycle + 8)) )
        {
          songPlayer.close();
          queueIndex = queueCycle + 9;
          songPlayer = minim.loadFile((String)songQueue.get(queueIndex - 1));
          bars.changeSource(songPlayer);
          filters.changeSource(songPlayer, 15);                
          metaData = songPlayer.getMetaData();
          songPlayer.setGain(volume);
          songPlayer.play();
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
      if ( !Methods.isInteger(theEvent.getStringValue()) )
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
    if ( !Methods.isFloat(theEvent.getStringValue()) )
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
    if ( !Methods.isFloat(theEvent.getStringValue()) )
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
    if ( !Methods.isFloat(theEvent.getStringValue()) )
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
    if ( !Methods.isFloat(theEvent.getStringValue()) )
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
    if ( !Methods.isInteger(theEvent.getStringValue()) )
    {
      width = width;
    }
    else
    { 
      if ( imgResized )
      {
        imgResized = false;
      }
      img.resize(Integer.parseInt(theEvent.getStringValue()), 0);
      frame.setSize(img.width, img.height);
      imgResized = true;
      resizeHeightField.setText(""+img.height);
      img = img.get();
      bars.pauseBars();
      bars.changeImage(img);
      filters.pauseFilters();
      filters.changeImage(img);
      accessBarTextXPositions = setAccessBarTextPosition(img.width, img.height);
    }
  }
  if ( theEvent.getName().equals(resizeHeightField.getName()) )
  {
    if ( !Methods.isInteger(theEvent.getStringValue()) )
    {
      height = height;
    }
    else
    { 
      if ( imgResized )
      {
        imgResized = false;
      }
      img.resize(0, Integer.parseInt(theEvent.getStringValue()));
      frame.setSize(img.width, img.height);
      imgResized = true;
      resizeWidthField.setText(""+img.width);
      img = img.get();
      bars.pauseBars();
      bars.changeImage(img);
      filters.pauseFilters();
      filters.changeImage(img);
      accessBarTextXPositions = setAccessBarTextPosition(img.width, img.height);
    }
  }
  if ( theEvent.getName().equals(seekField.getName()) )
  {
    if ( !Methods.isInteger(Methods.removeChar(theEvent.getStringValue())) || (Methods.convertToMillis(Integer.parseInt(Methods.removeChar(theEvent.getStringValue()))) > songPlayer.length() ) )
    {
      seekField.setValue("n/a");
    }
    else
    {
      songPlayer.cue(Methods.convertToMillis(Integer.parseInt(Methods.removeChar(theEvent.getStringValue()))));
    }
  }
  if ( theEvent.getName().equals(volField.getName()) )
  {
    if ( !Methods.isFloat(theEvent.getStringValue()) )
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
