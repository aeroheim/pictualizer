import ddf.minim.*;
import ddf.minim.analysis.*;
import sojamo.drop.*;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import javax.imageio.ImageIO;

import java.lang.Float.*;

PImage img;
PGraphics tintBuffer;
PGraphics imageBuffer;

/* Music/Minim */
Minim minim;
AudioSource in;

/* Visualizations. */
// AudioSpectrumVisualizer spectrumVisualizer;

/* Widgets. */
AudioWidget widget;

/* Fonts. */
PFont meiryo;
PFont centuryGothic;


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
    
    tintBuffer = createGraphics(width, height);
    tintBuffer.beginDraw();
    tintBuffer.endDraw();
    
    imageBuffer = createGraphics(width, height);
    imageBuffer.beginDraw();
    imageBuffer.image(img, 0, 0);
    imageBuffer.endDraw();
    
    // initialize music
    minim = new Minim(this);
    in = minim.getLineIn(); 
    
    /*     
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
    */
    
    // initialize fonts
    meiryo = createFont("M+ 2p thin", 64, true);
    centuryGothic = createFont("Century Gothic", 64, true);
    
    // initialize widget
    widget = new AudioWidget(width / 6.0, height / 3.0, (5.0 * width) / 6.0, (2.0 * height) / 3.0);
    widget.listen(in);
    
    
    initSDrop();
    initSongQueue();    
}


void draw()
{        
    drawMain();
    // tint(110, 150);
    widget.draw();
}

void drawMain()
{
    /* Clear the previous frame. */
    tintBuffer.clear();
    tintBuffer.beginDraw();
    
    tintBuffer.image(img, 0, 0);
    tintBuffer.tint(130, 150);
    // spectrumVisualizer.draw(imageBuffer, tintBuffer);
   
    /* Finish the layer and draw it. */
    tintBuffer.scale(.5);
    tintBuffer.endDraw(); 
    image(tintBuffer, 0, 0);
}

void stop()
{ 
  // songPlayer.close();
  minim.stop();
  super.stop();
}
