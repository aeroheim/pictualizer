
private final static float EPSILON = 0.00001;

int imgX;
int imgY;
int framesElapsed;
float imgdX;
float imgdY;
boolean xTransition;
boolean yTransition;


/*
 *  Initialize the default camera values.
 */
public void initCamera()
{
    imgX = 0;
    imgY = 0;
    framesElapsed = 0;
    imgdX = 0.25;
    imgdY = 0.25; 
    xTransition = false;
    yTransition = false;
}

/*
 *  Adjusts the camera positional values to simulate a "roaming" camera on the main image.
 *  FEATURES TO ADD:
 *  - heuristic to determine x/y speeds (make it seem like natural panning instead of an algorithmic one)
 *  - dynamic slowdown when nearing edges (~10-15% img width distance towards any edge?)
 *  - fade in/out at new random location after colliding with edge (preferably in new spot and angles that will roam for a good duration of time)
 *  - allow for scaled out roaming if image is sufficiently large enough (both dimensions at least 30-50% larger than frame dimensions?)
 */
public void roam(PImage image)
{
    /* Verify that the image can be scrolled horizontally. */
    if ((image.width != width))
    {
        if (imgX >= 0 || imgX <= (-image.width + width))
        {
            // print("boundary: "+(-image.width + width)+"\n");
            /* Hit X boundary, reverse direction. */
            if (!xTransition)
            {
                imgdX = -imgdX;
                xTransition = true;
            }
        }
        
        /* Update the X camera position. */
        if (framesElapsed % abs(1 / imgdX) == 0)
        {
            xTransition = false;
            framesElapsed = 0;
            if (imgdX > 0)
                imgX++;
            else if (imgdX < 0)
                imgX--;
        }
    }
    
    /* Verify that the image can be scrolled vertically. */
    if ((image.height != height))
    {
        if (imgY >= 0 || imgY <= (-image.height + height))
        {
            /* Hit Y boundary, reverse direction. */
            if (!yTransition)
            {
                imgdY = -imgdY;
                yTransition = true;
            }     
        }
        /* Update the Y camera position. */
        if (framesElapsed % abs(1 / imgdY) == 0)
        {
            yTransition = false;
            framesElapsed = 0;
            if (imgdY > 0)
                imgY++;
            else if (imgdY < 0)
                imgY--;
        } 
    }
    
    framesElapsed++;
        
    // print("imgX: "+imgX+"\n");
    // print("imgY: "+imgY+"\n");
}

private int floatCompare(float a, float b)
{
    if (a > b)
        return 1;
    else if ( abs(a - b) < EPSILON )
        return 0;
    else
        return -1;
}

/*
 *  Adjust the given image so that none of its dimensions are smaller than the frame's dimensions.
 */
public void fixImgToFrame(PImage image)
{
    /* Handle resizing of the image. */
    if (image.width < width && image.height < height)
    {
        if ((width - image.width) > (height - image.height))
            image.resize(0, height);
        else
            image.resize(width, 0); 
    }
    else if (image.width < width)
        image.resize(width, 0);
    else if (image.height < height)
        image.resize(0, height);  
}
