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
    songIndex++;
}

void dequeueSong(int index)
{
    songQueue.remove(index);
    songIndex--;
}

String getCurrentSong()
{
    return songQueue.get(songIndex - 1);
}    
