import java.awt.MouseInfo; 
import java.awt.Point;

Point mouse;
boolean dragging;
int prevMouseX;
int prevMouseY;
int newMouseX;
int newMouseY;

/*
 *  Smooth dragging implementation taken from processing forums.
 *  http://processing.org/discourse/beta/num_1266149435.html. 
 */
void mouseDragged()                                  
{                                                    
    mouse = MouseInfo.getPointerInfo().getLocation();
    if ( !dragging )
    {
        prevMouseX = mouseX;
        prevMouseY = mouseY;
        dragging = true;
    }
    newMouseX = mouse.x - prevMouseX;
    newMouseY = mouse.y - prevMouseY;
    frame.setLocation(newMouseX, newMouseY);
}

/*
 *  Part of smooth dragging implementation.
 */
void mouseReleased()
{
    dragging = false;
}

void mouseClicked()
{
    widget.registerClick();
}
