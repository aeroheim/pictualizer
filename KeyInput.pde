
/*
 * Prevent ESC key from exiting the program.
 */
void keyPressed() 
{
  if (key == ESC) 
    key = 0;
}
