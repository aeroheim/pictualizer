
/**
 *  class: Methods
 *  contains all non-class definitive accessory/misc methods used.
*/

import java.lang.StringBuffer;


class Methods
{
  
  //Determines if a String represents an Integer value.
  public static boolean isInteger(String str) 
  {
    try 
    {
      Integer.parseInt(str);
      return true;
    } 
      catch (NumberFormatException nfe) {
    }
    return false;
  }

  //Determines if a String represents a Float value.
  public static boolean isFloat(String str)
  {
    try
    {
      Float.parseFloat(str);
      return true;
    }
      catch (NumberFormatException nfe) {
    }
    return false;
  }  
  
  //Removes all non-digit characters from a String by returning a new String.
  public static String removeChar(String str)
  {
    int length = str.length();
    StringBuffer digits = new StringBuffer(length);
    for (int i = 0; i < length; i++)
    {
      char ch = str.charAt(i);
      if ( Character.isDigit(ch) )
      {
        digits.append(ch);
      }
    }
    return digits.toString();
  }

  //Converts a timestamp by the format minute:seconds to milliseconds.
  public static int convertToMillis(int minutesSeconds)
  {
    int seconds = minutesSeconds % 100;
    int minutes = minutesSeconds / 100;
    return (minutes*60000) + (seconds*1000);
  }
  
  //Converts milliseconds to seconds.
  public static int millisToSeconds(int milliseconds)
  {
    return (milliseconds/1000)%60;
  }

  //Converts milliseconds to minutes.
  public static int millisToMinutes(int milliseconds)
  {
    return milliseconds/60000;
  }
  
}
