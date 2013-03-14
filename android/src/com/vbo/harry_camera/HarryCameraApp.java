package com.vbo.harry_camera;

import android.app.Application;
import android.content.Context;
import android.util.Log;
import android.view.Display;
import android.view.WindowManager;

import com.vbo.harry_camera.data.DataHelper;
import com.vbo.harry_camera.utils.CameraUtil;

public class HarryCameraApp extends Application {

    private static final String TAG = "HarryCamera";
    public static Display sDefaultDisplay;
    public static boolean sCameraPrepared;
    private static CameraPrepareListener sCameraPrepareListener;
    @Override
    public void onCreate() {
        super.onCreate();
        WindowManager wmManager = (WindowManager) getSystemService(Context.WINDOW_SERVICE);
        sDefaultDisplay = wmManager.getDefaultDisplay();
        DataHelper.initDataCache(getApplicationContext());
        new Thread(new Runnable() {

            @Override
            public void run() {
                if (!CameraUtil.init(getApplicationContext())) {
                    Log.w(TAG, "no camera");
                } else {
                    CameraUtil.setCurrentMode(true);
                    sCameraPrepared = true;
                    if (sCameraPrepareListener != null)
                        sCameraPrepareListener.onCameraPrepared();
                }
            }
        }).start();
        new  Thread(new Runnable(){

            @Override
            public void run() {
                DataHelper.refreshRes(null);
            }
        }).start();
    }

    @Override
    public void onTerminate() {
        super.onTerminate();
    }

    public static void setCameraPrepareListener(CameraPrepareListener listener) {
        sCameraPrepareListener = listener;
    }

    public interface CameraPrepareListener {
        public void onCameraPrepared();
    }
}
