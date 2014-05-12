/*
 *  class: PAudioPlayer
 *  Wrapper class for Minim's AudioSource; provides support
 *  for basic music player functions (such as handling songs)
 */
 
class PAudioPlayer
{
    // private Minim minim;
    private AudioSource source;
    private ArrayList<String> queue;
    private ArrayList<Integer> order;
    private int index;
    
    private boolean repeat;
    private boolean shuffle;
    private boolean manualPause;
    private boolean autoNext;
    
    /*
     *  Constructs a new PAudioPlayer. 
     */
    public PAudioPlayer()
    {
        /* Initialize minim; default PAudioPlayer source is system input. */
        // minim = new Minim(this);
        source = minim.getLineIn();
      
        /* Initialize the PAudioPlayer song queue. */
        queue = new ArrayList<String>();
        order = new ArrayList<Integer>();
        index = -1;
    }
    
    /*
     *  Returns the current AudioSource used by the PAudioPlayer.
     */    
    public AudioSource getSource()
    {
        return source; 
    }
    
    /*
     *  Returns the AudioMetaData object associated with the AudioSource.
     */
    public AudioMetaData getMetaData()
    {
        if (playerMode())
            return ((AudioPlayer) source).getMetaData();
        return null;  
    }
    
    /*
     *  Returns whether or not the internal AudioSource is an AudioPlayer.
     */
    public boolean playerMode()
    {
        return source instanceof AudioPlayer; 
    }
    
    public boolean isPlaying()
    {
        if (playerMode())
            return ((AudioPlayer) source).isPlaying();
        return false;
    }
    
    public boolean isRepeating()
    {
        return repeat; 
    }
    
    public boolean isShuffling()
    {
        return shuffle;
    }
    
    /*
     *  Checks on the current player status; plays the sequential song if the current song has finished, or
     *  repeats the current song if the player is on repeat mode.
     */
    public void checkPlayerStatus()
    {
        if (playerMode() && !((AudioPlayer) source).isPlaying() && !manualPause)
            if (repeat)
                play();
            else
            {
                autoNext = true;
                next();            
            }   
    }
    
    /*
     *  Check if the PAudioPlayer has finished a song and automatically started playing the next one available.
     */
    public boolean checkAutoNext()
    {
        if (autoNext)
        {
            autoNext = false;
            return true; 
        }
        return false;
    }
    
    public void play()
    {
        if (playerMode())
        {
            /* Hack to check if song is over but not paused. Minim doesn't have proper working functionality to detect this. */
            if ( !manualPause )
                ((AudioPlayer) source).rewind();
            ((AudioPlayer) source).play();
            manualPause = false;
        }
    }
    
    public void pause()
    {
        if (playerMode())
        {
            ((AudioPlayer) source).pause();
            manualPause = true;
        }   
    }
    
    public void stop()
    {
        if (playerMode())
        {
           ((AudioPlayer) source).pause();
           ((AudioPlayer) source).rewind();
           manualPause = true;
        }
    }

    public void seek(int pos)
    {
        if (playerMode())
            ((AudioPlayer) source).cue(pos);
    }
    
    public int getSeekPosition()
    {
        if (playerMode())
            return ((AudioPlayer) source).position();
        return -1; 
    }
    
    public float getLength()
    {
        if (playerMode())
            return ((AudioPlayer) source).length();
         return -1;
    }
    
    public void setVolume(float gain)
    {
        if (playerMode())
            ((AudioPlayer) source).setGain(gain); 
    }
    
    public float getVolume()
    {
        if (playerMode())
            return ((AudioPlayer) source).getGain();
        return -1;
    }
        
    public void close()
    {
        if (playerMode())
            ((AudioPlayer) source).close();
        minim.stop();
    }
    
    public void enqueue(String path)
    {
        index++;
        queue.add(path);
        order.add(index);
    }
    
    public void dequeue(int index)
    {
        queue.remove(index);
        order.remove(Integer.valueOf(index));
        
        /* Decrement the remaining indices above the removed index. */
        for(int i = 0; i < order.size(); i++)
            if ( Integer.compare(order.get(i), index) > 0 )
                order.set(i, order.get(i) - 1);
                
        this.index--;
    }
    
    /*
     *  Toggles repeat mode for the PAudioPlayer.
     */
    public void toggleRepeat()
    {
        if (repeat)
           repeat = false;
        else
           repeat = true; 
    }
       
    /*
     *  Toggles shuffle mode for the PAudioPlayer and sets appropriate changes in the internal arrays.
     */
    public void toggleShuffle()
    {
        if (shuffle)
        {    
            index = order.get(index);
            /* Sort the song order back to sequential order. */
            Collections.sort(order);
            shuffle = false;
        }
        else
        {
            shuffleOrder();
            shuffle = true;
            index = 0; 
        }
    }
    
    /*
     *  Performs a Knuth shuffle on the song order list.
     */
    private void shuffleOrder()
    {
        Random rng = new Random();
        for(int i = order.size() - 1; i > 0; i--)
        {
            int j = rng.nextInt(i + 1);
            Collections.swap(order, j, i);
        }
    }
    
    public void load(String path)
    {
        /* Close the previous AudioPlayer. */
        if (playerMode())
            ((AudioPlayer) source).close();            

        source = minim.loadFile(path);
        play();
    }
    
    public void next()
    {
        if (index + 1 < order.size())
            load(queue.get(order.get(++index)));
        /* Shuffled list is circular. */
        else if (shuffle)
        {
            index = 0;
            load(queue.get(order.get(index))); 
        }
            
    }
    
    public void previous()
    {
        if (index - 1 >= 0)
            load(queue.get(order.get(--index))); 
        /* Shuffled list is circular. */
        else if (shuffle)
        {
            index = order.size() - 1;
            load(queue.get(order.get(index)));
        }
    }

    public String getPath()
    {
        return queue.get(index);
    }
    
    public int getIndex()
    {
        return ((int) order.get(index)); 
    }
    
}
