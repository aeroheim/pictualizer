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
 
    AudioWidget(float startX, float startY, float endX, float endY)
    {
        
        x = startX;
        y = startY;
        widgetWidth = endX - startX;
        widgetHeight = endY - startY;
        
        generateID3AlbumArt();
        generateMetaData();
        
        int[] spectrumRanges = new int[] {200, 450, 900, 1350, 1800, 2400};
        float[] spectrumBoost = new float[] {0.1, 0.1, 0.1, 0.1, 0.1, 0.1};
        
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
        wave = new ScrollingAudioWaveform(x + ID3AlbumArt.width + widgetWidth / 20, x + widgetWidth, y + (3.0 * ID3AlbumArt.height) / 4.0, (int) widgetHeight, (int)(widgetHeight / 3.0));
        wave.setTimeOffset(18);
        wave.setAmpBoost(0.2);
      
        /* Spectrum visualizer. */
        spectrum = new AudioSpectrumVisualizer(x + ID3AlbumArt.width + widgetWidth / 20, x + widgetWidth, y + ID3AlbumArt.height / 2.0, y + widgetHeight, 3, 30, false);
        spectrum.setSmooth(0.85);
        spectrum.section(spectrumRanges);
        spectrum.setSensitivities(spectrumBoost);   
        spectrum.setDividerWidth(5); 
    }
    
    void draw()
    {   
        image(ID3AlbumArt, x, y);
        drawMetaData();
        // wave.draw();
        spectrum.draw(imageBuffer, tintBuffer);
    }
    
    void drawMetaData()
    {
        textFont(meiryo, 64);
        textAlign(LEFT, TOP);
        /* Draw related metadata if in player mode. */
        if (input instanceof AudioPlayer && metaData != null)
        {
            /* Title. */
            title.draw();
                
            /* Artist. */
            float displacement = textDescent();
            textFont(meiryo, 24);
            if (metaData.author().length() != 0)
                text(metaData.author(), x + ID3AlbumArt.width + widgetWidth / 20, y + displacement * 2.8);
            else
                text("unknown", x + ID3AlbumArt.width + widgetWidth / 20, y + displacement * 2.8);               
        }
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
            ID3AlbumArt.resize((int) widgetHeight, (int) widgetHeight);
        }
        /* In input mode, generate default image. */
        else
            ID3AlbumArt = new PImage((int) widgetHeight, (int) widgetHeight);    
    }
    
    void generateMetaData()
    {    
        float xPos = x + ID3AlbumArt.width + widgetWidth / 20;
        if (input instanceof AudioPlayer)
        {
            metaData = ((AudioPlayer) input).getMetaData();
            if (metaData.title().length() != 0)
                title = new ScrollingText(metaData.title(), meiryo, 64, xPos, x + widgetWidth - xPos, y);
            else
                title = new ScrollingText(getFileName(metaData.fileName()), meiryo, 64, xPos, x + widgetWidth - xPos, y);
        }
        else
            title = new ScrollingText("input mode", meiryo, 64, xPos, x + widgetWidth - xPos, y);
            
        /* Set default scroll options. */
        title.setScrollSpeed(0.5);
        title.setScrollPause(5);
    }
    
    void drawScrollingTitle()
    {
        
    }

}
