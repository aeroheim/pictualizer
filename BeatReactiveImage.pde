
float flashDuration;
float addBeatDelay;

int mainAlpha;
int defaultAlpha;
int minAlpha;
int maxAlpha;

int alpha;
float dAlpha;
boolean isFlashing;

int blurLevel;
PImage blurImg;
PGraphics blurBuffer;

/*
 *  Sets up first time variables for the BeatReactiveImage.
 */
void initBeatReactiveImage(PImage image)
{
    flashDuration = 0.3;
    addBeatDelay = 4.0;
    
    mainAlpha = 185;
    defaultAlpha = 200;
    minAlpha = 25;
    maxAlpha = 275;
    dAlpha = ceil((maxAlpha - minAlpha) / (flashDuration * FRAME_RATE));
    
    blurLevel = 5;
    
    isFlashing = false;
    
    getBeatReactiveImage(image);
}

/*
 *  Obtains a blurred image that can be used to create the BeatReactiveImage.
 */
void getBeatReactiveImage(PImage image)
{
    blurImg = image.get();
    blurImg.filter(BLUR, 5);
    
    blurBuffer = createGraphics(width, height, P2D);
}

/*
 *  Handle BeatReactiveImage logic on beat detects.
 */
void OnBeatDetect()
{
    if (beatDetect.isKick())
    {
        if (!isFlashing)
        {
            isFlashing = true;
            alpha = defaultAlpha;
        }
        // Additional beat detects during the flashing should slightly prolong the current flash transition.
        else
        {
            float tempDAlpha = dAlpha / addBeatDelay;
            
            // If the current alpha is increasing, we lower the alpha by a bit.
            if (dAlpha > 0)
            {
                if (alpha + tempDAlpha > maxAlpha)
                    alpha = maxAlpha;
                else
                    alpha -= tempDAlpha; 
            }
            // If the current alpha is decreasing, we increase the alpha by a bit.
            else
            {
                if (alpha + tempDAlpha < minAlpha)
                    alpha = minAlpha;
                else
                    alpha -= tempDAlpha; 
            }
        }
    }
}

/*
 *  Draw the BeatReactiveImage.
 */
void drawBeatReactiveImage(PGraphics layer)
{
    blurBuffer.beginDraw();
    blurBuffer.clear();
    
    blurBuffer.image(blurImg, imgX, imgY);
   
    blurBuffer.tint(255, alpha);
   
    blurBuffer.endDraw();
    
    flashImage();
    
    layer.image(blurBuffer, 0, 0);
}

/*
 *  Adjusts the alpha values for the BeatReactiveImage.
 */
void flashImage()
{
    if (dAlpha > 0)
    {
        if (alpha + dAlpha > maxAlpha)
        {
            alpha = maxAlpha;
            dAlpha = -dAlpha; 
        }
        else
            alpha += dAlpha;
    }
    else
    {
        if (alpha + dAlpha < minAlpha)
        {
            alpha = minAlpha;
            dAlpha = -dAlpha; 
        }
        else
            alpha += dAlpha;
        
        if (alpha == minAlpha)
            isFlashing = false;
    }
}


