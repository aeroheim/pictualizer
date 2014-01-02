/*
 *  class: TextButton
 *  basic GUI element that creates interactive text with 
 *  basic functionalities such as being clicked on or highlighted.
 */

class TextButton {
  
  private PFont font;
  private int size;
  private int xPos;
  private int yPos;
  private String text;
  
  //Color constants for the TextButton class.
  public final int HIGHLIGHT = 255;
  public final int DIM = 175;
  
  
  // Creates a TextButton object.
  public TextButton(PFont font, int size, String text, int xPos, int yPos) 
  {
    this.font = font;
    this.size = size;
    this.text = text;
    this.xPos = xPos;
    this.yPos = yPos;
  }
  
  // Changes the position of this text button.
  public void changePos(int xPos, int yPos)
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
  public void draw(int textColor) 
  {
    fill(textColor, textColor, textColor);
    textFont(font, size);
    text(text, xPos, yPos);
  }
  
  // Returns the width of this TextButton.
  public int getWidth()
  {
    textFont(font, size);
    return (int)textWidth(text); 
  }
  
  // Returns the height of this TextButton.
  public int getHeight()
  {
    textFont(font, size);
    return (int)textWidth(text);
  }
  
  // Returns the starting X position of this TextButton.
  public int getX()
  {
    return xPos;
  }
  
  // Returns the starting Y position of this TextButton.
  public int getY()
  {
    return yPos;
  }
  
  // Returns the ending X position of this TextButton.
  public int getEndX()
  {
    return xPos + getWidth();
  }
  
  // Returns the ending Y position of this TextButton.
  public int getEndY()
  {
    return yPos + getHeight();
  }
  
}

