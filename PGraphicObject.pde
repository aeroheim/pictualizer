
/*
 *  abstract class: PGraphicObject
 *
 *  A basic abstract implementation of a graphical UI object in pictualizer.
 *  This class provides basic positional functionalities, but lacks an object to draw.
 *  Extending classes must implement the abstract draw() method.
 */
 
public abstract class PGraphicObject
{
    private float pX;
    private float pY;
    private float pWidth;
    private float pHeight;
    private color pColor;
    private color pDimColor;
    private color pHighlightColor;
    
    /*
     *  Default constructor for the abstract PGraphicObject class.
     *  All positional values are initialized to 0;
     *  colors are by default initialized to (255, 255, 255).
     */
    public PGraphicObject()
    {
        /* Default coordinates. */
        pX = 0.0;
        pY = 0.0;
        pWidth = 0.0;
        pHeight = 0.0; 
        
        /* Default colors. */
        pColor = color(255);
        pDimColor = color(255);
        pHighlightColor = color(255);
    }
  
    /*
     *  Constructor for initializing positional values only. 
     */
    public PGraphicObject(float pX, float pY, float pWidth, float pHeight)
    {
        this.pX = pX;
        this.pY = pY;
        this.pWidth = pWidth;
        this.pHeight = pHeight;
    }
    
    /*
     *  Constructor that fully initializes a PGraphicObject. 
     *  Positional values and colors must all be provided.
     */
    public PGraphicObject(float pX, float PY, float pWidth, float pHeight, color pColor, color pDimColor, color pHighlightColor)
    {
        this.pX = pX;
        this.pY = pY;
        this.pWidth = pWidth;
        this.pHeight = pHeight;
        this.pColor = pColor;
        this.pDimColor = pDimColor;
        this.pHighlightColor = pHighlightColor;
    }
    
    /* 
     *  Extending classes must implement the draw() method to draw the actual PGraphicObject.
     */
    public abstract void draw();
       
    /*
     *  mouseOver() returns whether or not the current mouse position is hovering over this PGraphicObject.
     *  The mouse position is checked using processing's mouseX and mouseY system variables.
     */
    public boolean mouseOver()
    {
        if (mouseX >= pX && mouseX <= pX + pWidth &&
            mouseY >= pY && mouseY <= pY + pHeight)
            return true;
        return false;
    }
    
    /*
     *  isClicked() returns whether or not the PGraphicObject has been clicked on or not.
     */
    public boolean isClicked()
    {
        if (mouseButton == LEFT && mouseOver())
            return true;
        return false;
    }
    
    
    /*
     *  requires implementation; handles click interaction
     */
    public void registerClick() {};
        
    /* 
     *  resize() will resize the PGraphicObject given new positional values.
     *  This method is kept protected, as deriving classes will have different 
     *  requirements for resizing.
     */
    protected void resize(float pWidth, float pHeight)
    {
        this.pWidth = pWidth;
        this.pHeight = pHeight;
    }

    /* 
     *  setLocation() sets the PGraphicObject to the given new positional values.
     */
    public void setLocation(float pX, float pY)
    {
        this.pX = pX;
        this.pY = pY;
    }
    
    /* 
     *  highlight() sets the current color of this object to the highlighted color.
     */
    public void highlight()
    {
        setColor(pHighlightColor); 
    }

    /* 
     *  dim() sets the current color of this object to the dim color.
     */    
    public void dim()
    {
        setColor(pDimColor);
    }
    
    /*
     *  returns the current X coordinate of this PGraphicObject.
     */    
    public float getX()
    {
        return pX; 
    }
    
    /*
     *  returns the current Y coordinate of this PGraphicObject.
     */    
    public float getY()
    {
        return pY; 
    }
    
    /*
     *  returns the current width of this PGraphicObject.
     */    
    public float getWidth()
    {
        return pWidth; 
    }
    
    /*
     *  returns the current height of this PGraphicObject.
     */    
    public float getHeight()
    {
        return pHeight; 
    }
    
    /*
     *  returns the current color of this PGraphicObject.
     */
    public color getColor()
    {
        return pColor; 
    }
    
    /*
     *  returns the current specified dim color of this PGraphicObject.
     */
    public color getDimColor()
    {
        return pDimColor; 
    }      
        
    /*
     *  returns the current specified highlight color of this PGraphicObject.
     */
    public color getHighlightColor()
    {
        return pHighlightColor; 
    }
    
    /*
     *  Sets the current color of this PGraphicObject to the specified color.
     */
    public void setColor(color c)
    {
        pColor = c;
    }
    
    /*
     *  Sets the current dim color of this PGraphicObject to the specified color.
     */
    public void setDimColor(color c)
    {
        pDimColor = c; 
    }
    
    /*
     *  Sets the current highlight color of this PGraphicObject to the specified color.
     */
    public void setHighlightColor(color c)
    {
        pHighlightColor = c; 
    }
    
}
