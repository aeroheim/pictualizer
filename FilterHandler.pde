

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
        blurMode = true;
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
                  if ( grayMode )
              grayFilter();
          if ( tintMode )
              tintFilter();
          if ( blurMode )
              blurFilter();

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
        if ( musicBeat.isRange(0, 5, 2) && blinkMode ) {
            tint(135, 45);
        }
        else
            tint(105, 60);
    }
  
    private void grayFilter() {
        filter(GRAY);
    }
  
    private void blurFilter() {
        if ( musicBeat.isRange(0, 5, 2) ) 
            image(blurImg, 0, 0);
    }

}
