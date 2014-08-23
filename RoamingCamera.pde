
import java.util.Random;

private static final CameraPanningStyle[] CAMERA_PANNING_STYLES = CameraPanningStyle.values();
private static final VerticalPanningStyle[] VERTICAL_PANNING_STYLES = VerticalPanningStyle.values();
private static final HorizontalPanningStyle[] HORIZONTAL_PANNING_STYLES = HorizontalPanningStyle.values();
private static final DiagonalPanningStyle[] DIAGONAL_PANNING_STYLES = DiagonalPanningStyle.values();

private static final Random PANNING_RNG = new Random();

public static final float MIN_SCALE_RANGE = 0.25;
public static final float MAX_SCALE_RANGE = 0.35;

CameraPanningStyle cameraPanningStyle;
CameraPanningStyle prevCameraPanningStyle;

VerticalPanningStyle verticalPanningStyle;
HorizontalPanningStyle horizontalPanningStyle;
DiagonalPanningStyle diagonalPanningStyle;

public static final float MIN_CAMERA_SPEED = 0.10;
public static final float MID_CAMERA_SPEED = 0.15;
public static final float MAX_CAMERA_SPEED = 0.25;
public static final float FADE_DURATION = 1.0;

float cameraDX;
float cameraDY;
float cameraX;
float cameraY;

float scale;
int tint;

CameraFadeState fadeState;
float fadeDuration;
float fadeSpeed;

/*
 *  Basic init function.
 */
void initRoamingCamera()
{
    tint = 0;
    setFadeDuration(FADE_DURATION);
    resetCameraPanning();
}

/*
 *  Main function that moves the roaming camera around.
 */
public void roam(PImage img)
{  
    cameraX += cameraDX;
    cameraY += cameraDY;
  
    if (cameraAtFadeOutZone())
        fadeState = CameraFadeState.FADE_OUT;
    
    if (cameraAtBoundary())
    {
        // println("camera at boundary");
        resetCameraPanning();
    }
        
    if (fadeState != CameraFadeState.NO_FADE)
        fade();
}

/*
 *  Determines if the camera has reached any of the edges of the img.
 */
public boolean cameraAtBoundary()
{
    switch(cameraPanningStyle)
    {
        case VERTICAL:
            return cameraAtVerticalBoundary();
        case HORIZONTAL:
            return cameraAtHorizontalBoundary();
        case DIAGONAL:
            return cameraAtDiagonalBoundary();
        default:
            return false;
    }
}

/*
 *  Returns whether the camera is at the maximum Y coordinate or not. 
 *  This is dependant on the current panning style being used.
 */
public boolean cameraAtVerticalBoundary()
{
    switch(verticalPanningStyle)
    {
        case TOTOP:
            return cameraY >= 0; 
        case TOBOTTOM:
            return cameraY <= (-img.height + floor(height / scale));
        default:
            return false;
    }
}

/*
 *  Returns whether the camera is at the maximum X coordinate or not.
 *  This is dependant on the current panning style being used.
 */
public boolean cameraAtHorizontalBoundary()
{
    switch(horizontalPanningStyle)
    {
        case TOLEFT:
            return cameraX >= 0;
        case TORIGHT:
           return cameraX <= (-img.width + floor(width / scale));
        default:
            return false;
    }
}

/*
 *  Returns whether the camera is at the maximum X/Y coordinate or not.
 *  This is dependant on the current panning style being used.
 */
public boolean cameraAtDiagonalBoundary()
{
    switch(diagonalPanningStyle)
    {
        case TOTOPLEFT:
           return cameraY >= 0 || cameraX >= 0;
        case TOTOPRIGHT:
           return cameraY >= 0 || cameraX <= (-img.width + floor(width / scale));
        case TOBOTTOMLEFT:
           return cameraY <= (-img.height + floor(height / scale)) || cameraX >= 0;
        case TOBOTTOMRIGHT:
           return cameraY <= (-img.height + floor(height / scale)) || cameraX <= (-img.width + floor(width / scale));
        default:
           return false; 
    }
}
 
/*
 *  Determines if the camera needs to fade out based on its coordinates. 
 *  This is dependant on the current panning style being used.
 */
public boolean cameraAtFadeOutZone()
{
    switch(cameraPanningStyle)
    {
        case VERTICAL:
            return cameraAtVerticalFadeOutZone();
        case HORIZONTAL:
            return cameraAtHorizontalFadeOutZone();
        case DIAGONAL:
            return cameraAtDiagonalFadeOutZone();
        default:
            return false;
    }
}

/*
 *  Determines if the camera needs to fade out based on its current Y coordinate.
 *  This is dependant on the current panning style being used.
 */
private boolean cameraAtVerticalFadeOutZone()
{
    switch(verticalPanningStyle)
    {
        case TOTOP:
            return cameraY >= 0 - getYFadeDistance();
        case TOBOTTOM:
            return cameraY <= (-img.height + floor(height / scale)) + getYFadeDistance();
        default:
            return false;
    }
}

/*
 *  Determines if the camera needs to fade out based on its current X coordinate.
 *  This is dependant on the current panning style being used.
 */
private boolean cameraAtHorizontalFadeOutZone()
{
    switch(horizontalPanningStyle)
    {
         case TOLEFT:
             return cameraX >= 0 - getXFadeDistance();
         case TORIGHT:
             return cameraX <= (-img.width + floor(width / scale)) + getXFadeDistance();
         default:
             return false;
    }
}

/*
 *  Determines if the camera needs to fade out based on its current X/Y coordinate.
 *  This is dependant on the current panning style being used.
 */
private boolean cameraAtDiagonalFadeOutZone()
{
    switch(diagonalPanningStyle)
    {
        case TOTOPLEFT:
            return (cameraY >= 0 - getYFadeDistance()) || (cameraX >= 0 - getXFadeDistance());
        case TOTOPRIGHT:
            return (cameraY >= 0 - getYFadeDistance()) || (cameraX <= (-img.width + floor(width / scale)) + getXFadeDistance());
        case TOBOTTOMLEFT:
            return (cameraY <= (-img.height + floor(height / scale)) + getYFadeDistance()) || (cameraX >= 0 - getXFadeDistance());
        case TOBOTTOMRIGHT:
            return (cameraY <= (-img.height + floor(height / scale)) + getYFadeDistance()) || (cameraX <= (-img.width + floor(width / scale)) + getXFadeDistance());
        default:
            return false; 
    }
}


/*
 *  Sets the current fade duration and adjusts the fade speed.
 */
public void setFadeDuration(float newFadeDuration)
{
    fadeDuration = newFadeDuration;
    fadeSpeed = defaultTint / ((fadeDuration / 2) * FRAME_RATE);
}

/*
 *  Gets the current distance from any horizontal edge that fade outs must begin at.
 */
public float getXFadeDistance()
{
    return (ceil(defaultTint / fadeSpeed) * abs(cameraDX)) * scale;
}

/*
 *  Gets the current distance from any vertical edge that fade outs must begin at.
 */
public float getYFadeDistance()
{
    return (ceil(defaultTint / fadeSpeed) * abs(cameraDY)) * scale;
}

/*
 *
 */
public void fade()
{   
    if (fadeState == CameraFadeState.FADE_OUT)
        fadeOut();
    else if (fadeState == CameraFadeState.FADE_IN)
        fadeIn();
}

/*
 *
 */
public void fadeOut()
{
    if ((tint - fadeSpeed) < 0)
    {
        fadeState = CameraFadeState.NO_FADE;
        tint = 0;
    }
    else
        tint -= fadeSpeed;
        
    // println("fadeOut tint: "+tint);
}

/*
 *
 */
public void fadeIn()
{    
    if ((tint + fadeSpeed) > defaultTint)
    {
        fadeState = CameraFadeState.NO_FADE;
        tint = defaultTint;
    }
    else
        tint += fadeSpeed;
    
    // println("fadeIn tint: "+tint);     
}

/*
 *  Insert comment here.
 */
public void resetCameraPanning()
{
    fadeState = CameraFadeState.FADE_IN;
    
    prevCameraPanningStyle = cameraPanningStyle;
    
    do
        cameraPanningStyle = getNextCameraPanningStyle();
    while(cameraPanningStyle == prevCameraPanningStyle);
  
    switch(cameraPanningStyle)
    {
        case VERTICAL:
            resetVerticalPanning();
            break;
        case HORIZONTAL:
            resetHorizontalPanning();
            break;
        case DIAGONAL:
            resetDiagonalPanning();        
            break;      
    }
}

/*
 *  Resets the vertical camera panning.
 */
public void resetVerticalPanning()
{
    verticalPanningStyle = getNextVerticalPanningStyle();
    
    scale = getNextVerticalPanningScale();

    float maxXPosition = abs(-img.width + floor(width / scale));
    
    cameraX = maxXPosition == 0 ? 0.0 : -PANNING_RNG.nextInt((int) maxXPosition);
    cameraDX = 0.0;
    
    switch(verticalPanningStyle)
    {    
        case TOTOP:
            cameraY = (-img.height + floor(height / scale));
            cameraDY = MAX_CAMERA_SPEED;
            break;
        case TOBOTTOM:
            cameraY = 0;
            cameraDY = -MAX_CAMERA_SPEED;
            break;
    }
}

/*
 *  Resets the horizontal camera panning.
 */
public void resetHorizontalPanning()
{
    horizontalPanningStyle = getNextHorizontalPanningStyle();
    
    scale = getNextHorizontalPanningScale();
    
    float maxYPosition = abs(-img.height + floor(height / scale));
    
    cameraY = maxYPosition == 0 ? 0.0 : -PANNING_RNG.nextInt((int) maxYPosition);
    cameraDY = 0.0;
    
    switch(horizontalPanningStyle)
    {
        case TOLEFT:
            cameraX = (-img.width + floor(width / scale));
            cameraDX = MAX_CAMERA_SPEED;
            break;
        case TORIGHT:
            cameraX = 0.0;
            cameraDX = -MAX_CAMERA_SPEED;
            break;
    }
}

/*
 *  Resets the diagonal camera panning.
 */
public void resetDiagonalPanning()
{
    diagonalPanningStyle = getNextDiagonalPanningStyle();
    
    scale = getNextDiagonalPanningScale();    
    
    switch(diagonalPanningStyle)
    {
        case TOTOPLEFT:
            cameraX = (-img.width + floor(width / scale));
            cameraY = (-img.height + floor(height / scale));
            cameraDX = img.width > img.height ? MAX_CAMERA_SPEED : PANNING_RNG.nextFloat() * (MID_CAMERA_SPEED - MIN_CAMERA_SPEED) + MIN_CAMERA_SPEED;
            cameraDY = img.width <= img.height ? MAX_CAMERA_SPEED : PANNING_RNG.nextFloat() * (MID_CAMERA_SPEED - MIN_CAMERA_SPEED) + MIN_CAMERA_SPEED;
            break;
        case TOTOPRIGHT:
            cameraX = 0.0;
            cameraY = (-img.height + floor(height / scale));
            cameraDX = img.width > img.height ? -MAX_CAMERA_SPEED : -(PANNING_RNG.nextFloat() * (MID_CAMERA_SPEED - MIN_CAMERA_SPEED) + MIN_CAMERA_SPEED);
            cameraDY = img.width <= img.height ? MAX_CAMERA_SPEED : PANNING_RNG.nextFloat() * (MID_CAMERA_SPEED - MIN_CAMERA_SPEED) + MIN_CAMERA_SPEED;
            break;
        case TOBOTTOMLEFT:
            cameraX = (-img.width + floor(width / scale));
            cameraY = 0.0;
            cameraDX = img.width > img.height ? MAX_CAMERA_SPEED : PANNING_RNG.nextFloat() * (MID_CAMERA_SPEED - MIN_CAMERA_SPEED) + MIN_CAMERA_SPEED;
            cameraDY = img.width <= img.height ? -MAX_CAMERA_SPEED : -(PANNING_RNG.nextFloat() * (MID_CAMERA_SPEED - MIN_CAMERA_SPEED) + MIN_CAMERA_SPEED);
            break;
        case TOBOTTOMRIGHT:
            cameraX = 0.0;
            cameraY = 0.0;
            cameraDX = img.width > img.height ? -MAX_CAMERA_SPEED : -(PANNING_RNG.nextFloat() * (MID_CAMERA_SPEED - MIN_CAMERA_SPEED) + MIN_CAMERA_SPEED);
            cameraDY = img.width <= img.height ? -MAX_CAMERA_SPEED : -(PANNING_RNG.nextFloat() * (MID_CAMERA_SPEED - MIN_CAMERA_SPEED) + MIN_CAMERA_SPEED);
            break;
    }
}

/*
 *  Returns a new vertical panning scale generated by the RNG.
 */
private float getNextVerticalPanningScale()
{  
    // If the ratio of height to width is large enough, we can directly use the minimum scale without scaling any further for fade pixels.
    float minScale = ((float) img.width / img.height) <= 0.75 ? getMinimumScale() : getMinimumScale() + MIN_SCALE_RANGE;
    float maxScale = minScale + MAX_SCALE_RANGE;
    
    return PANNING_RNG.nextFloat() * (maxScale - minScale) + minScale;
}

/*
 *  Returns a new horizontal panning scale generated by the RNG.
 */
private float getNextHorizontalPanningScale()
{   
    // If the ratio of the width to height is large enough, we can directly us the minimum scale without scaling any further for fade pixels.
    float minScale = img.width > img.height * 2 ? getMinimumScale() : getMinimumScale() + MIN_SCALE_RANGE;
    float maxScale = minScale + MAX_SCALE_RANGE;
        
    return PANNING_RNG.nextFloat() * (maxScale - minScale) + minScale;     
}

/*
 *  Returns a new diagonal panning scale generated by the RNG.
 */
private float getNextDiagonalPanningScale()
{
    float minScale = getMinimumScale() + MAX_SCALE_RANGE;
    float maxScale = minScale + MIN_SCALE_RANGE;
    
    return PANNING_RNG.nextFloat() * (maxScale - minScale) + minScale; 
}

/*
 *  Obtains the minimum scaling needed to fit the img within the window.
 */
private float getMinimumScale()
{
    float minVerticalScale = (float) height / img.height;
    float minHorizontalScale = (float) width / img.width;
    
    return minVerticalScale > minHorizontalScale ? minVerticalScale : minHorizontalScale;
}

/*
 *  Helper function to obtain the next camera panning style to be used.
 */
private CameraPanningStyle getNextCameraPanningStyle()
{
    return CAMERA_PANNING_STYLES[PANNING_RNG.nextInt(CAMERA_PANNING_STYLES.length)];
}

/*
 *  Helper function to obtain the next vertical panning style to be used.
 */
private VerticalPanningStyle getNextVerticalPanningStyle()
{
    return VERTICAL_PANNING_STYLES[PANNING_RNG.nextInt(VERTICAL_PANNING_STYLES.length)]; 
}

/*
 *  Helper function to obtain the next horizontal panning style to be used.
 */
private HorizontalPanningStyle getNextHorizontalPanningStyle()
{
    return HORIZONTAL_PANNING_STYLES[PANNING_RNG.nextInt(HORIZONTAL_PANNING_STYLES.length)]; 
}

/*
 *  Helper function to obtain the next diagonal panning style to be used.
 */
private DiagonalPanningStyle getNextDiagonalPanningStyle()
{
    return DIAGONAL_PANNING_STYLES[PANNING_RNG.nextInt(DIAGONAL_PANNING_STYLES.length)]; 
}


