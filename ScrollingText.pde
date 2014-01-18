/*
 *  class: ScrollingText
 *  animates a scrolling text.
 *  scrolls the text in and out of the given x boundaries.
 *  time intervals for scrolling can be specified.
 */
 
class ScrollingText
{
    String text;
    PFont font;
    int size;
     
    float x;
    float y;
    float scrollingTextWidth;
    
    float translatedWidth;
    float scrollWidth;
     
    float scrollSpeed;
    int scrollPause;
    float frameElapsed;
    
    boolean pause;
    
    PGraphics textBuffer;
    
    ScrollingText(String text, PFont font, int size, float x, float scrollingTextWidth, float y)
    {
        this.text = text;
        this.font = font;
        this.size = size;
        this.x = x;
        this.scrollingTextWidth = scrollingTextWidth;
        this.y = y;
        frameElapsed = 0;
        
        /* Calculate & initialize scroll values. */
        scrollSpeed = 0.0;
        scrollPause = 0;
        translatedWidth = 0.0;
        textFont(font, size);
        scrollWidth = textWidth(text) - scrollingTextWidth;
        pause = true;
        
        /* Create the buffer to draw on. */
        textBuffer = createGraphics((int) scrollingTextWidth, (int) (textDescent() + textAscent()));
        textBuffer.beginDraw();
        textBuffer.endDraw();
        drawToBuffer();
    }
    
    void setScrollSpeed(float speed)
    {
        scrollSpeed = speed;
    }
    
    
    /*
     *  Time to pause the scroll once reaching an end.
     *  Time is measured in seconds.
     */
    void setScrollPause(int scrollPause)
    {
        this.scrollPause = scrollPause; 
    }
    
    void draw()
    {
        image(textBuffer, x, y);
        /* Scroll only if necessary. */
        if (scrollWidth > 0)
            scrollText();
    }
    
    void drawToBuffer()
    {
        /* Set up font related properties first. */
        textBuffer.textFont(font, size);
        textBuffer.textAlign(LEFT, TOP);
        
        /* Always clear previous frame before re-drawing. */
        textBuffer.clear();
                
        textBuffer.beginDraw();   
        textBuffer.translate(translatedWidth, 0);
        textBuffer.text(text, 0, 0);

        textBuffer.endDraw();  
    }
    
    void scrollText()
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
