/*
 *  class: ScrollingAudioWaveform
 *  visualizes an animated audio waveform by scrolling
 *  through the amplitude values of an AudioSource's buffers
 *  at consecutive time intervals.
 */

class ScrollingAudioWaveform
{
    AudioSource input;
    int TIME_OFFSET;
    int HEIGHT_SCALE;  
    float SMOOTH_CONST;
    float AMP_BOOST;
    float waveformX;
    float waveformY;
    float waveformWidth;
    float maxWaveformHeight;
    float maxSampleBuffer;
    float[][] amps;
    boolean display;
    
    int waveColor;
    int alpha;
    int delta;
    boolean fading;
  
    ScrollingAudioWaveform(float beginX, float endX, float centerY, int heightScale, int maxHeight)
    {        
        /* Initialize display values. */
        HEIGHT_SCALE = heightScale;
        waveformX = beginX;
        waveformY = centerY;
        waveformWidth = endX - beginX;
        maxWaveformHeight = maxHeight;
        display = true;
        
        /* Fading. */
        alpha = 255;
        delta = 5;
        fading = false;
        
        /* Initialize default values for adjustable variables. */
        TIME_OFFSET = 1;
        SMOOTH_CONST = 0.0;
        AMP_BOOST = 1.0;
        waveColor = 200;
    }
    
    void toggleDraw()
    {
        display = !display; 
    }
    
    void listen(AudioSource input)
    {
        this.input = input;
        maxSampleBuffer = input.bufferSize();
    }

    void resize(float beginX, float endX, float centerY, int heightScale, int maxHeight)
    {
        HEIGHT_SCALE = heightScale;
        waveformX = beginX;
        waveformY = centerY;
        waveformWidth = endX - beginX;
        maxWaveformHeight = maxHeight;
    }
    
    void draw()
    {
        if ( display )
        {
            if ( alpha != 0 && alpha != 255 )
                alpha += delta;
            else
                fading = false;
                
            stroke(waveColor, alpha);
            
            for(int i = 0; i < amps.length; i++)
            {  
                int offsetPos = (int) amps[i].length * i;
                /* Generate the new audio sample each frame and draw it. */
                if ( i == amps.length - 1 )
                {
                    /* Divide buffer spectrum into individual unit size. */
                    float bufferUnit = round(maxSampleBuffer / amps[i].length);
                    /* Store and draw the audio samples. */
                    for(int j = 0; j < amps[i].length - 1; j++)
                    {
                        /* Rounding occurs due to dealing with floats, therefore handle out of bounds sample requests. */
                        int sampleBuffer = checkSampleRange((int) ((j + 1) * bufferUnit));
                        int prevBuffer = (int) (j * bufferUnit);
    
                        /* Calculate amp for current sample. */
                        amps[i][j] = checkAmpHeight(smoothSample(amps[i][j], modifySample(getAvgSample(prevBuffer, sampleBuffer)) * AMP_BOOST * HEIGHT_SCALE));
             
                        prevBuffer = sampleBuffer;
                        sampleBuffer = checkSampleRange((int) ((j + 2) * bufferUnit));
             
                        /* Calculate amp for next sample. */
                        amps[i][j+1] = checkAmpHeight(smoothSample(amps[i][j + 1], modifySample(getAvgSample(prevBuffer, sampleBuffer)) * AMP_BOOST * HEIGHT_SCALE));
             
                        /* Connect the samples together to form a waveform. */
                        line(waveformX + offsetPos + j, waveformY + (int) amps[i][j], waveformX + offsetPos + j + 1, waveformY + (int) amps[i][j + 1]);
                    }
                }
                /* Propogate the waveform down and draw to simulate animation. */
                else
                {
                    for(int j = 0; j < amps[i].length - 1; j++)
                    {
                        line(waveformX + offsetPos + j, waveformY + (int) amps[i][j], waveformX + offsetPos + j + 1, waveformY + (int) amps[i][j + 1]);
                        /* Propogate values from previous time offset. */
                        amps[i][j] = amps[i + 1][j];
                    }
                }
            }
        }
    }
    
    /*
     * Check if the amp is within max height range. If not, return the max height allowed instead.
     */
    float checkAmpHeight(float amp)
    {
        if ( Float.isInfinite(abs(amp)) )
            return 0;
        else if ( abs(amp) > maxWaveformHeight )
            return maxWaveformHeight;
        return amp;
    }
    
    /*
     * Check if the given sample range is valid. If valid, return it, otherwise return a valid sample range.
     */
    int checkSampleRange(int sample)
    {
        if ( sample >= in.bufferSize() )
            return in.bufferSize() - 1;
        return sample;
    }
    
    /*
     * Return the average value of the samples between the given range.
     */
    float getAvgSample(int low, int high)
    {
        float avgSample = 0.0;
        for(int i = low; i <= high; i++)
        {
            avgSample += in.mix.get(i);
            /*
            if ( i % 2 == 0 )
                avgSample += in.left.get(i);
            else
                avgSample += in.right.get(i);
            */
        }
        avgSample /= (high - low);
        return avgSample;
    }
    
   /*
    * Apply smoothing to the sample based on the SMOOTH_CONST defined.
    * Smoothing is achieved by applying a moving average based on previous
    * and current amp values.
    */
    float smoothSample(float prevAmp, float newAmp)
    {
        return (prevAmp * SMOOTH_CONST) + newAmp * (1 - SMOOTH_CONST);
    }
    
    /* 
     * Add any modifiers to the sample in here.
     */
    float modifySample(float sample)
    {
        return sample;
    }

   /*
    *  standard setters/mutators
    */
    
    void setAmpBoost(float AMP_BOOST)
    {
        this.AMP_BOOST = AMP_BOOST; 
    }
    
    void setTimeOffset(int TIME_OFFSET)
    {
        this.TIME_OFFSET = TIME_OFFSET; 
        
        /* The amps array is sectioned into (width / TIME_OFFSET) slices per offset. */
        amps = new float[TIME_OFFSET][round(waveformWidth / TIME_OFFSET)];
        for(int i = 0; i < amps.length; i++)
            for(int j = 0; j < amps[i].length; j++)
                amps[i][j] = 0.0;
    }
    
    void setSmooth(float SMOOTH_CONST)
    {
        this.SMOOTH_CONST = SMOOTH_CONST; 
    }
    
   /*
    *  standard getters/accessors
    */    
    
    float getAmpBoost()
    {
        return AMP_BOOST;
    }
    
    float getTimeOffset()
    {
        return TIME_OFFSET; 
    }
    
    float getSmoothConst()
    {
        return SMOOTH_CONST; 
    }
    
    /* 
     *  mouse functions
     */
     
    boolean mouseOver()
    {
        if (mouseX >= waveformX && mouseX <= (waveformX + waveformWidth) &&
            mouseY >= (int)(waveformY - maxWaveformHeight) && mouseY <= (int)(waveformY + maxWaveformHeight))
        {
            waveColor = 255;
            return true;
        }
        waveColor = 200;
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
