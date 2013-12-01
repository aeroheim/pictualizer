/*
 *  class: AudioSpectrumVisualizer
 *  visualizes an audio spectrum using FFT data from
 *  an AudioSource.
 */

class AudioSpectrumVisualizer
{
    AudioSource input;
    FFT fft;
    
    float SMOOTH_CONST;
    float spectrumX;
    float spectrumY;
    float spectrumWidth;
    float maxSpectrumHeight;
    
    float AMP_BOOST;
    float[] sensitivity;
    
    int[] ranges;
    int[] amps;
    int dividerWidth;
    int barWidth;
    boolean display;

    AudioSpectrumVisualizer(float beginX, float endX, float beginY, float endY, int numBars)
    {
        /* Initialize display values. */
        spectrumX = beginX;
        spectrumY = endY;
        spectrumWidth = endX - beginX;
        maxSpectrumHeight = endY - beginY;
        display = true;
        
        /* Initialize default values for adjustable variables. */
        dividerWidth = 0;
        SMOOTH_CONST = 0.0;
        bass = 1.0;
        mid = 1.0;
        hi = 1.0;
        AMP_BOOST = 1.0;
        
        /* Initialize the FFT-amps array. */
        amps = new int[numBars];
        for(int i = 0; i < amps.length; i++)
            amps[i] = 0;
            
        barWidth = (int) (spectrumWidth / amps.length) - dividerWidth;
    }

    void toggleDraw()
    {
        display = !display; 
    }       
    
    void listen(AudioSource input)
    {
        this.input = input;
        fft = new FFT(input.bufferSize(), input.sampleRate());
        fft.window(FFT.HAMMING);
    }
    
    void resize(float beginX, float endX, float beginY, float endY)
    {
        spectrumX = beginX;
        spectrumY = beginY;
        spectrumWidth = endX - beginX;
        maxSpectrumHeight = endY - beginY;
        barWidth = (int) (spectrumWidth / amps.length) - dividerWidth;
    }
    
    void draw()
    {
        if ( display )
        {
            fft.forward(input.mix);
            int fftBassRange = (bassRange * 3) / amps.length;
            int fftMidRange = bassRange + ((midRange - bassRange)* 3) / amps.length;
            int fftHiRange = midRange + (hiRange * 3) / amps.length;
            for(int i = 0; i < amps.length; i++)
            {
                int divider = i % (amps.length / 3); 
                if ( i < (amps.length / 3) )
                    amps[i] = smoothAmp(amps[i], modifyAmp(fft.calcAvg(fftBassRange * divider, fftBaseRange * (divider + 1)
            }
        } 
    }
    
    /* 
     * Add any modifiers to the sample in here.
     * Current modifiers: log()/log(2)
     */
    float modifyAmp(float amp)
    {
        return log(amp) / log(2);
    }
    
    /*
     * Check if the amp is within max height range. If not, return the max height allowed instead.
     */
    float checkAmpHeight(float amp)
    {
        if ( abs(amp) > maxSpectrumHeight )
            return maxSpectrumHeight;
        return amp;
    }
    
   /*
    * Apply smoothing to the sample based on the SMOOTH_CONST defined.
    * Smoothing is achieved by applying a moving average based on previous
    * and current amp values.
    */
    float smoothAmp(float prevAmp, float newAmp)
    {
        return (prevAmp * SMOOTH_CONST) + newAmp * (1 - SMOOTH_CONST);
    }
    
   /*
    *  standard setters/mutators
    */
    
    void setRange(int bassRange, int midRange, int hiRange)
    {
        this.bassRange = bassRange;
        this.midRange = midRange;
        this.hiRange = hiRange; 
    }
    
    void setNumBars(int numBars)
    {
        amps = new int[numBars];
        for(int i = 0; i < amps.length; i++)
            amps[i] = 0;     
    }
    
    void setDividerWidth(int dividerWidth)
    {
        this.dividerWidth = dividerWidth; 
        barWidth = (int) (spectrumWidth / amps.length) - dividerWidth;
    }
    
    void setSmooth(float SMOOTH_CONST)
    {
        this.SMOOTH_CONST = SMOOTH_CONST; 
    }
    
    void setBass(float bass)
    {
        this.bass = bass; 
    }
    
    void setMid(float mid)
    {
        this.mid = mid; 
    }
    
    void setHi(float hi)
    {
        this.hi = hi; 
    }
    
    void setAmpBoost(float AMP_BOOST)
    {
        this.AMP_BOOST = AMP_BOOST; 
    }
    
   /*
    *  standard getters/accessors
    */
    
    float getBass()
    {
        return bass;
    }
    
    float getMid()
    {
        return mid; 
    }
    
    float getHi()
    {
        return hi; 
    }
    
    float getAmpBoost()
    {
        return AMP_BOOST; 
    }
}
