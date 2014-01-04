import ddf.minim.*;
import ddf.minim.analysis.*;
import sojamo.drop.*;

PImage img;
PGraphics mainBuffer;

/* Music/Minim */
Minim minim;
AudioSource in;

/* Visualizations. */
ScrollingAudioWaveform scrollingVisualizer;
AudioSpectrumVisualizer spectrumVisualizer;

/* Widgets. */
AudioWidget widget;


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
    scrollingVisualizer = new ScrollingAudioWaveform(width / 6.0, (5.0 * width) / 6.0, height / 2.0, height, height / 3);
    scrollingVisualizer.listen(in);
    scrollingVisualizer.setTimeOffset(18);
    scrollingVisualizer.setAmpBoost(0.2);
    // scrollingVisualizer.setSmooth(0.8);
        
    // favorite ranges : 450, 1350, 2400
    int[] spectrumFreqRanges = new int[] {200, 450, 900, 1350, 1800, 2400};
    float[] spectrumSensitivities = new float[] {0.1, 0.1, 0.1, 0.1, 0.1, 0.1};
    spectrumVisualizer = new AudioSpectrumVisualizer(0, width, 0, height, 3, 30, false);
    spectrumVisualizer.listen(in);
    spectrumVisualizer.setSmooth(0.85);
    spectrumVisualizer.section(spectrumFreqRanges);
    spectrumVisualizer.setSensitivities(spectrumSensitivities);   
    spectrumVisualizer.setDividerWidth(5); 
    spectrumVisualizer.toggleBackgroundMode();
    
    // initialize widget
    widget = new AudioWidget(width / 6.0, height / 3.0, (5.0 * width) / 6.0, (2.0 * height) / 3.0, in);
    
    initSDrop();
    initSongQueue();
}


void draw()
{        
    drawMain();
    tint(110, 150);
    widget.draw();
    spectrumVisualizer.draw(mainBuffer);
    scrollingVisualizer.draw();
}

void drawMain()
{
    mainBuffer.clear();
    mainBuffer.beginDraw();
    
    mainBuffer.image(img, 0, 0);
    // mainBuffer.tint(110, 150);
    mainBuffer.endDraw();
    
    image(mainBuffer, 0, 0);
}

void stop()
{ 
  // songPlayer.close();
  minim.stop();
  super.stop();
}
