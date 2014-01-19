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
    
    // Bar seekBar;
    // Bar volBar;
    float barX;
    float barWidth;        
    float barY;
    float barHeight;
    
    float playPauseX;
    float playPauseY;
    float playPauseWidth;
    float playPauseHeight;
    
    float pauseX;
    float pauseWidth;
    
    float stopX;
    float stopY;
    float stopSideLength;
    
    PImage ID3AlbumArt;
    PImage defaultArt;
    
    int titleFontSize;
    int artistFontSize;
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
        
        int[] spectrumRanges = new int[] {200, 450, 900, 1350, 1800, 2400};
        float[] spectrumBoost = new float[] {0.1, 0.1, 0.1, 0.1, 0.1, 0.1};
        
        titleFontSize = (int) (widgetHeight / 3.5);
        artistFontSize = (int) (widgetHeight / 6.0);
        barFontSize = (int) (widgetHeight / 12.0);
        
        /* Text button initialize. */
        previous = new TextButton(meiryo, artistFontSize, "< <", x, y + widgetHeight, 200);
        forward = new TextButton(meiryo, artistFontSize, "> >", x + ID3AlbumArt.width - previous.getWidth(), y + widgetHeight, 200);
        seek = new TextButton(meiryo, artistFontSize, "seek", x + ID3AlbumArt.width + widgetWidth / 20, y + widgetHeight, 200);
        vol = new TextButton(meiryo, artistFontSize, "vol.", x + ID3AlbumArt.width + widgetWidth / 20, y + widgetHeight, 200);
        
        /* Buttons. */         
        playPauseX = x + ID3AlbumArt.width / 2.75;
        playPauseY = y + widgetHeight * 1.09;
        playPauseWidth = x + ID3AlbumArt.width / 2.25 - playPauseX;
        playPauseHeight = y + widgetHeight * 1.19 - playPauseY;
        
        stopX = x + ID3AlbumArt.width / 1.85;
        stopY = y + widgetHeight * 1.1;
        stopSideLength = widgetHeight * 0.08;
        
        pauseX = playPauseX + stopSideLength / 1.5;
        pauseWidth = stopSideLength / 4.0;
        
        
        
        visMode = States.AUDIO_SPECTRUM;
        barMode = States.BAR_SEEK;
        
        volume = 0.0;
        
        /* Bars. */
        barX = seek.getEndX() + seek.getWidth() / 4.0;
        barWidth = x + widgetWidth - barX;
        barY = seek.getY() + seek.getHeight() / 1.4;
        barHeight = seek.getHeight() / 15.0;
        
        initVisualizations(spectrumRanges, spectrumBoost);

        /*   
            spectrum = new AudioSpectrumVisualizer(0, width, 0, height, 3, 30, false);
            spectrum.listen(in);
            spectrum.setSmooth(0.85);
            spectrum.section(spectrumRanges);
            spectrum.setSensitivities(spectrumBoost);   
            spectrum.setDividerWidth(3);
        */
    }
    
    void listen(AudioSource input)
    {
        this.input = input;
        wave.listen(input);
        spectrum.listen(input);
        if (input instanceof AudioPlayer)
            ((AudioPlayer) input).setGain(volume);
    }
    
    void initVisualizations(int[] spectrumRanges, float[] spectrumBoost)
    {
        /* Waveform visualizer. */
        wave = new ScrollingAudioWaveform(x + ID3AlbumArt.width + widgetWidth / 20, x + widgetWidth, y + (3.25 * ID3AlbumArt.height) / 4.0, (int) widgetHeight, (int)(widgetHeight / 4.0));
        wave.setTimeOffset(18);
        wave.setAmpBoost(0.25);
        wave.setAlpha(0);
        wave.setDelta(-15);
        // wave.setSmooth(0.0);
      
        /* Spectrum visualizer. */
        spectrum = new AudioSpectrumVisualizer(x + ID3AlbumArt.width + widgetWidth / 20, x + widgetWidth, y + ID3AlbumArt.height / 2.0, y + widgetHeight, 6, 30, false);
        spectrum.setSmooth(0.85);
        spectrum.section(spectrumRanges);
        spectrum.setSensitivities(spectrumBoost);   
        spectrum.setDividerWidth((int) (widgetWidth / 100.0));
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
            seek.draw();
            drawSeekBar();
        }
        else
        {
            vol.draw();
            drawVolumeBar();
        }
        
        // draw play
        if ( !((AudioPlayer) input).isPlaying() )
        {
            fill(200, 150);
            if (playMouseOver())
                fill(255);
            triangle(playPauseX, playPauseY, 
                     playPauseX, playPauseY + playPauseHeight, 
                     playPauseX + playPauseWidth, playPauseY + playPauseHeight / 2.0);
        }
        else
        {        
            // draw pause
            fill(200, 150);
            if (pauseMouseOver())
                fill(255);
            rect(playPauseX, stopY, pauseWidth, stopSideLength);
            rect(pauseX, stopY, pauseWidth, stopSideLength);
        }
        
        // draw stop
        fill(200, 150);
        if (stopMouseOver())
            fill(255);
        rect(stopX, stopY, stopSideLength, stopSideLength);
    }
    
    void drawSeekBar()
    {   
        /* Draw background seek bar. */
        noStroke();
        fill(200, 35);
        rect(barX, barY, barWidth, barHeight);
        
        /* Draw current seek bar. */
        float currentMillisPos = ((AudioPlayer) in).position();
        float percent = currentMillisPos / ((AudioPlayer) in).length();
        fill(175);
        rect(barX, barY, percent * barWidth, barHeight);
        
        int sec  = (int) (currentMillisPos / 1000) % 60 ;
        int min  = (int) ((currentMillisPos / (1000*60)) % 60);
        int hr   = (int) ((currentMillisPos / (1000*60*60)) % 24);
        
        textFont(centuryGothic, barFontSize);
        text(String.format("%02d:%02d:%02d", hr, min, sec)+" / "+songLength, barX, seek.getY() + textAscent() * .75);
    }
    
    void drawVolumeBar()
    {
        /* Draw background volume bar. */
        noStroke();
        fill(200, 35);
        rect(barX, barY, barWidth, barHeight);
        
        /* Draw current volume bar. */
        float percent = (((AudioPlayer) input).getGain() + 80) / 94;
        fill(175);
        rect(barX, barY, percent * barWidth, barHeight);
        
        textFont(centuryGothic, barFontSize);
        text(((AudioPlayer) input).getGain()+" dB", barX, seek.getY() + textAscent() * .75);          
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
            
            metaData = ((AudioPlayer) input).getMetaData();
            /* Generate metadata for song title. */
            if (metaData.title().length() != 0)
                title = new ScrollingText(metaData.title(), meiryo, titleFontSize, startX, endX, y);
            else
                title = new ScrollingText(getFileName(metaData.fileName()), meiryo, titleFontSize, startX, endX, y);
            
            /* Generate metadata for song artist. */  
            if (metaData.author().length() != 0)
                artist = new ScrollingText(metaData.author(), meiryo, artistFontSize, startX, endX, y + textAscent() + textDescent() / 2);
            else
                artist = new ScrollingText("unknown", meiryo, artistFontSize, startX, endX, y + textAscent() + textDescent() / 2);
        }
        else
        {
            title = new ScrollingText("input", meiryo, titleFontSize, startX, endX, y);
            artist = new ScrollingText("audio input", meiryo, artistFontSize, startX, endX, y + textAscent() + textDescent() / 2);
        }
            
        /* Set default scroll options. */
        title.setScrollSpeed(0.25);
        title.setScrollPause(5);
        artist.setScrollSpeed(0.25);
        artist.setScrollPause(5);
    }


    void mouseOver()
    {
        if (visMode == States.AUDIO_SPECTRUM)
            spectrum.mouseOver();
        else
            wave.mouseOver();
            
        if (barMode == States.BAR_SEEK)
            seek.mouseOver();
        else
            vol.mouseOver();
        
        previous.mouseOver();
        forward.mouseOver();   
    }
    
    boolean playMouseOver()
    {
        if ( !((AudioPlayer) input).isPlaying() &&
            mouseX >= playPauseX && mouseX <= playPauseX + playPauseWidth &&
            mouseY >= playPauseY && mouseY <= playPauseY + playPauseHeight)
            return true;
        return false;  
    }
    
    boolean pauseMouseOver()
    {
        if ( ((AudioPlayer) input).isPlaying() &&
            mouseX >= playPauseX && mouseX <= playPauseX + playPauseWidth &&
            mouseY >= playPauseY && mouseY <= playPauseY + playPauseHeight)
            return true;
        return false;  
    }
    
    boolean stopMouseOver()
    {
        if ( mouseX >= stopX && mouseX <= stopX + stopSideLength &&
             mouseY >= stopY && mouseY <= stopY + stopSideLength)
             return true;
        return false;
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
            else if (playMouseOver())
            {
                /* Hack to check if song is over but not paused. Minim doesn't have proper working functionality to detect this. */
                if ( !manualPlayerPause )
                    ((AudioPlayer) input).rewind();
                ((AudioPlayer) input).play();
                manualPlayerPause = false;
            }
            else if (pauseMouseOver())
            {
                ((AudioPlayer) input).pause();
                manualPlayerPause = true;
            }
            else if (stopMouseOver())
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
            else if (input instanceof AudioPlayer && 
                     mouseX >= barX && mouseX <= barX + barWidth && mouseY >= barY - barHeight * 2 && mouseY <= barY + barHeight * 2)
            {
                float percent = (mouseX - barX) / barWidth;
                /* Seek bar. */
                if ( barMode == States.BAR_SEEK )
                    ((AudioPlayer) input).cue((int) (percent * ((AudioPlayer) input).length()));
                /* Volume bar. */
                else
                {
                    float newGain = 94 * percent - 80;
                    ((AudioPlayer) input).setGain(newGain);
                    volume = newGain;
                }
            }
        }
    }
}
