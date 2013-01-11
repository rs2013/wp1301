package com.weiplus.client;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;

public class HaxeHelper {
    
    private static final String TAG = "HaxeHelper";
    
    private static Map<Integer, String[]> resultMap = new HashMap<Integer, String[]>();
    
    private HaxeHelper() { }
    
    public static void startHaxeActivity(Activity activity, int requestCode, String haxeAppId, String param) {
        Intent it = new Intent(activity, MainActivity.class);
        it.putExtra("appId", haxeAppId);
        if (param != null) {
            it.putExtra("param", param);
        }
        activity.startActivityForResult(it, requestCode);
    }

    public static void finishHaxeActivity(int resultCode, String result) {
        Intent it = new Intent();
        if (result != null && result != "") {
            it.putExtra("data", result);
        }
        MainActivity.getInstance().setResult(resultCode, it);
        MainActivity.getInstance().finish();
    }
    
    public static void startActivity(String activityClassName, int requestCode, String[] pairs) {
        Class<Activity> clz = null;
        try {
            Class.forName(activityClassName);
        } catch (ClassNotFoundException e) {
            Log.i(TAG, "Start " + activityClassName + " failed.");
        }
        Intent it = new Intent(MainActivity.getInstance(), clz);
        if (pairs != null && pairs.length > 0) {
            for (int i = 0; i < pairs.length; i += 2) {
                it.putExtra(pairs[i], pairs[i + 1]);
            }
        }
        MainActivity.getInstance().startActivityForResult(it, requestCode);
    }
    
    public static void startImageCapture(int requestCode, String snapFilePath) {
        Intent it = new Intent(MediaStore.ACTION_IMAGE_CAPTURE); // "android.media.action.IMAGE_CAPTURE"
        Uri uri = Uri.fromFile(new File(snapFilePath));
        it.putExtra( MediaStore.EXTRA_OUTPUT, uri);
        MainActivity.getInstance().startActivityForResult(it, requestCode);
    }
    
    public static void onActivityResult(int requestCode, int resultCode, Intent data) {
        List<String> list = new ArrayList<String>();
        list.add("resultCode");
        list.add(requestCode == Activity.RESULT_OK ? "ok" : "canceled");
        Bundle extras = data != null ? data.getExtras() : null;
        if (extras != null) {
            for (String key: extras.keySet()) {
                Object o = extras.get(key);
                if ((o instanceof Integer) || (o instanceof String)) {
                    list.add(key);
                    list.add(o.toString());
                }
            }
        }
        resultMap.put(requestCode, list.toArray(new String[0]));
    }
    
    public static String[] getResult(int requestCode) {
        return resultMap.get(requestCode);
    }
    
}
