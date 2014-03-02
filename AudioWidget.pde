/*
 *  class: AudioWidget
 *  A graphical widget that interfaces with audio.
 *  Displays visualizations, metadata, etc.
 */

import java.lang.String;

class AudioWidget
{  
    float x;
    float y;
    float widgetWidth;
    float widgetHeight;
    
    ScrollingAudioWaveform wave;
    AudioSpectrumVisualizer spectrum;
    
    AudioSource input;
    AudioMetaData metaData;
    
    ScrollingText title;
    ScrollingText artist;
       
    /* Add text buttons. */
    TextButton forward;
    TextButton previous;
    TextButton seek;
    TextButton vol;
    
    PGraphicsButton play;
    PGraphicsButton pause;
    PGraphicsButton stop;
    PGraphicsButton repeat;
    PGraphicsButton shuffle;
    
    ProgressBar seekBar;
    ProgressBar volBar;
    
    float barX;
    float barWidth;        
    float barY;
    float barHeight;
        
    PImage ID3AlbumArt;
    PImage defaultArt;
    
    int titleFontSize;
    int artistFontSize;
    int modeFontSize;
    int barFontSize;
    
    String songLength;
    float volume;
    
    States visMode;
    States barMode;
 
    AudioWidget(float startX, float startY, float widgetWidth, float widgetHeight)
    {
        
        x = startX;
        y = startY;
        this.widgetWidth = widgetWidth;
        this.widgetHeight = widgetHeight;
        
        try {
            defaultArt = loadImage("art.png");
            defaultArt.resize((int) widgetHeight, (int) widgetHeight);
        }
        catch (Exception e)
        {
            defaultArt = null;
        }

        generateID3AlbumArt();
        generateMetaData();
        
        // int[] spectrumRanges = new int[] {200, 450, 900, 1350, 2000, 3600};
        int[] spectrumRanges = new int[] {600, 1200, 2000, 3600, 4800, 6400};
        float[] spectrumBoost = new float[] {0.04, 0.07, 0.09, 0.15, 0.15, 0.15};
        // float[] spectrumBoost = new float[] {0.1, 0.1, 0.1, 0.1, 0.1, 0.1};        
        
        titleFontSize = (int) (widgetHeight / 3.5);
        artistFontSize = (int) (widgetHeight / 6.0);
        modeFontSize = (int) (widgetHeight / 8.0);
        barFontSize = (int) (widgetHeight / 12.0);
                                       
        visMode = States.AUDIO_SPECTRUM;
        barMode = States.BAR_SEEK;
                
        volume = 0.0;
        
        initButtons();
        initBars();
               
        initVisualizations(spectrumRanges, spectrumBoost);
    }
    
    void listen(AudioSource input)
    {
        this.input = input;
        wave.listen(input);
        spectrum.listen(input);
        if (input instanceof AudioPlayer)
        {
            ((AudioPlayer) input).setGain(volume);
            volBar.setCurrentValue(volume + 80);
        }
    }
    
    private void initButtons()
    {
        initPGraphicsButtons();
        initTextButtons();
    }
    
    private void initPGraphicsButtons()
    {
        float playX = x + ID3AlbumArt.width / 2.6;
        float playY = y + widgetHeight * 1.095;
        float playWidth = ID3AlbumArt.width / 2.25 - ID3AlbumArt.width / 2.75;
        float playHeight = widgetHeight * 0.1;
                
        float stopX = x + ID3AlbumArt.width / 1.85;
        float stopY = y + widgetHeight * 1.1;
        float stopSideLength = widgetHeight * 0.08;
        
        float pauseWidth = stopSideLength / 4.0;
        
        float repeatX = x + ID3AlbumArt.width + widgetWidth / 20;
        float repeatY = y + widgetHeight * 1.07;
        float repeatWidth = playWidth + 5;
        float repeatHeight = playHeight + 5;
        float repeatRadius = widgetWidth / 100;
                             
                      
        /* Initialize the PLAY PGraphicsButton. */
        PGraphics dimPlay = createGraphics((int) playWidth + 1, (int) playHeight + 1);
        PGraphics highlightPlay = createGraphics((int) playWidth + 1, (int) playHeight + 1);
        
        dimPlay.beginDraw(); dimPlay.noStroke(); dimPlay.fill(200, 150);
        dimPlay.triangle(0, 0, 0, playHeight, playWidth, playHeight / 2);
        dimPlay.endDraw();
        
        highlightPlay.beginDraw(); highlightPlay.noStroke(); highlightPlay.fill(255);
        highlightPlay.triangle(0, 0, 0, playHeight, playWidth, playHeight / 2);
        highlightPlay.endDraw();
  
        play = new PGraphicsButton(playX, playY, dimPlay, highlightPlay);
        
        
        /* Initialize the PAUSE PGraphicsButton. */
        PGraphics dimPause = createGraphics((int) playWidth + 1, (int) playHeight + 1);
        PGraphics highlightPause = createGraphics((int) playWidth + 1, (int) playHeight + 1);
        
        dimPause.beginDraw(); dimPause.noStroke(); dimPause.fill(200, 150);
        dimPause.rect(0, 0, pauseWidth, stopSideLength);
        dimPause.rect(stopSideLength / 1.5, 0, pauseWidth, stopSideLength);
        dimPause.endDraw();
        
        highlightPause.beginDraw(); highlightPause.noStroke(); highlightPause.fill(255);
        highlightPause.rect(0, 0, pauseWidth, stopSideLength);
        highlightPause.rect(stopSideLength / 1.5, 0, pauseWidth, stopSideLength);
        highlightPause.endDraw();
        
        pause = new PGraphicsButton(playX, stopY, dimPause, highlightPause);
      
      
        /* Initialize the STOP PGraphicsButton. */
        PGraphics dimStop = createGraphics((int) stopSideLength + 1, (int) stopSideLength + 1);
        PGraphics highlightStop = createGraphics((int) stopSideLength + 1, (int) stopSideLength + 1);
        
        dimStop.beginDraw(); dimStop.noStroke(); dimStop.fill(200, 150);
        dimStop.rect(0, 0, stopSideLength, stopSideLength);
        dimStop.endDraw();
        
        highlightStop.beginDraw(); highlightStop.noStroke(); highlightStop.fill(255);
        highlightStop.rect(0, 0, stopSideLength, stopSideLength);
        highlightStop.endDraw();
        
        stop = new PGraphicsButton(stopX, stopY, dimStop, highlightStop);
        
        /* Initialize the REPEAT PGraphicsButton. */
        PGraphics dimRepeat = createGraphics((int) repeatWidth, (int) repeatHeight);
        PGraphics highlightRepeat = createGraphics((int) repeatWidth, (int) repeatHeight);
        
        dimRepeat.beginDraw(); dimRepeat.stroke(200, 150); dimRepeat.strokeWeight(repeatWidth / 10); dimRepeat.noFill();
        dimRepeat.arc(repeatWidth / 2, repeatHeight / 2, repeatRadius * 2, repeatRadius * 2, QUARTER_PI, 2 * PI - QUARTER_PI);
        dimRepeat.fill(200); dimRepeat.noStroke();
        dimRepeat.triangle(repeatWidth/2 + repeatRadius/4, repeatHeight/2 - repeatRadius/4,
                           repeatWidth/2 + 5 * repeatRadius/4, repeatHeight/2 - repeatRadius/4,
                           repeatWidth/2 + repeatRadius, repeatHeight/2 - 5 * repeatRadius/4);
        dimRepeat.endDraw();
        
        highlightRepeat.beginDraw(); highlightRepeat.stroke(255); highlightRepeat.strokeWeight(repeatWidth / 10); highlightRepeat.noFill();
        highlightRepeat.arc(repeatWidth / 2, repeatHeight / 2, repeatRadius * 2, repeatRadius * 2, QUARTER_PI, 2 * PI - QUARTER_PI);
        highlightRepeat.fill(255); highlightRepeat.noStroke();
        highlightRepeat.triangle(repeatWidth/2 + repeatRadius/4, repeatHeight/2 - repeatRadius/4,
                           repeatWidth/2 + 5 * repeatRadius/4, repeatHeight/2 - repeatRadius/4,
                           repeatWidth/2 + repeatRadius, repeatHeight/2 - 5 * repeatRadius/4);
        highlightRepeat.endDraw();
        
        repeat = new PGraphicsButton(repeatX, repeatY, dimRepeat, highlightRepeat);
        
        /* Initialize the SHUFFLE PGraphicsButton. */
        float shuffleX = repeat.getX() + repeat.getWidth() + widgetWidth / 100;
        float shuffleY = repeat.getY();
        float shuffleWidth = repeatWidth;
        float shuffleHeight = repeatHeight;
        
        PGraphics dimShuffle = createGraphics((int) shuffleWidth, (int) shuffleHeight);
        PGraphics highlightShuffle = createGraphics((int) shuffleWidth, (int) shuffleHeight);
        
        dimShuffle.beginDraw(); dimShuffle.stroke(200, 150); dimShuffle.strokeWeight(shuffleWidth / 20); dimShuffle.noFill();
        dimShuffle.line(0, shuffleHeight / 8, (3 * shuffleWidth) / 4, 0); dimShuffle.line(0, shuffleHeight, (3 * shuffleWidth) / 4, (7 * shuffleHeight) / 8);
        dimShuffle.line(0, shuffleHeight / 8, 0, shuffleHeight); dimShuffle.line((3 * shuffleWidth) / 4, 0, (3 * shuffleWidth) / 4, shuffleHeight);
        dimShuffle.line(shuffleWidth / 2, shuffleHeight / 8, shuffleWidth, 0); dimShuffle.line(shuffleWidth / 2, shuffleHeight, shuffleWidth, (7 * shuffleHeight ) / 8);
        dimShuffle.line(shuffleWidth / 2, shuffleHeight / 8, shuffleWidth / 2, 0); dimShuffle.line(shuffleWidth, 0, shuffleWidth, (7 * shuffleHeight) / 8);
        dimShuffle.endDraw();
        
        highlightShuffle.beginDraw(); highlightShuffle.stroke(255); highlightShuffle.strokeWeight(shuffleWidth / 20); highlightShuffle.noFill();
        highlightShuffle.line(0, shuffleHeight / 8, (3 * shuffleWidth) / 4, 0); highlightShuffle.line(0, shuffleHeight, (3 * shuffleWidth) / 4, (7 * shuffleHeight) / 8);
        highlightShuffle.line(0, shuffleHeight / 8, 0, shuffleHeight); highlightShuffle.line((3 * shuffleWidth) / 4, 0, (3 * shuffleWidth) / 4, shuffleHeight);
        highlightShuffle.line(shuffleWidth / 2, shuffleHeight / 8, shuffleWidth, 0); highlightShuffle.line(shuffleWidth / 2, shuffleHeight, shuffleWidth, (7 * shuffleHeight ) / 8);
        highlightShuffle.line(shuffleWidth / 2, shuffleHeight / 8, shuffleWidth / 2, 0); highlightShuffle.line(shuffleWidth, 0, shuffleWidth, (7 * shuffleHeight) / 8);
        highlightShuffle.endDraw();
        
        shuffle = new PGraphicsButton(shuffleX, shuffleY, dimShuffle, highlightShuffle);                
    }
    
    private void initBars()
    {
        float barX = seek.getX() + seek.getWidth() * 1.25;
        float barY = seek.getY() + seek.getHeight() / 1.4;
        float barWidth = x + widgetWidth - (barX * 1.2);
        float barHeight = seek.getHeight() / 15.0;
        
        seekBar = new ProgressBar(barX, barY, barWidth, barHeight, 0, 0);
        seekBar.setColor(color(175));
        seekBar.setBackgroundColor(color(200, 35));
        
        volBar = new ProgressBar(barX, barY, barWidth, barHeight, 0, 94);
        volBar.setColor(color(175));
        volBar.setBackgroundColor(color(200, 35));
    }
    
    private void initTextButtons()
    {     
        previous = new TextButton(x, y + widgetHeight, meiryo, artistFontSize, "< <");
            previous.setColor(200);
            previous.setDimColor(200);
            previous.setHighlightColor(255);
            
        forward = new TextButton(x + ID3AlbumArt.width - previous.getWidth(), y + widgetHeight, meiryo, artistFontSize, "> >");
            forward.setColor(200);
            forward.setDimColor(200);
            forward.setHighlightColor(255);
            
        seek = new TextButton(shuffle.getX() + widgetWidth / 30, y + widgetHeight, meiryo, artistFontSize, "seek");
            seek.setColor(200);
            seek.setDimColor(200);
            seek.setHighlightColor(255);
            
        vol = new TextButton(shuffle.getX() + widgetWidth / 30, y + widgetHeight, meiryo, artistFontSize, "vol.");
            vol.setColor(200);
            vol.setDimColor(200);
            vol.setHighlightColor(255);
    }
    
    void initVisualizations(int[] spectrumRanges, float[] spectrumBoost)
    {
        /* Waveform visualizer. */
        wave = new ScrollingAudioWaveform(x + ID3AlbumArt.width + widgetWidth / 20, x + widgetWidth, y + (3.25 * ID3AlbumArt.height) / 4.0, (int) widgetHeight, (int)(widgetHeight / 4.0));
        wave.setTimeOffset(18);
        wave.setAmpBoost(0.21);
        wave.setAlpha(0);
        wave.setDelta(-15);
        wave.setSmooth(0.25);
      
        /* Spectrum visualizer. */
        spectrum = new AudioSpectrumVisualizer(x + ID3AlbumArt.width + widgetWidth / 20, x + widgetWidth, y + ID3AlbumArt.height / 1.5, y + widgetHeight, 6, 90, false);
        // spectrum = new AudioSpectrumVisualizer(x + ID3AlbumArt.width + widgetWidth / 20, x + widgetWidth, y + ID3AlbumArt.height / 1.5, y + widgetHeight, 6, 30, false);
        spectrum.setSmooth(0.85);
        spectrum.setAmpBoost(0.25);
        spectrum.section(spectrumRanges);
        spectrum.setSensitivities(spectrumBoost);   
        spectrum.setDividerWidth((int) (widgetWidth / 150.0));
        // spectrum.setDividerWidth((int) (widgetWidth / 100.0));
        spectrum.setDelta(15);
    }
    
    void draw()
    {   
        // scale(0.5);
        image(ID3AlbumArt, x, y);
        
        /* Metadata. */
        drawMetaData();
        
        /* Visualization. */
        drawVisualization();
            
        /* Control. */
        if (input instanceof AudioPlayer)
            drawControl(); 
        
        mouseOver();
    }
    
    void drawVisualization()
    {
        if (spectrum.isFading() && wave.isFading())
        {
            spectrum.draw(imageBuffer, tintBuffer);
            wave.draw();
        }
        else if (visMode == States.AUDIO_SPECTRUM)
            spectrum.draw(imageBuffer, tintBuffer);
        else if (visMode == States.AUDIO_WAVEFORM)
            wave.draw();
    }
    
    void drawMetaData()
    {
        textFont(meiryo, 12);
        textAlign(LEFT, TOP);

        /* Title. */ 
        title.draw();
                
        /* Artist. */
        artist.draw();       
    }
     
    void drawControl()
    {
        previous.draw(); 
        forward.draw(); 
        if (barMode == States.BAR_SEEK)
        {
            float currentMillisPos = ((AudioPlayer) in).position();
            seek.draw();
            seekBar.setCurrentValue(currentMillisPos);
            seekBar.draw();
            
            /* Draw seek bar text. */
            int sec  = (int) (currentMillisPos / 1000) % 60 ;
            int min  = (int) ((currentMillisPos / (1000*60)) % 60);
            int hr   = (int) ((currentMillisPos / (1000*60*60)) % 24);
            
            textFont(centuryGothic, barFontSize);
            text(String.format("%02d:%02d:%02d", hr, min, sec)+" / "+songLength, seekBar.getX(), seek.getY() + textAscent() * .75);
        }
        else
        {
            vol.draw();
            volBar.draw();
            
            /* Draw volume bar text. */
            textFont(centuryGothic, barFontSize);
            text(String.format("%.2f", ((AudioPlayer) input).getGain())+" dB", volBar.getX(), seek.getY() + textAscent() * .75);          
        }
        
        if ( !((AudioPlayer) input).isPlaying() )
        {
            if (play.mouseOver())
                play.highlight();
            else
                play.dim();
            play.draw();
        }
        else
        {        
            if (pause.mouseOver())
                pause.highlight();
            else
                pause.dim();
            pause.draw();
        }
        
        if (stop.mouseOver())
            stop.highlight();
        else
            stop.dim();
            
        stop.draw();
       
        repeat.draw();
        shuffle.draw();
    }
        
    String getFileName(String filePath)
    {
        StringBuffer helper = new StringBuffer();
        helper.append(filePath);   
        return filePath.substring(helper.lastIndexOf("\\") + 1, helper.lastIndexOf("."));
    }
    
    void generateID3AlbumArt()
    {
        /* Currently in player mode. Grab ID3Image if available. */
        if (input instanceof AudioPlayer)
        {
            ID3AlbumArt = getAlbumArt(getCurrentSong());
            if (ID3AlbumArt == null)
                ID3AlbumArt = defaultArt;
            ID3AlbumArt.resize((int) widgetHeight, (int) widgetHeight);
        }
        /* In input mode, load default image. */
        else if (defaultArt != null)
            ID3AlbumArt = defaultArt;
        /* No default art, create one. */
        else
        {
            defaultArt = createImage((int) widgetHeight, (int) widgetHeight, ARGB);
            defaultArt.loadPixels();
            for(int i = 0; i < defaultArt.pixels.length; i++)
                defaultArt.pixels[i] = color(50, 125);
            defaultArt.updatePixels();
            ID3AlbumArt = defaultArt; 
        }
    }
    
    void generateMetaData()
    {    
        float startX = x + ID3AlbumArt.width + widgetWidth / 20;
        float endX = x + widgetWidth - startX;
        
        titleFontSize = (int) (widgetHeight / 3.5);
        artistFontSize = (int) (widgetHeight / 6.0);
        
        if (input instanceof AudioPlayer)
        {
            float songMaxLength = ((AudioPlayer) input).length();
            int songSec  = (int)((songMaxLength / 1000) % 60) ;
            int songMin  = (int)((songMaxLength / (1000 * 60)) % 60);
            int songHr   = (int)((songMaxLength / (1000 * 60 * 60)) % 24);
            
            songLength = String.format("%02d:%02d:%02d", songHr, songMin, songSec);
            seekBar.setMaxValue(songMaxLength);
            
            metaData = ((AudioPlayer) input).getMetaData();
            /* Generate metadata for song title. */
            if (metaData.title().length() != 0)
                title = new ScrollingText(startX, y, endX, meiryo, titleFontSize, metaData.title());
            else
                title = new ScrollingText(startX, y, endX, meiryo, titleFontSize, getFileName(metaData.fileName()));
            
            /* Generate metadata for song artist. */  
            if (metaData.author().length() != 0)
                artist = new ScrollingText(startX, y + textAscent() + textDescent() / 2, endX, meiryo, artistFontSize, metaData.author());
            else
                artist = new ScrollingText(startX, y + textAscent() + textDescent() / 2, endX, meiryo, artistFontSize, "unknown");
        }
        else
        {
            title = new ScrollingText(startX, y, endX, meiryo, titleFontSize, "input");
            artist = new ScrollingText(startX, y + textAscent() + textDescent() / 2, endX, meiryo, artistFontSize, "audio input");
        }
            
        /* Set default scroll options. */
        title.setScrollSpeed(0.25);
        title.setScrollPause(5);
        artist.setScrollSpeed(0.25);
        artist.setScrollPause(5);
    }


    public void mouseOver()
    {
        if (visMode == States.AUDIO_SPECTRUM)
            spectrum.mouseOver();
        else
            wave.mouseOver();
        
        /* Mouse over 'seek' button. */
        if (barMode == States.BAR_SEEK && seek.mouseOver())
            seek.highlight();
        else
            seek.dim();
        
        /* Mouse over 'vol.' button. */
        if (barMode == States.BAR_VOL && vol.mouseOver())
            vol.highlight();
        else
            vol.dim();
        
        /* Mouse over '<<' button. */
        if (previous.mouseOver())
            previous.highlight();
        else
            previous.dim();
        
        /* Mouse over '>>' button. */
        if (forward.mouseOver())
            forward.highlight();
        else
            forward.dim();
            
        /* Mouse over 'repeat' button. */
        if (repeat.mouseOver())
            repeat.highlight();
        else
            repeat.dim();
        
        /* Mouse over 'shuffle' button. */
        if (shuffle.mouseOver())
            shuffle.highlight();
        else
            shuffle.dim();
    }
    
    void registerClick()
    {
        if (mouseButton == LEFT)
        {
            if (spectrum.mouseOver() && visMode == States.AUDIO_SPECTRUM && !spectrum.isFading() && !wave.isFading())
            {
                spectrum.fade();
                wave.fade();
                visMode = States.AUDIO_WAVEFORM;
            }
            else if (wave.mouseOver() && visMode == States.AUDIO_WAVEFORM && !spectrum.isFading() && !wave.isFading())
            {  
                spectrum.fade();
                wave.fade();
                visMode = States.AUDIO_SPECTRUM;
            }
            /* Previous song. */
            else if (previous.mouseOver())
            {
                loadPrevSong();
            }
            /* Next song. */
            else if (forward.mouseOver())
            {
                loadNextSong();
            }
            else if (play.mouseOver() && input instanceof AudioPlayer && !((AudioPlayer) input).isPlaying())
            {
                /* Hack to check if song is over but not paused. Minim doesn't have proper working functionality to detect this. */
                if ( !manualPlayerPause )
                    ((AudioPlayer) input).rewind();
                ((AudioPlayer) input).play();
                manualPlayerPause = false;
            }
            else if (pause.mouseOver() && input instanceof AudioPlayer)
            {
                ((AudioPlayer) input).pause();
                manualPlayerPause = true;
            }
            else if (stop.mouseOver() && input instanceof AudioPlayer)
            {
                 ((AudioPlayer) input).pause();
                 ((AudioPlayer) input).rewind();
                 manualPlayerPause = true;
            }
            /* Clicked on seek/vol, switch states. */
            else if (seek.mouseOver() || vol.mouseOver())
            {
                if (barMode == States.BAR_SEEK)
                    barMode = States.BAR_VOL;
                else
                    barMode = States.BAR_SEEK;
            }
            /* Clicked on bar, calculate position/volume to seek to. */
            else if (input instanceof AudioPlayer && mouseX >= seekBar.getX() && mouseX <= seekBar.getX() + seekBar.getWidth() &&
                         mouseY >= seekBar.getY() - seekBar.getHeight() * 2 && mouseY <= seekBar.getY() + seekBar.getHeight() * 2)
            {
                float percent = (mouseX - seekBar.getX()) / seekBar.getWidth();
                /* Seek bar. */
                if ( barMode == States.BAR_SEEK )
                    ((AudioPlayer) input).cue((int) (percent * ((AudioPlayer) input).length()));
                /* Volume bar. */
                else
                {
                    float newGain = 94 * percent - 80;
                    ((AudioPlayer) input).setGain(newGain);
                    volBar.setCurrentValue(newGain + 80);
                    volume = newGain;
                }
            }
        }
    }
}
