/**
 *  class: MusicBar
 *  draws all visualization bars in visualizer using FFT data from
 *  an AudioSource
*/


class MusicBars {
  
  public static final int STRETCH_MODE = 0;
  public static final int CENTER_MODE = 1;
  public static final int DEBUG_FONT_SIZE = 6;
  private static final float SMOOTH = 0.85;
  
  private PImage srcImg;
  private PFont font;
  private int fontSize;
  
  private AudioSource source;
  private FFT audioData;
  private int[] amps;
  
  private int mode;
  private boolean debugMode;
  private boolean display;
  
  private float bass;
  private float mid;
  private float hi;
  private float all;
  
  public MusicBars(AudioSource source, PImage img, PFont font) {
      this.source = source;
      this.font = font;
      srcImg = img;
      srcImg.loadPixels();
      audioData = new FFT(source.bufferSize(), source.sampleRate());
      audioData.window(FFT.HAMMING);
      mode = STRETCH_MODE;
      debugMode = true;
      display = true;
      amps = new int[21];
      for(int i = 0; i < amps.length; i++)
          amps[i] = 0;
      bass = 0.03;
      mid = 0.03;
      hi = 0.04;
      all = 2.0;
      fontSize = getScaledFontSize();
  }
  
  
  private int getScaledFontSize() {
      int tempSize = DEBUG_FONT_SIZE;
      textFont(font, tempSize);
      while ( textWidth("0000 - 0000 Hz") > srcImg.width/amps.length - srcImg.width/200 ) {
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
      srcImg = img;
      fontSize = getScaledFontSize();
      srcImg.loadPixels();
      /* Wait for frame to update before altering pixels; done to avoid ArrayIndexOutOfBounds exception */
      //while ( srcImg.pixels.length != pixels.length )
         // frame.setSize(img.width, img.height);
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
  
  
  private float getMaxAmp(int minFreq, int maxFreq)
  {
      float maxAmp = 0.0;
      float amp = 0.0;
      for(int i = minFreq; i < maxFreq; i++)
          if ( (amp = audioData.calcAvg(i, i)) > maxAmp )
              maxAmp = amp;
      return maxAmp;
  }
  
  //***********  SET A LIMIT ON NUMBARS FOR WHEN BARS BECOME TOO SMALL AND DISAPPEAR  *****************//
  private void drawStretchBars() {
      audioData.forward(source.mix);
      int barWidth = width/amps.length - width/150;
      if ( debugMode ) {
          textFont(font, fontSize);
          textAlign(LEFT); 
      }
      int divider;
      loadPixels();
      for ( int i = 0; i < amps.length; i++ ) {
          //divider keeps all 3 ranges in their respective frequencies.
          divider = i % (amps.length / 3);
          //BASS Range: 0Hz - 450Hz
          if ( i < amps.length/3 ) { 
              amps[i] = (int) (amps[i] * SMOOTH + (all * bass * height * (log(audioData.calcAvg(((450*3)/amps.length)*divider, ((450*3)/amps.length)*(divider+1)))/log(2))) * (1 - SMOOTH));
              //amps[i] = (int) (all * bass * height * log(audioData.calcAvg((900/amps.length)*divider, (900/amps.length)*(divider+1))));
              if ( debugMode )
                  text(""+((900/amps.length)*divider)+"- "+((900/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
          }
          //MID Range: 450Hz - 1350Hz          
          else if ( i >= amps.length/3 && i < (2 * amps.length)/3 ) {
              amps[i] = (int) (amps[i] * SMOOTH + (all * mid * height * (log(audioData.calcAvg(450+((900*3)/amps.length)*divider, 450+((900*3)/amps.length)*(divider+1)))/log(2))) * (1 - SMOOTH));
              //amps[i] = (int) (all * mid * height * audioData.calcAvg(300+(1800/amps.length)*divider, 300+(1800/amps.length)*(divider+1)));
              if ( debugMode )
                  text(""+(300+(1800/amps.length)*divider)+"- "+(300+(1800/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
          }
          //HI Range: 1350Hz - 2400Hz
          else {
              amps[i] = (int) (amps[i] * SMOOTH + (all * hi * height * (log(audioData.calcAvg(1350+((1050*3)/amps.length)*divider, 1350+((1050*3)/amps.length)*(divider+1)))/log(2))) * (1 - SMOOTH));
              //amps[i] = (int) (all * hi * height * audioData.calcAvg(900+(4500/amps.length)*divider, 900+(4500/amps.length)*(divider+1)));
              if ( debugMode )
                  text(""+(900+(4500/amps.length)*divider)+"- "+(900+(4500/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
          }
          
          if ( amps[i] > height ) amps[i] = height;
          else if ( amps[i] < 0 ) amps[i] = 0;
          //copy(srcImg, (width/amps.length+1) * i, height, barWidth, -amps[i], (width/amps.length+1) * i, height, barWidth, -amps[i]);
          for( int j = ( (srcImg.height-amps[i]-1) * srcImg.width ); j < srcImg.height * srcImg.width - 1; j += srcImg.width )
              try { 
                  int coordinate = j + (((srcImg.width/amps.length) + 1) * i);
                  if ( i == amps.length - 1 )
                      System.arraycopy(srcImg.pixels, coordinate, pixels, coordinate, srcImg.width - ((srcImg.width/amps.length + 1) * i)); 
                  else
                      System.arraycopy(srcImg.pixels, coordinate, pixels, coordinate, barWidth); 
              }
              catch( ArrayIndexOutOfBoundsException e ) { redraw(); }              
      }
      updatePixels();
      
      if ( debugMode )
          for ( int i = 0; i < amps.length; i++ )
          {
              divider = i % (amps.length / 3);
              if ( i < amps.length/3 ) text(""+((900/amps.length)*divider)+"- "+((900/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
              else if ( i >= amps.length/3 && i < (2 * amps.length)/3 ) text(""+(300+(1800/amps.length)*divider)+"- "+(300+(1800/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
              else text(""+(900+(4500/amps.length)*divider)+"- "+(900+(4500/amps.length)*(divider+1))+"Hz", (width/amps.length+1)*i, height - amps[i] - 2);
          }
  }
  
  private void drawCenterBars() {
      audioData.forward(source.mix);
      int barWidth = (3*width)/(5*amps.length) - width/150;
      int divider;
      loadPixels();
      for ( int i = 0; i < amps.length; i++ ) {
          //divider keeps all 3 ranges in their respective frequencies.
          divider = i % (amps.length / 3);
          //BASS Range: 0Hz - 450Hz
          if ( i < amps.length/3 ) 
              amps[i] = (int) (amps[i] * SMOOTH + (.6 * all * bass * height * log(audioData.calcAvg(((450*3)/amps.length)*divider, ((450*3)/amps.length)*(divider+1)))) * (1 - SMOOTH));
              //amps[i] = (int) (.6 * all * bass * height * audioData.calcAvg((900/amps.length)*divider, (900/amps.length)*(divider+1)));
          //MID Range: 450Hz - 1350Hz          
          else if ( i >= amps.length/3 && i < (2 * amps.length)/3 ) 
              amps[i] = (int) (amps[i] * SMOOTH + (.6 * all * mid * height * log(audioData.calcAvg(450+((900*3)/amps.length)*divider, 450+((900*3)/amps.length)*(divider+1)))) * (1 - SMOOTH));
              //amps[i] = (int) (.6 * all * mid * height * audioData.calcAvg(300+(2700/amps.length)*divider, 300+(2700/amps.length)*(divider+1)));
          //HI Range: 1350Hz - 2400Hz
          else 
              amps[i] = (int) (amps[i] * SMOOTH + (.6 * all * hi * height * log(audioData.calcAvg(1350+((1050*3)/amps.length)*divider, 1350+((1050*3)/amps.length)*(divider+1)))) * (1 - SMOOTH));
              //amps[i] = (int) (.6 * all * hi * height * audioData.calcAvg(1200+(15000/amps.length)*divider, 1200+(15000/amps.length)*(divider+1)));
          if ( amps[i] > height * .6 ) amps[i] = (int) (height * .6);
          else if ( amps[i] < 0 ) amps[i] = 0;
          //copy(srcImg, width/5+((3*width)/(5*amps.length)+1)*i, height * 4/5, barWidth, -amps[i], width/5+((3*width)/(5*amps.length)+1)*i, height * 4/5, barWidth, -amps[i]);
          for( int j = (int)(( (((4.0/5.0) * srcImg.height) - amps[i] - 1) * srcImg.width + ((1.0/5.0)*srcImg.width) )); j < (int)(((4.0/5.0)*srcImg.height) * srcImg.width - ((1.0/5.0)*srcImg.width)); j += srcImg.width )
              try { 
                  int coordinate = (int)(j + (((((3.0/5.0)*srcImg.width)/amps.length)) * i));
                  System.arraycopy(srcImg.pixels, coordinate, pixels, coordinate, barWidth); 
              }
              catch( ArrayIndexOutOfBoundsException e ) { redraw(); }              
      }
      updatePixels();
  }
       
}
