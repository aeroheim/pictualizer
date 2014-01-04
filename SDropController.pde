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
    if ( theDropEvent.filePath().toLowerCase().endsWith(".mp3") || theDropEvent.filePath().toLowerCase().endsWith(".wav") ) 
    {
        /* Add song to queue. */
        enqueueSong(theDropEvent.filePath());
        currDropCount++;
        
        if (currDropCount >= getDropCount(theDropEvent))
        {
            /* Refresh minim. */
            if (in instanceof AudioPlayer)
                ((AudioPlayer) in).close();
            minim.stop();
            minim = new Minim(this);
    
            /* Update minim with new song. */
            in = minim.loadFile(getCurrentSong());
            spectrumVisualizer.listen(in);
            ((AudioPlayer) in).play();
        }
    }
}

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
