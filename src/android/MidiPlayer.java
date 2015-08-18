package normannit.midiplayer;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import android.content.Context;
import android.net.Uri;
import android.media.MediaPlayer;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetFileDescriptor;
import java.io.IOException;
import java.io.FileInputStream;

public class MidiPlayer extends CordovaPlugin
{

    MediaPlayer mediaPlayer;
    String filename;

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException
    {
        Context context = this.cordova.getActivity().getApplicationContext();

        if (action.equals("setup"))
        {
            String filePath = data.getString(0);
            mediaPlayer = new MediaPlayer();
            filename = filePath;
            callbackContext.success("success");
            return true;
        }

        if (action.equals("play"))
        {
            try
            {
                AssetFileDescriptor descriptor = context.getAssets().openFd(filename);
                mediaPlayer.setDataSource(descriptor.getFileDescriptor(), descriptor.getStartOffset(), descriptor.getLength());
                descriptor.close();
                mediaPlayer.prepare();
                mediaPlayer.start();
            }
            catch(Exception e)
            {
                callbackContext.error(e.toString());
            }
            callbackContext.success("success");
            return true;
        }

        if (action.equals("pause"))
        {
            mediaPlayer.pause();
            callbackContext.success("success");
            return true;
        }

        if (action.equals("stop"))
        {
            mediaPlayer.stop();
            callbackContext.success("success");
            return true;
        }

        if (action.equals("getCurrentPosition"))
        {
            callbackContext.success(""+mediaPlayer.getCurrentPosition());
            return true;
        }

        if (action.equals("seekTo"))
        {
            mediaPlayer.seekTo(data.getInt(0));
            callbackContext.success("success");
            return true;
        }

        if (action.equals("release"))
        {
            callbackContext.success("Not implemented for android yet. This method has no effect.");
            return true;
        }
            
        callbackContext.error("Unknown method");
        return false;
    }
}