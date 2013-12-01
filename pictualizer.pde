import ddf.minim.*;
import ddf.minim.analysis.*;

PImage img;
PGraphics mainBuffer;

/* Music/Minim */
Minim minim;
AudioInput in;
AudioPlayer player;

/* Visualizations. */
ScrollingAudioWaveform scrollingVisualizer;
AudioSpectrumVisualizer spectrumVisualizer;


/*
 *  Remove processing's built in frame from window.
 */
void init()
{
    frame.removeNotify();
    frame.setUndecorated(true);
    frame.addNotify();
    super.init();
}

void setup()
{    
    img = loadImage("background.jpg");
    size(img.width, img.height, JAVA2D);
    background(img);
    
    mainBuffer = createGraphics(width, height);
    mainBuffer.beginDraw();
    mainBuffer.endDraw();
    
    // initialize music
    minim = new Minim(this);
    in = minim.getLineIn();
    
    // initialize visualizations
    scrollingVisualizer = new ScrollingAudioWaveform(width / 5.0, (4.0 * width) / 5.0, height / 2.0, height, height / 3);
    scrollingVisualizer.listen(in);
    scrollingVisualizer.setTimeOffset(18);
    
    spectrumVisualizer = new AudioSpectrumVisualizer(0, width, 0, height, 3, 21);   
    spectrumVisualizer.listen(in);
    spectrumVisualizer.setSmooth(0.85);
    int[] spectrumFreqRanges = new int[] {450, 1350, 2400};
    float[] spectrumSensitivities = new float[] {0.06, 0.06, 0.08};
    spectrumVisualizer.section(spectrumFreqRanges);
    spectrumVisualizer.setSensitivities(spectrumSensitivities);    
}


void draw()
{        
    image(img, 0, 0);
    tint(180, 150);
    scrollingVisualizer.draw();
    spectrumVisualizer.draw();
}

void drawMain()
{
    mainBuffer.clear();
    mainBuffer.beginDraw();
    
    image(img, 0, 0);
    tint(180, 150);
    
    mainBuffer.endDraw();
    image(mainBuffer, 0, 0);
}

void stop()
{ 
  // songPlayer.close();
  minim.stop();
  super.stop();
}
