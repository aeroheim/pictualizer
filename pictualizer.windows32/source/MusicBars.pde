
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
      bass = 0.005;
      mid = 0.020;
      hi = 0.060;
      all = 1.000;
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
              amps[i] = (int) (.6 * all * bass * height * audioData.calcAvg((900/amps.length)*divider, (900/amps.length)*(divider+1)));
          //MID Range: 300Hz - 1200Hz          
          else if ( i >= amps.length/3 && i < (2 * amps.length)/3 ) 
              amps[i] = (int) (.6 * all * mid * height * audioData.calcAvg(300+(2700/amps.length)*divider, 300+(2700/amps.length)*(divider+1)));
          //HI Range: 1200Hz - 6000Hz
          else 
              amps[i] = (int) (.6 * all * hi * height * audioData.calcAvg(1200+(15000/amps.length)*divider, 1200+(15000/amps.length)*(divider+1)));
          if ( amps[i] > height * .6 )
              amps[i] = (int) (height * .6);
          copy(srcImg, width/5+((3*width)/(5*amps.length)+1)*i, height * 4/5, barWidth, -amps[i], width/5+((3*width)/(5*amps.length)+1)*i, height * 4/5, barWidth, -amps[i]);
      }
  }
       
    
}
