package com.weiplus.client;

import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;

import org.json.*;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Bitmap.Config;
import android.util.Log;
import android.view.View;

public class CameraUtils {

    public static final String AR_CACHE_DIR = "/sdcard/.harryphoto/ars_cache";
    public static final String ALBUM_DIR = "/sdcard/DCIM/MagicCamera";

    private static final String TAG = "CameraUtils";
    
    public static byte[] readStream(InputStream is) throws IOException {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        BufferedInputStream bis = new BufferedInputStream(is);
        byte[] bb = new byte[100000];
        for (int len = bis.read(bb); len > 0; len = bis.read(bb)) {
            bos.write(bb, 0, len);
        }
        return bos.toByteArray();
    }
    
    public static String readText(InputStream is) throws IOException {
        byte[] bb = readStream(is);
        return new String(bb, "UTF-8");
    }
    
    public static JSONObject readJsonFromFile(String path) throws Exception {
            InputStream is = new FileInputStream(new File(path));
            String jsonStr = CameraUtils.readText(is);
            is.close();
            return (JSONObject) new JSONTokener(jsonStr).nextValue();
    }
    
    public static String arCachePath(String url) {
        int idx = url.lastIndexOf("/");
        return AR_CACHE_DIR + "/" + url.substring(idx + 1);
    }

    public static boolean arCacheExists(String url) {
        String path = arCachePath(url);
        return new File(path).exists();
    }

    public static int[] getImageSize(String path) {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, options);
        return new int[] { options.outWidth, options.outHeight };
    }
    
    public static Bitmap loadImage(String path, int maxArea) {
        maxArea = maxArea <= 0 ? Integer.MAX_VALUE : maxArea;
        Bitmap big = null;
        try {
            FileInputStream is = new FileInputStream(path);
            big = BitmapFactory.decodeStream(is);
            is.close();
        } catch (IOException e) { 
            Log.e(TAG, "LoadImage, path=" + path + ",ex=" + e);
        }
        int area = big.getWidth() * big.getHeight();
        Bitmap bm = big;
        if (area > maxArea) {
            double r = Math.sqrt(maxArea / (double) area);
            bm = Bitmap.createScaledBitmap(big, (int) (r * big.getWidth()), (int) (r * big.getHeight()), false);
            big.recycle();
        }
        return bm;
    }
    
    public static Bitmap loadArImage(String path, int maxArea) {
        maxArea = maxArea <= 0 ? Integer.MAX_VALUE : maxArea;
        Bitmap big = null;
        try {
            FileInputStream is = new FileInputStream(path);
            big = BitmapFactory.decodeStream(is);
            is.close();
        } catch (IOException e) {
            Log.e(TAG, "LoadArImage, path=" + path + ",ex=" + e);
        }
        int area = big.getWidth() * big.getHeight();
        Bitmap bm = big;
        if (area > maxArea) {
            double r = Math.sqrt(maxArea / (double) area);
            bm = Bitmap.createScaledBitmap(big, (int) (r * big.getWidth()), (int) (r * big.getHeight()), false);
            big.recycle();
        }
        
        int w = bm.getWidth(), h = bm.getHeight(), w2 = w / 2;
        int[] pixels = new int[w * h];
        bm.getPixels(pixels, 0, w, 0, 0, w, h);
        bm.recycle();
        for (int i = h; --i >= 0;) {
            for (int n = i * w, j = n + w2, jj = n + w; --j >= n;) {
                int alpha = (pixels[--jj] & 0x00FF0000) << 8; // use red channel
                pixels[j] = (pixels[j] & 0x00FFFFFF) | alpha;
            }
        }
        Bitmap newbm = Bitmap.createBitmap(pixels, 0, w, w2, h, Config.ARGB_8888);
        return newbm;
    }
    
    public static JSONObject getUserData(View view) {
        CharSequence cs = view.getContentDescription();
        String str = cs == null ? "{}" : cs.toString();
        JSONObject ret = null;
        try {
            ret = (JSONObject) new JSONTokener(str).nextValue();
        } catch (Exception ex) {
            Log.e(TAG, "getUserData, str=" + str + ",ex=" + ex);
        }
        return ret;
    }
    
    public static String[] getUrlInfo(String descr) {
        if (descr == null) return null;
        String[] arr = descr.split(" ");
        for (int i = 0; i < arr.length; i++) {
            String low = arr[i].toLowerCase();
            boolean isUrl = false;
            if ((isUrl = low.startsWith("url:")) || low.startsWith("shop:")) {
                String[] ret = new String[2];
                ret[0] = isUrl ? "url" : "shop";
                ret[1] = isUrl ? arr[i].substring(4) : arr[i].substring(5);
                return ret;
            }
        }
        return null;
    }
    
}
