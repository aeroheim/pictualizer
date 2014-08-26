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
import java.util.Collections;
import java.util.Random;

PImage img;
PGraphics tintBuffer;
PGraphics imageBuffer;

/* Music/Minim */
PAudioPlayer player;
Minim minim;
BeatListener beatListener;
BeatDetect beatDetect;

/* Visualizations. */
AudioSpectrumVisualizer spectrumVisualizer;

/* Widgets. */
AudioWidget widget;

/* Fonts. */
PFont mplus;
PFont centuryGothic;

public static int FRAME_RATE = 60;

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
        
    size(1080, 530, P2D);
    
    tintBuffer = createGraphics(width, height, P2D);
    tintBuffer.beginDraw();
    tintBuffer.endDraw();
    
    imageBuffer = createGraphics(width, height, JAVA2D);
    imageBuffer.beginDraw();
    imageBuffer.image(img, 0, 0);
    imageBuffer.endDraw();
    
    // initialize music
    minim = new Minim(this);
    player = new PAudioPlayer();
    
    beatDetect = new BeatDetect(player.getSource().bufferSize(), player.getSource().sampleRate());
    beatDetect.setSensitivity(250);
    // beatListener = new BeatListener(beatDetect, player.getSource());
    
    
    // favorite ranges : 450, 1350, 2400
    int[] spectrumFreqRanges = new int[] {450, 1350, 2400};
    float[] spectrumSensitivities = new float[] {0.01, 0.02, 0.02}; 
    spectrumVisualizer = new AudioSpectrumVisualizer(0, width, 0, height, 3, 21, false);
    spectrumVisualizer.listen(player.getSource());
    spectrumVisualizer.setSmooth(0.90);
    spectrumVisualizer.section(spectrumFreqRanges);
    spectrumVisualizer.setSensitivities(spectrumSensitivities);   
    // spectrumVisualizer.setDividerWidth((int) (width / 150.0)); 
    spectrumVisualizer.setDividerWidth(5);
    spectrumVisualizer.toggleBackgroundMode();

    
    // initialize fonts
    mplus = createFont("mplus-2p-light.ttf", 64, true);
    centuryGothic = createFont("GOTHIC.TTF", 64, true);
    
    // initialize widget
    // widget = new AudioWidget(player, width / 6.0, height / 3.0, (4.0 * width) / 6.0, (2 * height) / 5.0);
    widget = new AudioWidget(player, width / 20.0, height / 10.0, width / 2.0, height / 4.0);
    
    widget.listen(player.getSource());
    
    initSDrop();
    initBeatReactiveImage(img);
    initRoamingCamera();
    
}


void draw()
{   
    drawMain();
        
    widget.draw();
    player.checkPlayerStatus();
    roam(img);
}

void drawMain()
{
    /* Clear the previous frame. */
    tintBuffer.beginDraw();
    tintBuffer.clear();
    
    tintBuffer.scale(scale);
    tintBuffer.image(img, cameraX, cameraY);
    
    tintBuffer.tint(tint, 150);
   
    /* Finish the layer and draw it. */
    tintBuffer.endDraw(); 
    image(tintBuffer, 0, 0);
    
    // Draw the BeatReactiveImage
    if (isFlashing && fadeState == CameraFadeState.NO_FADE)
        drawBeatReactiveImage();
    
    /*
    // Draw the background spectrum visualizer
    if (fadeState == CameraFadeState.NO_FADE)
    {
        tintBuffer.beginDraw();  
        {
            tintBuffer.clear();
            spectrumVisualizer.draw(imageBuffer, tintBuffer); 
        }
        tintBuffer.endDraw();  
        
        image(tintBuffer, 0, 0);
    }
    */
    
    // Update values for the BeatReactiveImage.
    OnBeatDetect();
    
    // Update the image buffer used by spectrum visualizers
    updateImageBuffer();
}

void updateImageBuffer()
{
    imageBuffer.beginDraw();
    
    imageBuffer.scale(scale);
    imageBuffer.image(img, cameraX, cameraY);
    
    if (fadeState != CameraFadeState.NO_FADE)
        imageBuffer.tint(tint);
    
    imageBuffer.endDraw();
}

void stop()
{ 
  // songPlayer.close();
  super.stop();
}
