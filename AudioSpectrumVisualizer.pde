/*
 *  class: AudioSpectrumVisualizer
 *  visualizes an audio spectrum using FFT data from
 *  an AudioSource.
 */

class AudioSpectrumVisualizer
{
    AudioSource input;
    FFT fft;
    
    boolean backgroundMode;
    
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
    
    int spectrumColor;
    int alpha;
    int delta;
    boolean fading;


    AudioSpectrumVisualizer(float beginX, float endX, float beginY, float endY, int numSections, int numBars, boolean backgroundMode)
    {
        /* Initialize display values. */
        spectrumX = beginX;
        spectrumY = endY;
        spectrumWidth = endX - beginX;
        maxSpectrumHeight = endY - beginY;
        display = true;
        spectrumColor = 200;
        
        /* Fading. */
        alpha = 255;
        delta = 5;
        fading = false;

        /* Initialize drawing objects. */
        this.backgroundMode = backgroundMode;
        
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
    
    void draw(PGraphics srcBuff, PGraphics destBuff)
    {
        if ( display )
        {  
            noStroke();            
            if ( backgroundMode )
                destBuff.loadPixels();
            
            if ( alpha != 0 && alpha != 255 )
                alpha += delta;
            else
                fading = false;
            
            fft.forward(input.mix);
            float prevFreq = 0;
            for(int i = 0; i < amps.length; i++)
            {
                int section = i / (amps.length / numSections);
                float freqUnit = section > 0 ? ((freqRanges[section] - freqRanges[section - 1]) * numSections) / amps.length : (freqRanges[section] * numSections) / amps.length;
                float currentFreq = prevFreq + freqUnit;
                
                // print("divider: "+ divider +", section: "+ section +"\n");
                // print("prevFreq: "+ prevFreq +", currentFreq: "+ currentFreq +", freqUnit: "+ freqUnit +"\n");
                
                float ampMultiplier = AMP_BOOST * sensitivities[section] * maxSpectrumHeight;
                amps[i] = (int) checkAmpHeight(smoothAmp(amps[i], ampMultiplier * modifyAmp(fft.calcAvg(prevFreq, currentFreq))));
                
                // test text
                if ( backgroundMode )
                {
                    textFont(centuryGothic, width / 200.0);
                    textAlign(LEFT);
                    text(currentFreq+"Hz", spectrumX + (spectrumWidth / amps.length + 1) * i, spectrumY - amps[i] - 2);
                }
                
                prevFreq = currentFreq;
                
                if ( !backgroundMode )
                {
                    fill(spectrumColor, alpha);
                    rect(spectrumX + (spectrumWidth / amps.length) * i, spectrumY, barWidth - dividerWidth, -amps[i]);
                }
                else
                    for(int j = (int) ((maxSpectrumHeight - amps[i] - 1) * spectrumWidth); j < maxSpectrumHeight * spectrumWidth - 1; j += spectrumWidth)
                    {
                        int coordinate = j + ((((int)spectrumWidth / amps.length) + 1) * i);
                        if ( coordinate > (width * height))
                            print("coordinate: "+coordinate+"\n");

                        if ( i == amps.length - 1)
                            System.arraycopy(srcBuff.pixels, coordinate, destBuff.pixels, coordinate, (int) spectrumWidth - (((int)spectrumWidth / amps.length + 1) * i));
                        else
                            System.arraycopy(srcBuff.pixels, coordinate, destBuff.pixels, coordinate, barWidth);

                    }
            }
            if ( backgroundMode )
                destBuff.updatePixels();
            stroke(255);
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
        if ( amp > maxSpectrumHeight )
            return maxSpectrumHeight;
        else if ( amp < 0 )
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
    
    void toggleBackgroundMode()
    {
        backgroundMode = !backgroundMode; 
    }
    
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
    
    /* 
     *  mouse functions
     */
     
     boolean mouseOver()
     {
         if (mouseX >= spectrumX && mouseX <= (spectrumX + spectrumWidth) &&
             mouseY >= spectrumY - maxSpectrumHeight && mouseY <= spectrumY)
         {
             spectrumColor = 255;
             return true;
         }
         spectrumColor = 200;
         return false;
     }
     
     void fade()
     {
         if (alpha == 0 || alpha == 255)
             delta = -delta;
         alpha += delta;
         fading = true;
     }
     
     boolean isFading()
     {
         return fading; 
     }
     
     void setAlpha(int alpha)
     {
         this.alpha = alpha; 
     }
     
     void setDelta(int delta)
     {
         this.delta = delta; 
     }
}
