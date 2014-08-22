/*
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


void loadSong(String filePath)
{
    if (in instanceof AudioPlayer)
        ((AudioPlayer) in).close();
    // minim.stop();
    // minim = new Minim(this);
       
    in = minim.loadFile(filePath);
    widget.listen(in);
    spectrumVisualizer.listen(in);
    ((AudioPlayer) in).play();
  
    
    widget.generateID3AlbumArt();
    widget.generateMetaData();
    widget.getFileName(filePath);
}

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
*/
