package com.weiplus.client;

import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
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
        Bitmap big = loadSmallImage(path, maxArea, false);
        if (big == null) return null;
        
        maxArea = maxArea <= 0 ? Integer.MAX_VALUE : maxArea;
        int area = big.getWidth() * big.getHeight();
        Bitmap bm = big;
        if (area > maxArea) {
            double r = Math.sqrt(maxArea / (double) area);
            bm = Bitmap.createScaledBitmap(big, (int) (r * big.getWidth()), (int) (r * big.getHeight()), false);
            big.recycle();
        }
        return bm;
    }
    
    /**
     * 读取Alpha通道分离压缩的AR图像文件
     * @param path: 图像文件路径
     * @param maxArea: 载入后的最大面积（即总像素数=图像宽*图像高），为0则不限，即载入原始大小图片
     * @return Alpha通道合并后的半透明32位真彩位图
     */
    public static Bitmap loadArImage(String path, int maxArea) {
        Bitmap big = loadSmallImage(path, maxArea * 2, true);
        if (big == null) return null;
        // 因为alpha通道分离的图像宽度为原图的2倍，因此面积也是2倍
        maxArea = maxArea <= 0 ? Integer.MAX_VALUE : maxArea * 2; 
        
        int area = big.getWidth() * big.getHeight(); // 原始图面积
        Bitmap bm = big;
        if (area > maxArea) { // 原始面积大于最大面积，需要缩小
            double r = Math.sqrt(maxArea / (double) area); // 面积比例再开方，即一个维度的缩小比例
            bm = Bitmap.createScaledBitmap(big, (int) (r * big.getWidth()), (int) (r * big.getHeight()), false);
            big.recycle();
        }
        
        int w = bm.getWidth(), h = bm.getHeight(), w2 = w / 2;
        int[] pixels = new int[w * h];
        bm.getPixels(pixels, 0, w, 0, 0, w, h); // 把所有像素读取到数组
        bm.recycle();
        for (int i = h; --i >= 0;) { // 对每个扫描行
            for (int n = i * w, j = n + w2, jj = n + w; --j >= n;) { // 把右半扫描行的像素的Red值作为Alpha值合并到左半扫描行
                int alpha = (pixels[--jj] & 0x00FF0000) << 8; // 对ARGB排列的像素，把RED值左移8位即成为Alpha值
                pixels[j] = (pixels[j] & 0x00FFFFFF) | alpha; // 合并到左半扫描行的对应像素
            }
        }
        // 使用像素数组的左半部分创建一个新的图像，即结果图像
        Bitmap newbm = Bitmap.createBitmap(pixels, 0, w, w2, h, Config.ARGB_8888);
        return newbm;
    }
    
    public static Bitmap loadSmallImage(String path, int maxArea, boolean evenOnly) {
        if (maxArea <= 0) {
            return BitmapFactory.decodeFile(path);
        }
        int[] size = getImageSize(path);
        int sample = 1;
        if (evenOnly) {
            sample = 0;
            for (int ns = 2, area = size[0] * size[1]; maxArea * ns * ns <= area; ns += 2, sample += 2);
            if (sample == 0) sample = 1;
        } else {
            for (int ns = 2, area = size[0] * size[1]; maxArea * ns * ns <= area; ns++, sample++);
        }
        BitmapFactory.Options opt = new BitmapFactory.Options();
        opt.inSampleSize = sample;
        try {
            return BitmapFactory.decodeFile(path, opt);
        } catch (OutOfMemoryError e) {
            return null;
        }
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
