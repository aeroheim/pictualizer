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
    
    PImage ID3AlbumArt;
    PImage defaultArt;
    
    States state;
 
    AudioWidget(float startX, float startY, float endX, float endY)
    {
        
        x = startX;
        y = startY;
        widgetWidth = endX - startX;
        widgetHeight = endY - startY;
        
        defaultArt = loadImage("art.png");
        defaultArt.resize((int) widgetHeight, (int) widgetHeight);
        
        generateID3AlbumArt();
        generateMetaData();
        
        int[] spectrumRanges = new int[] {200, 450, 900, 1350, 1800, 2400};
        float[] spectrumBoost = new float[] {0.1, 0.1, 0.1, 0.1, 0.1, 0.1};
        
        state = States.AUDIOSPECTRUM;
        
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
    }
    
    void initVisualizations(int[] spectrumRanges, float[] spectrumBoost)
    {
        /* Waveform visualizer. */
        wave = new ScrollingAudioWaveform(x + ID3AlbumArt.width + widgetWidth / 20, x + widgetWidth, y + (3.25 * ID3AlbumArt.height) / 4.0, (int) widgetHeight, (int)(widgetHeight / 4.0));
        wave.setTimeOffset(18);
        wave.setAmpBoost(0.2);
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
        drawMetaData();
        // wave.draw();
        if (spectrum.isFading() && wave.isFading())
        {
            spectrum.draw(imageBuffer, tintBuffer);
            wave.draw();
        }
        else if (state == States.AUDIOSPECTRUM)
            spectrum.draw(imageBuffer, tintBuffer);
        else if (state == States.AUDIOWAVEFORM)
            wave.draw();
            
        mouseOver();
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
    
    void drawSeekBar()
    {
      
    }
    
    void drawControl()
    {
         
    }
    
    /* Draw the forward/backwards player buttons. */
    private void drawArrow()
    {

    }
    
    private void drawPlay()
    {
      
    }
    
    private void drawPause()
    {
      
    }
    
    private void drawStop()
    {
      
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
        else
            ID3AlbumArt = defaultArt;
    }
    
    void generateMetaData()
    {    
        float startX = x + ID3AlbumArt.width + widgetWidth / 20;
        float endX = x + widgetWidth - startX;
        
        int titleFontSize = (int) (widgetHeight / 3.5);
        int artistFontSize = (int) (widgetHeight / 6.0);
        
        if (input instanceof AudioPlayer)
        {
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
        if (state == States.AUDIOSPECTRUM)
            spectrum.mouseOver();
        else
            wave.mouseOver();
    }
    
    void registerClick()
    {
        if (spectrum.mouseOver() && state == States.AUDIOSPECTRUM && !spectrum.isFading() && !wave.isFading())
        {
            spectrum.fade();
            wave.fade();
            state = States.AUDIOWAVEFORM;
        }
        else if (wave.mouseOver() && state == States.AUDIOWAVEFORM && !spectrum.isFading() && !wave.isFading())
        {  
            spectrum.fade();
            wave.fade();
            state = States.AUDIOSPECTRUM;
        }
    }
}
