/*
 *  class: PGraphicsButton
 *
 *  Basic GUI element that uses a PGraphics buffer to 
 *  serve as an interactive button. PGraphics is used instead of PShape
 *  since Processing 2.0+ currently does not support PShape with the JAVA2D renderer.
 */
 
public class PGraphicsButton extends PGraphicObject
{
    private PGraphics buffer;
    private PGraphics highlightBuffer;
    private boolean highlight;

    /*
     *  Default constructor for the PGraphicsButton.
     *  Creates a blank empty shape for the internal shape.
     */
    public PGraphicsButton()
    {
        highlight = false;
        
        buffer = createGraphics(0, 0);
        highlightBuffer = createGraphics(0, 0);
        
        buffer.beginDraw();
        buffer.endDraw();
        highlightBuffer.beginDraw();
        highlightBuffer.endDraw();
    }
        
    /*
     *  Constructor for PGraphicsButton; takes in a specified coordinate
     *  and a pre-constructed PShape as the button.
     */
    public PGraphicsButton(float pX, float pY, PGraphics buffer, PGraphics highlightBuffer)
    {
        highlight = false;
        this.buffer = buffer;
        this.highlightBuffer = highlightBuffer;
        setLocation(pX, pY);
        resize(buffer.width, buffer.height);
    }
    
    /*
     *  resize() resizes the PGraphicsButton by taking in a new
     *  PGraphics and adjusting the height and width values.
     */
    public void resize(PGraphics buffer)
    {
        this.buffer = buffer;
        resize(buffer.width, buffer.height);
    }
    
    /*
     *  Draws the current PGraphics object onto the main Processing buffer.
     */
    public void draw()
    {
        if (highlight)
            image(highlightBuffer, getX(), getY());
        else
            image(buffer, getX(), getY());
    }
    
    /* 
     *  highlight() sets the current color of this object to the highlighted color.
     *  PGraphicsButton overrides the inherited method, since there is no way to
     *  manually change the color of a given PGraphics object.
     */
    public void highlight()
    {
        highlight = true;
    }

    /* 
     *  dim() sets the current color of this object to the dim color.
     *  PGraphicsButton overrides the inherited method, since there is no way to
     *  manually change the color of a given PGraphics object.
     */
    public void dim()
    {
        highlight = false;
    }
}
