/*
 *  class: TextButton
 *  basic GUI element that creates interactive text with 
 *  basic functionalities such as being clicked on or highlighted.
 */

class TextButton {
  
  private PFont font;
  private int size;
  private float xPos;
  private float yPos;
  private String text;
  int textColor;
  

  
  
  // Creates a TextButton object.
  public TextButton(PFont font, int size, String text, float xPos, float yPos, int textColor) 
  {
    this.font = font;
    this.size = size;
    this.text = text;
    this.xPos = xPos;
    this.yPos = yPos;
    this.textColor = textColor;
  }
  
  // Changes the position of this text button.
  public void changePos(float xPos, float yPos)
  {
    this.xPos = xPos;
    this.yPos = yPos;
  }
  
  // Changes the size of this text button.
  public void changeSize(int size)
  {
    this.size = size;
  }
  
  // Draws the designated text with the designated color.
  public void draw()
  {
    fill(textColor);
    textFont(font, size);
    textAlign(LEFT, TOP); 
    text(text, xPos, yPos);
  }
  
  // Returns the width of this TextButton.
  public float getWidth()
  {
    textFont(font, size);
    return textWidth(text); 
  }
  
  // Returns the height of this TextButton.
  public float getHeight()
  {
    textFont(font, size);
    return textAscent() + textDescent();
  }
  
  // Returns the starting X position of this TextButton.
  public float getX()
  {
    return xPos;
  }
  
  // Returns the starting Y position of this TextButton.
  public float getY()
  {
    return yPos;
  }
  
  // Returns the ending X position of this TextButton.
  public float getEndX()
  {
    return xPos + getWidth();
  }
  
  // Returns the ending Y position of this TextButton.
  public float getEndY()
  {
    return yPos + getHeight();
  }
  
  boolean mouseOver()
  {
      if (mouseX >= xPos && mouseX <= xPos + getWidth() &&
          mouseY >= yPos && mouseY <= yPos + getHeight())
      {
          textColor = 255;
          return true;
      }
      textColor = 200;
      return false;
  }
  
}
