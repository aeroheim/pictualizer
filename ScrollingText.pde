/*
 *  class: ScrollingText
 *  animates a scrolling text.
 *  scrolls the text in and out of the given x boundaries.
 *  time intervals for scrolling can be specified.
 */
 
public class ScrollingText extends PGraphicObject
{     
    private PFont font;
    private String text;
    private int fontSize;    
    
    private float translatedWidth;
    private float scrollWidth;     
    private float scrollSpeed;
    private float frameElapsed;
    private int scrollPause;
    
    private PGraphics textBuffer;
   
    /*
     *  The default constructor is disabled for this class,
     *  since there is no default font.
     */
    private ScrollingText()
    {
    } 
    
    /*
     *  Constructor that initializes position and text.  
     */
    public ScrollingText(float pX, float pY, float pWidth, PFont font, int fontSize, String text)
    {
        textFont(font, fontSize);
        
        /* Threaded non-sense, requires while loop. */
        while(pX != getX() && pY != getY() && getWidth() != pWidth && getHeight() != textAscent() + textDescent())
        {
            textFont(font, fontSize);
            setLocation(pX, pY);
            resize(pWidth, textAscent() + textDescent());
        }
            
        this.font = font;
        this.fontSize = fontSize;
        this.text = text;
        
        frameElapsed = 0;
        
        /* Calculate & initialize scroll values. */
        scrollSpeed = 0.0;
        scrollPause = 0;
        translatedWidth = 0.0;
        scrollWidth = textWidth(text) - pWidth;
        
        /* Create the buffer to draw on. */
        textBuffer = createGraphics((int) pWidth, (int) (textDescent() + textAscent()));
        textBuffer.beginDraw();
        textBuffer.endDraw();
        drawToBuffer();
    }
    
    /*
     *  resize() the ScrollingText by specifing a new font size and width.
     *  The height of the internal graphics buffer will be updated according to the 
     *  new font size, and the width will be updated to the specified value passed in.
     */
    public void resize(int fontSize, float pWidth)
    {
        this.fontSize = fontSize;
        textFont(font, fontSize);
        textBuffer = createGraphics((int) pWidth, (int) (textDescent() + textAscent()));
        textBuffer.beginDraw();
        textBuffer.endDraw();
        drawToBuffer();
    }
    
    /*
     *  Draw this ScrollingText object's buffer onto the main Processing buffer.
     */
    public void draw()
    {
        image(textBuffer, getX(), getY());
        /* Scroll only if necessary. */
        if (scrollWidth > 0)
            scrollText();
    }
        
    /*
     *  Set the speed at which the text scrolls at. 
     */
    public void setScrollSpeed(float scrollSpeed)
    {
        this.scrollSpeed = scrollSpeed;
    }
        
    /*
     *  Set the time to pause the scroll once reaching an end.
     *  Time is measured in seconds.
     */
    public void setScrollPause(int scrollPause)
    {
        this.scrollPause = scrollPause; 
    }
    
    /*
     *  Return the current speed that this ScrollingText scrolls at.
     */
    public float getScrollSpeed()
    {
        return scrollSpeed;
    }
    
    /*
     *  Returns the current pause duration that this ScrollingText uses.
     */
    public float getScrollPause()
    {
        return scrollPause; 
    }
    
    /*
     *  Internal method that draws to the ScrollingText buffer.
     */
    private void drawToBuffer()
    {
        /* Set up font related properties first. */
        textBuffer.textFont(font, fontSize);
        textBuffer.textAlign(LEFT, TOP);
        
        /* Always clear previous frame before re-drawing. */
        textBuffer.clear();
                
        textBuffer.beginDraw();   
        textBuffer.translate(translatedWidth, 0);
        textBuffer.text(text, 0, 0);

        textBuffer.endDraw();  
    }
    
    /*
     *  Internal method that scrolls the text. Uses scrollSpeed to control
     *  the scrolling speed, and scrollPause as the duration to pause when scrolled to the end.
     */
    private void scrollText()
    {
        int compare1 = Float.compare(abs(translatedWidth), scrollWidth);
        int compare2 = Float.compare(translatedWidth, 0.0);
        
        /* At end of text. Begin pause duration. */     
        if ((compare1 > 0 || compare1 == 0 || compare2 == 0) && frameElapsed / 60 < scrollPause)
        {
            frameElapsed++;
            drawToBuffer();
        }
        /* Finished pause, now intiate the new scrolling. */
        else if ((compare1 > 0 || compare1 == 0 || compare2 == 0.0) && frameElapsed / 60 >= scrollPause)
        {
            scrollSpeed= -(scrollSpeed);
                   
            drawToBuffer();
            
            translatedWidth += scrollSpeed;
            frameElapsed = 0;       
        }
        /* Continue scrolling. */
        else
        {
            drawToBuffer();
            translatedWidth += scrollSpeed;
        }
    }
    
}
