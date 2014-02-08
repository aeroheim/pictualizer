/*
 *  class: ProgressBar
 *  
 *  implements a user interface progress bar; the bar can be
 *  initialized with a maximum value and polled to continuously 
 *  update the progress towards the maximum value.
 */
 
public class ProgressBar extends PGraphicObject
{
    float maxVal;
    float currVal;
    color backgroundColor;
     
    /*
     *  The default constructor for a ProgressBar initializes all progress values to 0.
     */
    public ProgressBar()
    {
        maxVal = 0.0;
        currVal = 0.0;
        backgroundColor = color(0);
    }
    
    /*
     *  The constructor for ProgressBar takes in positional values and a specified current and max value.
     */
    public ProgressBar(float pX, float pY, float pWidth, float pHeight, float currVal, float maxVal)
    {
        resize(pWidth, pHeight);
        setLocation(pX, pY);
        this.maxVal = maxVal;
        this.currVal = currVal;
        backgroundColor = color(0);
    }
    
    /*
     *  Uses the PGraphicObject's protected resize method to resize the ProgressBar.
     */
    public void resize(float pWidth, float pHeight)
    {
        super.resize(pWidth, pHeight);
    }
    
    /*
     *  Draws the ProgressBar. The main color is used for the progress, and the background
     *  color is used for the background. The length of the current progress bar depends on
     *  the current and max progress values.
     */
    public void draw()
    {
        noStroke();
        /* Draw the background bar first. */
        fill(backgroundColor);
        rect(getX(), getY(), getWidth(), getHeight());
      
        /* Now draw the current progress bar. */
        fill(getColor());
        rect(getX(), getY(), (getProgressPercent() / 100) * getWidth(), getHeight());
    }
    
    /*
     *  Set the color of the progress bar's background.
     */
    public void setBackgroundColor(color backgroundColor)
    {
        this.backgroundColor = backgroundColor; 
    }
    
    /*
     *  Set the current progress value to the specified value.
     *  This method will only use the specified value if it is still less than the max value.
     */
    public void setCurrentValue(float currVal)
    {
        if (Float.compare(currVal, maxVal) <= 0)
            this.currVal = currVal; 
    }

    /*
     *  Set the max progress value to the specified value.
     *  This method will only use the specified max value if it is greater than the current value.
     */    
    public void setMaxValue(float maxVal)
    {
        if (Float.compare(maxVal, currVal) >= 0)
            this.maxVal = maxVal; 
    }
    
    /*
     *  Set the current progress to the specified percent.
     */
    public void setProgressPercent(float percent)
    {
        setCurrentValue(percent * maxVal);
    }
    
    /*
     *  Returns the current progress value.
     */
    public float getCurrentValue()
    {
        return currVal;
    }
    
    /*
     *  Returns the current max value.
     */
    public float getMaxVal()
    {
        return maxVal; 
    }
    
    /*
     *  Returns the current percentage of progress.
     */
    public float getProgressPercent()
    {
        return (currVal / maxVal) * 100; 
    }
    
    /* 
     *  Returns the current background color of the progress bar.
     */
    public color getBackgroundColor(color backgroundColor)
    {
        return backgroundColor;
    }
    
    
}
