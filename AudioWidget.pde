/*
 *  class: AudioWidget
 *  A graphical widget that interfaces with audio.
 *  Displays visualizations, metadata, etc.
 */

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
    
    /* Add text buttons. */
    
    PImage ID3AlbumArt;
 
    AudioWidget(float startX, float startY, float endX, float endY, AudioSource input)
    {
        
        x = startX;
        y = startY;
        widgetWidth = endX - startX;
        widgetHeight = endY - startY;
        this.input = input;
        
        generateID3AlbumArt();
        
        /*
        wave = new ScrollingAudioWaveform(width / 6.0, (5.0 * width) / 6.0, height / 2.0, height, height / 3);
        wave.listen(in);
        wave.setTimeOffset(18);
            
        spectrum = new AudioSpectrumVisualizer(0, width, 0, height, 3, 30, false);
        spectrum.listen(in);
        spectrum.setSmooth(0.85);
        spectrum.section(spectrumRanges);
        spectrum.setSensitivities(spectrumBoost);   
        spectrum.setDividerWidth(3);
        */
    }
    
    void initVisualizations(int[] spectrumRanges, float[] spectrumBoost)
    {
        
    }
    
    void draw()
    {
        image(ID3AlbumArt, x, y);
    }
    
    void generateID3AlbumArt()
    {
        /* Currently in player mode. Grab ID3Image if available. */
        if (in instanceof AudioPlayer)   
            ID3AlbumArt = getAlbumArt(getCurrentSong());
        /* In input mode, generate default image. */
        else
            ID3AlbumArt = new PImage(64, 64);    
    }

}
