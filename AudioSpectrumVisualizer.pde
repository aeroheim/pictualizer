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
    float[] sensitivities;
    
    int[] amps;
    int[] freqRanges;
    int numSections;   
    int dividerWidth;
    int barWidth;
    boolean display;

    AudioSpectrumVisualizer(float beginX, float endX, float beginY, float endY, int numSections, int numBars)
    {
        /* Initialize display values. */
        spectrumX = beginX;
        spectrumY = endY;
        spectrumWidth = endX - beginX;
        maxSpectrumHeight = endY - beginY;
        display = true;
        
        /* Initialize default values for adjustable variables. */
        this.numSections = numSections;
        dividerWidth = 0;
        SMOOTH_CONST = 0.0;
        AMP_BOOST = 1.0;
        
        /* Initialize the sensitivity array. */
        sensitivities = new float[numSections];
        for(int i = 0; i < sensitivities.length; i++)
            sensitivities[i] = 1.0;
        
        /* Initialize the FFT-amps array. */
        setNumBars(numBars);
            
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
    
    void section(int[] freqRanges)
    {
        numSections = freqRanges.length;
        this.freqRanges = new int[freqRanges.length];
        for(int i = 0; i < freqRanges.length; i++)
            this.freqRanges[i] = freqRanges[i];
    }
    
    void draw()
    {
        if ( display )
        {
            fft.forward(input.mix);
            for(int i = 0; i < amps.length; i++)
            {
                int divider = i % (amps.length / numSections);
                print("i is : "+i+"\n");
                print("divider is: "+divider+"\n");
                float freqRange = freqRanges[divider] * numSections;
                float ampMultiplier = AMP_BOOST * sensitivities[divider] * maxSpectrumHeight;
                // EXPLOIT INTEGER DIVISION TO GET YOUR CORRECT SENSITIVITY INDEX; I THINK IT WILL WORK
                amps[i] = (int) checkAmpHeight(smoothAmp(amps[i], ampMultiplier * modifyAmp(fft.calcAvg(freqRange * divider, freqRange * (divider + 1)))));
                fill(255, 255, 255);
                rect(spectrumX + (spectrumWidth / amps.length) * i, spectrumY, barWidth - dividerWidth, -amps[i]);
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
     * Check if the amp is within range. If not, return the corresponding bounded range value.
     */
    float checkAmpHeight(float amp)
    {
        if ( abs(amp) > maxSpectrumHeight )
            return maxSpectrumHeight;
        else if ( abs(amp) < 0 )
            return 0;
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
    
    void setRanges(int[] freqRanges)
    {
        this.freqRanges = new int[freqRanges.length];
        for(int i = 0; i < freqRanges.length; i++)
            this.freqRanges[i] = freqRanges[i];
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
    
    void setSensitivity(int section, float sensitivity)
    {
        sensitivities[section] = sensitivity;
    }
    
    void setSensitivities(float[] sensitivities)
    {
        this.sensitivities = new float[sensitivities.length];
        for(int i = 0; i < sensitivities.length; i++)
            this.sensitivities[i] = sensitivities[i]; 
    }
    
    void setAmpBoost(float AMP_BOOST)
    {
        this.AMP_BOOST = AMP_BOOST; 
    }
    
   /*
    *  standard getters/accessors
    */
    
    float getSensitivity(int section)
    {
        return sensitivities[section];
    }
    
    float[] getSensitivities()
    {
        return sensitivities; 
    }
    
    float getAmpBoost()
    {
        return AMP_BOOST; 
    }
}
