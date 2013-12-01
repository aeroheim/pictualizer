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
}


void draw()
{        
    image(img, 0, 0);
    tint(180, 150);
    scrollingVisualizer.draw();
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
