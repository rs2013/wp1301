package com.weiplus.client;

import java.io.File;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;

import org.json.*;

public class HaxeStub {
    
    private static final String TAG = "HaxeStub";
    
    // key -> JSON String
    private static Map<Integer, String> resultMap = new HashMap<Integer, String>();
    
    private HaxeStub() { }
    
//    public static void startHaxeActivity(Activity activity, int requestCode, String haxeAppId, String param) {
//        Intent it = new Intent(activity, MainActivity.class);
//        it.putExtra("appId", haxeAppId);
//        if (param != null) {
//            it.putExtra("param", param);
//        }
//        activity.startActivityForResult(it, requestCode);
//    }
//
//    public static void finishHaxeActivity(int resultCode, String result) {
//        Intent it = new Intent();
//        if (result != null && result != "") {
//            it.putExtra("data", result);
//        }
//        MainActivity.getInstance().setResult(resultCode, it);
//        MainActivity.getInstance().finish();
//    }
//    
    public static void startActivity(String activityClassName, int requestCode, String jsonArgs) {
        Log.i(TAG, "StartActivity " + activityClassName + ",args=" + jsonArgs);
        Class<Activity> clz = null;
        try {
            Class.forName(activityClassName);
        } catch (ClassNotFoundException e) {
            Log.e(TAG, "Start " + activityClassName + " failed.");
        }
        Intent it = new Intent(MainActivity.getInstance(), clz);
        try {
            if (jsonArgs != null && jsonArgs.length() > 0) {
                JSONObject json = (JSONObject) new JSONTokener(jsonArgs).nextValue();
                Iterator<String> itor = json.keys();
                for (String key = itor.next(); itor.hasNext(); key = itor.next()) {
                    Object o = json.get(key);
                    if (o instanceof Integer) {
                        it.putExtra(key, ((Integer) o).intValue());
                    } else if (o instanceof String) {
                        it.putExtra(key, (String) o);
                    } else if (o instanceof Boolean) {
                        it.putExtra(key, ((Boolean) o).booleanValue());
                    } else if (o instanceof Long) {
                        it.putExtra(key, ((Long) o).longValue());
                    } else if (o instanceof Double) {
                        it.putExtra(key, ((Double) o).doubleValue());
                    }
                }
            }
        } catch (JSONException e) {
            Log.e(TAG, "startActivity: name=" + activityClassName + ", args=" + jsonArgs);
        }
        MainActivity.getInstance().startActivityForResult(it, requestCode);
    }
    
    public static void startImageCapture(int requestCode, String snapFilePath) {
        Log.i(TAG, "startImageCapture " + snapFilePath);
        Intent it = new Intent(MediaStore.ACTION_IMAGE_CAPTURE); // "android.media.action.IMAGE_CAPTURE"
        if (snapFilePath != null && snapFilePath.trim().length() > 0) {
            Uri uri = Uri.fromFile(new File(snapFilePath));
            it.putExtra( MediaStore.EXTRA_OUTPUT, uri);
        }
        MainActivity.getInstance().startActivityForResult(it, requestCode);
    }
    
    public static void startGetContent(int requestCode, String type) {
        Log.i(TAG, "startGetContent " + type);
        Intent innerIntent = new Intent(Intent.ACTION_GET_CONTENT); // "android.intent.action.GET_CONTENT"
        innerIntent.setType("image/*"); // for more info about available types, see com.google.android.mms.ContentType
        Intent it = Intent.createChooser(innerIntent, null);
        MainActivity.getInstance().startActivityForResult(it, requestCode);
    }
    
    public static void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.i(TAG, "onActivityResult, result=" + resultCode + 
//                ",data=" + (data != null ? data.getDataString() : null) + 
//                ",path=" + (data != null ? data.getData().getPath(): null) +
                ",extras=" + (data != null ? data.getExtras() : null));
        JSONObject ret = new JSONObject();
        try {
            ret.put("resultCode", resultCode == Activity.RESULT_OK ? "ok" : 
                resultCode == Activity.RESULT_CANCELED ? "canceled" : "" + resultCode);
            Uri uri = data != null ? data.getData() : null;
            if (uri != null) {
                if (uri.toString().startsWith("content://")) {
                    String[] proj = { MediaStore.Images.Media.DATA };     
                    Cursor actualimagecursor = MainActivity.getInstance().managedQuery(uri, proj, null, null, null);
                    int actual_image_column_index = actualimagecursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
                    actualimagecursor.moveToFirst();
                  
                    String img_path = actualimagecursor.getString(actual_image_column_index);    
                    File file = new File(img_path);
                    ret.put("intentDataPath", file.getAbsolutePath());
                } else {
                    ret.put("intentDataPath", uri.getPath());
                }
            }
            Bundle extras = data != null ? data.getExtras() : null;
            if (extras != null) {
                for (String key: extras.keySet()) {
                    Object o = extras.get(key);
                    if (o instanceof Integer) {
                        ret.put(key, ((Integer) o).intValue());
                    } else if (o instanceof String) {
                        ret.put(key, (String) o);
                    } else if (o instanceof Boolean) {
                        ret.put(key, ((Boolean) o).booleanValue());
                    } else if (o instanceof Long) {
                        ret.put(key, ((Long) o).longValue());
                    } else if (o instanceof Double) {
                        ret.put(key, ((Double) o).doubleValue());
                    } else {
                        ret.put(key, o.toString());
                    }
                }
            }
        } catch (JSONException e) {
            Log.e(TAG, "onActivityResult error: requestCode=" + requestCode + ", data=" + data);
        }
        resultMap.put(requestCode, ret.toString());
//        Log.i(TAG, "onActivityResult, result=" + ret);
        Log.i(TAG, "dump map: " + resultMap);
    }
    
    public static String getResult(int requestCode) {
        Log.i(TAG, "getResult code=" + requestCode);
        return resultMap.get(requestCode);
    }
    
}
