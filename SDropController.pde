import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.Transferable;
import java.util.List;

SDrop drop;
int currDropCount;

void initSDrop()
{
    drop = new SDrop(this);
    currDropCount = 0;
}

void dropEvent(DropEvent theDropEvent)
{
    if (theDropEvent.isFile())
    {  
        /* First check for directories. */
        File dropFile = theDropEvent.file();
        if (dropFile.isDirectory())
        {   
            File[] directory = theDropEvent.listFilesAsArray(dropFile, true);
            for(int i = 0; i < directory.length; i++)
            {
                String filePath = directory[i].getPath();
                if (isSupportedSong(filePath))
                    player.enqueue(filePath);
            } 
            checkDropCount(theDropEvent);
        }
        /* Then proceed to individual files. */
        else if (isSupportedSong(theDropEvent.filePath()))
        {
            player.enqueue(theDropEvent.filePath());      
            checkDropCount(theDropEvent);
        }
        /* Ignore the file, increment the counter. */
        else
            checkDropCount(theDropEvent);
    }
}


/*
 *  Checks whether the current file is the last file of the DropEvent.
 *  If so, load the file as a song.
*/
void checkDropCount(DropEvent theDropEvent)
{  
    currDropCount++;
    if (currDropCount >= getDropCount(theDropEvent))
    {
        player.load(player.getPath());
        widget.listen(player.getSource());
        widget.generateID3AlbumArt();
        widget.generateMetaData();
        widget.getFileName(player.getPath());
        currDropCount = 0;
    }          
}

/*
 *  Returns the number of files dragged in a DropEvent.
*/
int getDropCount(DropEvent theDropEvent)
{
    try 
    {
        Transferable transferable = theDropEvent.dropTargetDropEvent().getTransferable();
        return ((List) (transferable.getTransferData(transferable.getTransferDataFlavors()[0]))).size();
    }
    catch (Exception e)
    {
        return 1;
    }
}


/*
 *  Current minim supported audio formats: mp3, wav
 *  TODO: add self-implemented FLAC support later
*/
boolean isSupportedSong(String filePath)
{
    return filePath.toLowerCase().endsWith(".mp3") || filePath.toLowerCase().endsWith(".wav");
}
