ArrayList<String> songQueue;
int songIndex;

void initSongQueue()
{
    songQueue = new ArrayList<String>();
    songIndex = 0; 
}

void enqueueSong(String path)
{
    songQueue.add(path);
    songIndex = songQueue.size();
}

void dequeueSong(int index)
{
    songQueue.remove(index);
    songIndex--;
}

/*
 *  Load a new song into the pictualizer's main AudioPlayer.
 *  Uses the given filepath provided.
*/
void loadSong(String filePath)
{
    /* Refresh minim. */
    if (in instanceof AudioPlayer)
        ((AudioPlayer) in).close();
    minim.stop();
    minim = new Minim(this);
       
    /* Update minim with new song. */
    in = minim.loadFile(filePath);
    widget.listen(in);
    spectrumVisualizer.listen(in);
    ((AudioPlayer) in).play();
    
    /* Update widget metadata. */
    widget.generateID3AlbumArt();
    widget.generateMetaData();
    widget.getFileName(filePath);
}


/*
 *  Attempt to load the next song in the songQueue
 *  if it exists.
*/
void loadNextSong()
{
    if (songIndex < songQueue.size())
        loadSong(songQueue.get(songIndex++));
}

void loadPrevSong()
{
    if (songIndex - 2 >= 0)
    {
        songIndex--;
        loadSong(songQueue.get(songIndex - 1)); 
    }
}


String getCurrentSong()
{
    return songQueue.get(songIndex - 1);
}
