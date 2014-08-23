/*
 *  class: AudioWidget
 *  A graphical widget that interfaces with audio.
 *  Displays visualizations, metadata, etc.
 */

import java.lang.String;

class AudioWidget extends PGraphicObject
{     
    ScrollingAudioWaveform wave;
    AudioSpectrumVisualizer spectrum;
    
    PAudioPlayer player;
    
    ScrollingText title;
    ScrollingText artist;
    ScrollingText index;
       
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
    
    boolean indexMode;
    
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
 
    AudioWidget(PAudioPlayer player, float pX, float pY, float pWidth, float pHeight)
    {
        
        super(pX, pY, pWidth, pHeight);
        this.player = player;
        
        try {
            int ID3AlbumArtSideLength = (int) (getHeight() * 0.8);
            defaultArt = loadImage("art.png");
            defaultArt.resize(ID3AlbumArtSideLength, ID3AlbumArtSideLength);
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
        
        titleFontSize = (int) (ID3AlbumArt.height / 3.5);
        artistFontSize = (int) (ID3AlbumArt.height / 6.0);
        modeFontSize = (int) (ID3AlbumArt.height / 8.0);
        barFontSize = (int) (ID3AlbumArt.height / 14.0);
                                       
        visMode = States.AUDIO_SPECTRUM;
        barMode = States.BAR_SEEK;
                
        volume = 0.0;
        
        initButtons();
        initBars();              
        initVisualizations(spectrumRanges, spectrumBoost);
    }
    
    void listen(AudioSource input)
    {
        wave.listen(input);
        spectrum.listen(input);
        
        /* Hack; fix later. */
        spectrumVisualizer.listen(input);
        
        beatDetect = new BeatDetect(input.bufferSize(), input.sampleRate());
        beatDetect.setSensitivity(500);
        beatListener = new BeatListener(beatDetect, input);
        
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
        float playX = getX() + ID3AlbumArt.width / 2.6;
        float playY = getY() + ID3AlbumArt.height * 1.1;
        float playWidth = ID3AlbumArt.width / 2.25 - ID3AlbumArt.width / 2.75;
        float playHeight = ID3AlbumArt.height * 0.1;
                
        float stopX = getX() + ID3AlbumArt.width / 1.85;
        float stopY = getY() + ID3AlbumArt.height * 1.11;
        float stopSideLength = ID3AlbumArt.width * 0.08;
        
        float pauseWidth = stopSideLength / 4.0;
        
        float repeatX = getX() + ID3AlbumArt.width + getWidth() / 20;
        float repeatY = getY() + ID3AlbumArt.height * 1.085;
        float repeatWidth = playWidth + 3;
        float repeatHeight = playHeight + 3;
        float repeatRadius = getWidth() / 100;
                             
                      
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
        float shuffleX = repeat.getX() + repeat.getWidth() * 1.5;
        float shuffleY = repeat.getY();
        int shuffleWidth = (int) repeatWidth;
        int shuffleHeight = (int) repeatHeight;
        
        float shuffleHeightOffset = shuffleHeight / 5.0;
        float shuffleArrowOffset = shuffleWidth / 5.0;
        float shuffleMidpoint = (1.5 * shuffleWidth) / 5.0;
        
        PGraphics dimShuffle = createGraphics((int) shuffleWidth, (int) shuffleHeight);
        PGraphics highlightShuffle = createGraphics((int) shuffleWidth, (int) shuffleHeight);
        
        dimShuffle.beginDraw(); dimShuffle.stroke(200, 150); dimShuffle.strokeWeight(shuffleWidth / 15.0); dimShuffle.fill(200, 150);
        dimShuffle.line(0, shuffleHeightOffset, shuffleMidpoint, shuffleHeightOffset);
        dimShuffle.line(shuffleMidpoint, shuffleHeightOffset, shuffleMidpoint + shuffleArrowOffset, shuffleHeight - shuffleHeightOffset);
        dimShuffle.line(shuffleMidpoint + shuffleArrowOffset, shuffleHeight - shuffleHeightOffset, shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeight - shuffleHeightOffset);
        dimShuffle.line(0, shuffleHeight - shuffleHeightOffset, shuffleMidpoint, shuffleHeight - shuffleHeightOffset);
        
        /* Add the groove in the shuffle icon. */
        dimShuffle.line(shuffleMidpoint, shuffleHeight - shuffleHeightOffset, shuffleMidpoint + shuffleArrowOffset / 4, shuffleHeight - shuffleHeightOffset * 1.25);
        dimShuffle.line(shuffleMidpoint + (3 * shuffleArrowOffset) / 4, shuffleHeightOffset * 1.25, shuffleMidpoint + shuffleArrowOffset, shuffleHeightOffset);
                
        dimShuffle.line(shuffleMidpoint + shuffleArrowOffset, shuffleHeightOffset, shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeightOffset);
        
        dimShuffle.noStroke();
        dimShuffle.triangle(shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeightOffset * 0.5,
                            shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeightOffset * 1.5,
                            shuffleWidth, shuffleHeightOffset);      
        dimShuffle.triangle(shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeight - shuffleHeightOffset * 0.5,
                            shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeight - shuffleHeightOffset * 1.5,
                            shuffleWidth, shuffleHeight - shuffleHeightOffset);       
        dimShuffle.endDraw();
        
        highlightShuffle.beginDraw(); highlightShuffle.stroke(255); highlightShuffle.strokeWeight(shuffleWidth / 15.0); highlightShuffle.fill(255);
        highlightShuffle.line(0, shuffleHeightOffset, shuffleMidpoint, shuffleHeightOffset);
        highlightShuffle.line(shuffleMidpoint, shuffleHeightOffset, shuffleMidpoint + shuffleArrowOffset, shuffleHeight - shuffleHeightOffset);
        highlightShuffle.line(shuffleMidpoint + shuffleArrowOffset, shuffleHeight - shuffleHeightOffset, shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeight - shuffleHeightOffset);
        highlightShuffle.line(0, shuffleHeight - shuffleHeightOffset, shuffleMidpoint, shuffleHeight - shuffleHeightOffset);
               
        /* Add the groove in the shuffle icon. */
        highlightShuffle.line(shuffleMidpoint, shuffleHeight - shuffleHeightOffset, shuffleMidpoint + shuffleArrowOffset / 4, shuffleHeight - shuffleHeightOffset * 1.25);
        highlightShuffle.line(shuffleMidpoint + (3 * shuffleArrowOffset) / 4, shuffleHeightOffset * 1.25, shuffleMidpoint + shuffleArrowOffset, shuffleHeightOffset);
        
        highlightShuffle.line(shuffleMidpoint + shuffleArrowOffset, shuffleHeightOffset, shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeightOffset);
        
        highlightShuffle.noStroke();
        highlightShuffle.triangle(shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeightOffset * 0.5,
                            shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeightOffset * 1.5,
                            shuffleWidth, shuffleHeightOffset);      
        highlightShuffle.triangle(shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeight - shuffleHeightOffset * 0.5,
                            shuffleMidpoint + shuffleArrowOffset * 2, shuffleHeight - shuffleHeightOffset * 1.5,
                            shuffleWidth, shuffleHeight - shuffleHeightOffset);
        highlightShuffle.endDraw();
        
        shuffle = new PGraphicsButton(shuffleX, shuffleY, dimShuffle, highlightShuffle);                
    }
    
    private void initBars()
    {
        float barX = seek.getX() + seek.getWidth() * 1.25;
        float barY = seek.getY() + seek.getHeight() / 1.4;
        float barWidth = getX() + getWidth() - barX;
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
        previous = new TextButton(getX(), getY() + ID3AlbumArt.height, meiryo, artistFontSize, "< <");
            previous.setColor(200);
            previous.setDimColor(200);
            previous.setHighlightColor(255);
            
        forward = new TextButton(getX() + ID3AlbumArt.width - previous.getWidth(), previous.getY(), meiryo, artistFontSize, "> >");
            forward.setColor(200);
            forward.setDimColor(200);
            forward.setHighlightColor(255);
            
        seek = new TextButton(shuffle.getX() + shuffle.getWidth() * 1.5, previous.getY(), meiryo, artistFontSize, "seek");
            seek.setColor(200);
            seek.setDimColor(200);
            seek.setHighlightColor(255);
            
        vol = new TextButton(seek.getX(), previous.getY(), meiryo, artistFontSize, "vol.");
            vol.setColor(200);
            vol.setDimColor(200);
            vol.setHighlightColor(255);
        index = new ScrollingText(getX(), getY(), ID3AlbumArt.width, centuryGothic, (int) (ID3AlbumArt.width * 0.9), "00");
            index.setScrollSpeed(0.5);
            index.setScrollPause(3);
    }
    
    void initVisualizations(int[] spectrumRanges, float[] spectrumBoost)
    {
        /* Waveform visualizer. */
        wave = new ScrollingAudioWaveform(getX() + ID3AlbumArt.width + getWidth() / 20, getX() + getWidth(), 
                                          getY() + (3.25 * ID3AlbumArt.height) / 4.0, ID3AlbumArt.height, (int)(ID3AlbumArt.height / 4.0));
        wave.setTimeOffset(14);
        wave.setAmpBoost(0.25);
        wave.setAlpha(0);
        wave.setDelta(-15);
        wave.setSmooth(0.0);
      
        /* Spectrum visualizer. */
        spectrum = new AudioSpectrumVisualizer(getX() + ID3AlbumArt.width + getWidth() / 20, getX() + getWidth(), 
                                               getY() + ID3AlbumArt.height / 1.5, getY() + ID3AlbumArt.height, 6, 90, false);
        // spectrum = new AudioSpectrumVisualizer(getX() + ID3AlbumArt.width + getWidth() / 20, getX() + getWidth(), getY() + ID3AlbumArt.height / 1.5, getY() + getHeight(), 6, 30, false);
        spectrum.setSmooth(0.85);
        spectrum.setAmpBoost(0.5);
        spectrum.section(spectrumRanges);
        spectrum.setSensitivities(spectrumBoost);   
        spectrum.setDividerWidth(floor(getWidth() / 150.0));
        // spectrum.setDividerWidth((int) (getWidth() / 100.0));
        spectrum.setDelta(15);
    }
    
    void draw()
    {   
        // drawBackground();
        // scale(0.5);
        if (indexMode)
            index.draw();
        else
            image(ID3AlbumArt, getX(), getY());
        
        /* Metadata. */
        drawMetaData();
        
        /* Visualization. */
        drawVisualization();
            
        /* Control. */
        if (player.playerMode())
            drawControl(); 
        
        if (mouseOver())
            highlight();             
    }
    
    private void drawBackground()
    {
        float widthOffset = getWidth() / 25.0;
        float heightOffset = getHeight() / 10.0;
        float radii = getWidth() / 10.0;
        fill(0, 100);
        noStroke();
        rect(getX() - widthOffset, getY() - heightOffset, getWidth() + widthOffset * 2, getHeight() + heightOffset * 2,
             radii / 4, radii, radii / 4, radii);
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
        
        /* Hack to check for automatic playing of next song. */
        if (player.checkAutoNext())
        {
            listen(player.getSource());
            widget.generateID3AlbumArt();
            widget.generateMetaData();
            widget.getFileName(player.getPath());
        }
    }
     
    void drawControl()
    {
        previous.draw(); 
        forward.draw(); 
        if (barMode == States.BAR_SEEK)
        {
            float currentMillisPos = player.getSeekPosition();
            seek.draw();
            seekBar.setCurrentValue(currentMillisPos);
            seekBar.draw();
            
            /* Draw seek bar text. */
            int sec  = (int) (currentMillisPos / 1000) % 60 ;
            int min  = (int) ((currentMillisPos / (1000*60)) % 60);
            int hr   = (int) ((currentMillisPos / (1000*60*60)) % 24);
            
            textFont(centuryGothic, barFontSize);
            text(String.format("%02d:%02d:%02d", hr, min, sec)+" / "+songLength, seekBar.getX(), seek.getY() + textAscent());
        }
        else
        {
            vol.draw();
            volBar.draw();
            
            /* Draw volume bar text. */
            textFont(centuryGothic, barFontSize);
            text((volume+" dB"), volBar.getX(), seek.getY() + textAscent());  
            //text(String.format("%.2f", volume+" dB"), volBar.getX(), seek.getY() + textAscent());          
        }
        
        if ( !player.isPlaying() )
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
        int ID3AlbumArtSideLength = (int) (getHeight() * 0.8);
        
        /* Currently in player mode. Grab ID3Image if available. */
        if (player.playerMode())
        {
            ID3AlbumArt = getAlbumArt(player.getPath());
            if (ID3AlbumArt == null)
                ID3AlbumArt = defaultArt;
            ID3AlbumArt.resize(ID3AlbumArtSideLength, ID3AlbumArtSideLength);
        }
        /* In input mode, load default image. */
        else if (defaultArt != null)
            ID3AlbumArt = defaultArt;
        /* No default art, create one. */
        else
        {
            defaultArt = createImage(ID3AlbumArtSideLength, ID3AlbumArtSideLength, ARGB);
            defaultArt.loadPixels();
            for(int i = 0; i < defaultArt.pixels.length; i++)
                defaultArt.pixels[i] = color(50, 125);
            defaultArt.updatePixels();
            ID3AlbumArt = defaultArt; 
        }
    }
    
    void generateMetaData()
    {    
        float startX = getX() + ID3AlbumArt.width + getWidth() / 20;
        float endX = getX() + getWidth() - startX;
        
        titleFontSize = (int) (ID3AlbumArt.height / 3.5);
        artistFontSize = (int) (ID3AlbumArt.height / 6.0);
        
        
        if (player.playerMode())
        {
            float songMaxLength = player.getLength();
            int songSec  = (int)((songMaxLength / 1000) % 60) ;
            int songMin  = (int)((songMaxLength / (1000 * 60)) % 60);
            int songHr   = (int)((songMaxLength / (1000 * 60 * 60)) % 24);
            
            songLength = String.format("%02d:%02d:%02d", songHr, songMin, songSec);
            seekBar.setMaxValue(songMaxLength);
            
            AudioMetaData metaData = player.getMetaData();
            
            /* Update the index display. */
            index.setText(String.format("%02d", player.getIndex() + 1));
            
            /* Generate metadata for song title. */
            if (metaData.title().length() != 0)
                title = new ScrollingText(startX, getY(), endX, meiryo, titleFontSize, metaData.title());
            else
                title = new ScrollingText(startX, getY(), endX, meiryo, titleFontSize, getFileName(metaData.fileName()));
            
            /* Generate metadata for song artist. */  
            if (metaData.author().length() != 0)
                artist = new ScrollingText(startX, getY() + textAscent() + textDescent() / 2, endX, meiryo, artistFontSize, metaData.author());
            else
                artist = new ScrollingText(startX, getY() + textAscent() + textDescent() / 2, endX, meiryo, artistFontSize, "unknown");
        }
        else
        {
            title = new ScrollingText(startX, getY(), endX, meiryo, titleFontSize, "input");
            artist = new ScrollingText(startX, getY() + textAscent() + textDescent() / 2, endX, meiryo, artistFontSize, "audio input");
        }
            
        /* Set default scroll options. */
        title.setScrollSpeed(0.25);
        title.setScrollPause(5);
        artist.setScrollSpeed(0.25);
        artist.setScrollPause(5);
    }

    public void highlight()
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
        else if (!player.isRepeating())
            repeat.dim();
        
        /* Mouse over 'shuffle' button. */
        if (shuffle.mouseOver())
            shuffle.highlight();
        else if (!player.isShuffling())
            shuffle.dim();
    }
    
    void registerClick()
    {
        if (mouseButton == LEFT)
        {
            if (mouseX >= getX() && mouseX <= getX() + ID3AlbumArt.width &&
                mouseY >= getY() && mouseY <= getY() + ID3AlbumArt.height)
            {
                indexMode = !indexMode; 
            }
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
                player.previous();
                listen(player.getSource());
                widget.generateID3AlbumArt();
                widget.generateMetaData();
                widget.getFileName(player.getPath());
            }
            /* Next song. */
            else if (forward.mouseOver())
            {
                player.next();
                listen(player.getSource());
                widget.generateID3AlbumArt();
                widget.generateMetaData();
                widget.getFileName(player.getPath());
            }
            else if (play.mouseOver() && player.playerMode() && !player.isPlaying())
            {
                player.play();
            }
            else if (pause.mouseOver() && player.playerMode())
            {
                player.pause();
            }
            else if (stop.mouseOver() && player.playerMode())
            {
                player.stop();
            }
            else if (repeat.mouseOver() && player.playerMode())
            {
                player.toggleRepeat();
                repeat.highlight();
            }
            else if (shuffle.mouseOver() && player.playerMode())
            {
                player.toggleShuffle(); 
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
            else if (player.playerMode() && mouseX >= seekBar.getX() && mouseX <= seekBar.getX() + seekBar.getWidth() &&
                         mouseY >= seekBar.getY() - seekBar.getHeight() * 2 && mouseY <= seekBar.getY() + seekBar.getHeight() * 2)
            {
                float percent = (mouseX - seekBar.getX()) / seekBar.getWidth();
                /* Seek bar. */
                if ( barMode == States.BAR_SEEK )
                    player.seek((int) (percent * player.getLength()));
                /* Volume bar. */
                else
                {
                    float newGain = 94 * percent - 80;
                    player.setVolume(newGain);
                    volBar.setCurrentValue(newGain + 80);
                    volume = newGain;
                }
            }
        }
    }
}
