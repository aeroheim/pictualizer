/*
 *  class: TextButton
 *
 *  Basic GUI element that uses text to serve
 *  as an interactive button.
 */

public class TextButton extends PGraphicObject
{   
    private PFont font;
    private String text;
    private int fontSize;
    
    /*
     *  The default constructor is disabled for this class,
     *  since there is no default font.
     */
    private TextButton()
    {
    }
    
    /*
     *  Constructor that initializes position and text.  
     */
    public TextButton(float pX, float pY, PFont font, int fontSize, String text)
    {
        textFont(font, fontSize);
        setLocation(pX, pY);
        resize(textWidth(text), textAscent() + textDescent());
        this.font = font;
        this.fontSize = fontSize;
        this.text = text;
    }
    
    /*
     *  resize() the TextButton by specifying a new font size.
     *  The width and height of this TextButton is adjusted accordingly to the new
     *  dimensions of the font using the new font size.
     */
    public void resize(int fontSize)
    {
        textFont(font, fontSize);
        this.fontSize = fontSize;
        resize(textWidth(text), textAscent() + textDescent());
    }
    
    /*
     *  setFont() changes the font of this TextButton.
     */
    public void setFont(PFont newFont)
    {
        PFont font = newFont;
        resize(fontSize);
    }
      
    /*
     *  draw() draws the TextButton onto the main Processing buffer.
     */
    public void draw()
    {
        fill(getColor());
        textFont(font, fontSize);
        textAlign(LEFT, TOP); 
        text(text, getX(), getY());
    }
    
}
