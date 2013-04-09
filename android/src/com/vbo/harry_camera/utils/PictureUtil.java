package com.vbo.harry_camera.utils;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.RectF;
import android.os.Environment;
import android.util.Log;
import android.view.ViewGroup.MarginLayoutParams;

import com.vbo.harry_camera.data.DataHelper;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

public class PictureUtil {

    public static final int MODE_FINGER = 1;
    public static final int MODE_RING   = 2;
    public static final int MODE_MIX    = 3;

    private static final String DIR_MY_PHOTOS = "HarryCamera_MyPhotos";
    private static final String DIR_POPULAR = "HarryCamera_Populars";
    private static final String TAG = "PictureUtil";

    private static final int FINE_TUNING = /*6*/0;
    private static final float FINE_TUNING_SCALE = /*1.1*/1f;
    private static final float FINE_TUNING_TRANSLATE = /*-5*/0;

    public static final int PIC_SIZE_SMALL = 1;
    public static final int PIC_SIZE_NORMAL = 2;
    public static final int PIC_SIZE_LARGE = 3;
    public static final int PIC_SIZE_EXTRA_LARGE = 4;
    public static final int PIC_SIZE_DEFAULT = PIC_SIZE_NORMAL;

    @Deprecated
    public static String savePic(byte[] data) {
        File pictureFile = getMyPhotosFile();
        if (pictureFile == null){
            Log.w(TAG, "Error creating media file, check storage permissions ");
            return null;
        }
        try {
            FileOutputStream fos = new FileOutputStream(pictureFile);
            fos.write(data);
            fos.close();
        } catch (FileNotFoundException e) {
            Log.w(TAG, "File not found: " + e.getMessage());
        } catch (IOException e) {
            Log.w(TAG, "Error accessing file: " + e.getMessage());
        }
        return pictureFile.getPath();
    }

    public static File savePic(Bitmap bitmap) {

        File pictureFile = getMyPhotosFile();

        if (pictureFile == null){
            Log.w(TAG, "Error creating media file, check storage permissions: ");
            return null;
        }
        try {
            FileOutputStream fos = new FileOutputStream(pictureFile);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
            fos.flush();
            fos.close();
        } catch (FileNotFoundException e) {
            Log.w(TAG, "File not found: " + e.getMessage());
        } catch (IOException e) {
            Log.w(TAG, "Error accessing file: " + e.getMessage());
        }
        return pictureFile;
    }

    @SuppressLint("SimpleDateFormat")
    public static File getMyPhotosFile(){

        File myPhotosStorageDir = getMyPhotosDir();
        if (myPhotosStorageDir == null) {
            return null;
        }

        // Create a media file name
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        File mediaFile = new File(myPhotosStorageDir.getPath() + File.separator +
                "IMG_" + timeStamp  + ".jpg");
        return mediaFile;
    }


    public static Bitmap rotatePic(byte[] data) {
        if (data == null || data.length == 0){
            return null;
        }
        Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
        Matrix matrix = new Matrix();
        matrix.postRotate(90); 
        Bitmap bitmapRotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(),
                bitmap.getHeight(), matrix, true);
        bitmap.recycle();
        return bitmapRotated;
    }

    // XXX 有误差
    public static Bitmap scalePic(Bitmap bitmap, float ringWidth) {
        if (bitmap == null)
            return null;
        float w = bitmap.getWidth();
        float h = bitmap.getHeight();
        Matrix matrix = new Matrix();
        float sx = ringWidth / w;
        matrix.postScale(sx, sx);
        Bitmap scaled = Bitmap.createBitmap(bitmap, 0, 0, (int)w,
                (int) h, matrix, true);
        bitmap.recycle();
        return scaled;
    }

 // XXX 有误差
    public static Bitmap scalePic(Bitmap bitmap, float ringWidth, float ringHeight) {
        if (bitmap == null)
            return null;
        float w = bitmap.getWidth();
        float h = bitmap.getHeight();
        Matrix matrix = new Matrix();
        float sx = ringWidth / w;
        float sy = ringHeight / h;
        matrix.postScale(sx, sy);
        Bitmap scaled = Bitmap.createBitmap(bitmap, 0, 0, (int)w,
                (int) h, matrix, true);
        bitmap.recycle();
        return scaled;
    }

    public static File savePic(Context context, byte[] data, int fingerWidth, int fingerHeight,
            int ringIndex, int ringWidth, int ringHeight, Matrix ringMatrix, int top, int left) {
        if (data == null) {
            return null;
        }
        Bitmap bitmapFinger = rotatePic(data);
        Bitmap scaled = scalePic(bitmapFinger, ringWidth);
        Bitmap bitmapRing = ((BitmapDrawable) context.getResources().getDrawable(DataHelper.TEST_FITTING[ringIndex])).getBitmap();
        Bitmap newBitmap = Bitmap.createBitmap(ringWidth + FINE_TUNING, fingerHeight * ringWidth / fingerWidth + FINE_TUNING, Config.ARGB_8888);
        Canvas cv = new Canvas(newBitmap);
        cv.drawBitmap(scaled, left , top, null);
        cv.drawBitmap(bitmapRing, ringMatrix, null);
        cv.save(Canvas.ALL_SAVE_FLAG);
        bitmapFinger.recycle();
        scaled.recycle();
        return savePic(newBitmap);
    }

    public static File savePic(Context context,int ringIndex, int ringWidth, int ringHeight, Matrix ringMatrix,
            Bitmap finger, int fingerWidth, int fingerHeight,
            int left, int top) {
        if (finger == null)
            return null;
        Bitmap bitmapRing = ((BitmapDrawable) 
                context.getResources().getDrawable(DataHelper.TEST_FITTING[ringIndex])).getBitmap();
        Bitmap newBitmap = Bitmap.createBitmap(
                ringWidth + FINE_TUNING, fingerHeight * ringWidth / fingerWidth + FINE_TUNING,
                Config.ARGB_8888);
        Canvas cv = new Canvas(newBitmap);
        cv.drawBitmap(finger, left , top, null);
        ringMatrix.postScale(FINE_TUNING_SCALE, FINE_TUNING_SCALE);
        ringMatrix.postTranslate(FINE_TUNING_TRANSLATE, 0);
        cv.drawBitmap(bitmapRing, ringMatrix, null);
        cv.save(Canvas.ALL_SAVE_FLAG);
        return savePic(newBitmap);
    }

    public static File savePic(Context context,Bitmap ring, Matrix ringMatrix,
            Bitmap finger, int fingerWidth, int fingerHeight) {
        if (finger == null || ring == null)
            return null;
        Bitmap bitmapRing = ring;
        /*RectF point = new RectF();
        ringMatrix.mapRect(point);
        if (BuildConfig.DEBUG)
            Log.d(TAG, "point = [" + point.left + ", " + point.top + ", "
                    + point.right + ", " + point.bottom + "]");
        if (BuildConfig.DEBUG)
            Log.d(TAG, "fingerWidth = "  + fingerWidth + " fingerHeight = " + fingerHeight
                    + " finger : [" + finger.getWidth() + ", " + finger.getHeight() + "]"
                    + " ring : [" + ring.getWidth() + ", " + ring.getHeight() + "]");*/
        Bitmap newBitmap = Bitmap.createBitmap(
                finger.getWidth(), finger.getHeight(),
                Config.ARGB_8888);
        Canvas cv = new Canvas(newBitmap);
        cv.drawBitmap(finger, 0 , 0, null);
        /*float tranX = point.left * finger.getWidth() / fingerWidth -  point.left;
        float tranY = point.top * finger.getHeight() / fingerHeight -  point.top;
        ringMatrix.postTranslate(tranX, tranY);
        ringMatrix.postScale(((float) finger.getWidth()) / ((float) fingerWidth),
                ((float) finger.getHeight()) / ((float) fingerHeight));
        RectF point2 = new RectF(); 
        ringMatrix.mapRect(point2);
        if (BuildConfig.DEBUG)
            Log.d(TAG, "point2 = [" + point2.left + ", " + point2.top + ", "
                    + point2.right + ", " + point2.bottom + "]");*/
        cv.drawBitmap(bitmapRing, ringMatrix, null);
        cv.save(Canvas.ALL_SAVE_FLAG);
        return savePic(newBitmap);
    }

    public static File getMyPhotosDir() {
        File mediaStorageDir = new File(Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES), DIR_MY_PHOTOS);
        if (!mediaStorageDir.exists()){
            if (!mediaStorageDir.mkdirs()){
                Log.d("MyCameraApp", "failed to create directory");
                return null;
            }
        }
        return mediaStorageDir;
    }

    public static File getPopularsDir() {
        File mediaStorageDir = new File(Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES), DIR_POPULAR);
        if (!mediaStorageDir.exists()){
            if (!mediaStorageDir.mkdirs()){
                Log.d("MyCameraApp", "failed to create directory");
                return null;
            }
        }
        return mediaStorageDir;
    }

    public static String[] getMyPhotosPath() {
        final File myPhotosDir = getMyPhotosDir();
        if (myPhotosDir == null) {
            return null;
        }
        String[] myPhotosPathList = myPhotosDir.list(new FilenameFilter() {
            
            @Override
            public boolean accept(File dir, String filename) {
                // TODO Auto-generated method stub
                if (dir.equals(myPhotosDir)) {
                    if (filename.endsWith("jpg")) {
                        return true;
                    } else {
                        // ignore other 
                    }
                } else {
                    // ignore sub dir
                }
                return false;
            }
        });
        return myPhotosPathList;
    }

    public static String[] getPopularsPath() {
        final File popularsDir = getPopularsDir();
        String[] popularsPathList = popularsDir.list(new FilenameFilter() {
            
            @Override
            public boolean accept(File dir, String filename) {
                // TODO Auto-generated method stub
                if (dir.equals(popularsDir)) {
                    if (filename.endsWith("jpg")) {
                        return true;
                    } else {
                        // ignore other 
                    }
                } else {
                    // ignore sub dir
                }
                return false;
            }
        });
        return popularsPathList;
    }

    public static Bitmap decodePicToBitmap(String path , int Sizelevel) {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, options);
        int maxNumPixels = 240 * 240;
        switch (Sizelevel) {
            case PIC_SIZE_SMALL:
                maxNumPixels = 120 * 160;
                break;
            case PIC_SIZE_NORMAL:
                maxNumPixels = 240 * 320;
                break;
            case PIC_SIZE_LARGE:
                maxNumPixels = 360 * 480;
                break;
            case PIC_SIZE_EXTRA_LARGE:
                maxNumPixels = 480 * 720;
                break;

        }
        options.inSampleSize = computeSampleSize(options, -1, 320 * 480);
        options.inJustDecodeBounds = false;
        Bitmap b = null;
        try {
            b = BitmapFactory.decodeFile(path, options);
        } catch (Exception e) {
            Log.w(TAG, "during decode file" + path, e);
        }
        return b;
    }

    private static int computeSampleSize(BitmapFactory.Options options,
            int minSideLength, int maxNumOfPixels) {
        int initialSize = computeInitialSampleSize(options, minSideLength,
                maxNumOfPixels);
        int roundedSize;
        if (initialSize <= 8) {
            roundedSize = 1;
            while (roundedSize < initialSize) {
                roundedSize <<= 1;
            }
        } else {
            roundedSize = (initialSize + 7) / 8 * 8;
        }
        return roundedSize;
    }

    private static int computeInitialSampleSize(BitmapFactory.Options options,
            int minSideLength, int maxNumOfPixels) {
        double w = options.outWidth;
        double h = options.outHeight;
        int lowerBound = (maxNumOfPixels == -1) ? 1 :
                (int) Math.ceil(Math.sqrt(w * h / maxNumOfPixels));
        int upperBound = (minSideLength == -1) ? 128 :
                (int) Math.min(Math.floor(w / minSideLength),
                        Math.floor(h / minSideLength));
        if (upperBound < lowerBound) {
            // return the larger one when there is no overlapping zone.
            return lowerBound;
        }

        if ((maxNumOfPixels == -1) &&
                (minSideLength == -1)) {
            return 1;
        } else if (minSideLength == -1) {
            return lowerBound;
        } else {
            return upperBound;
        }
    }

    public static File saveIcon(Context context, Bitmap bitmap) {

        File pictureFile = new File("/Android/data/" + context.getPackageName() + "/files/" + System.currentTimeMillis() + ".jpg");

        try {
            FileOutputStream fos = new FileOutputStream(pictureFile);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
            fos.flush();
            fos.close();
        } catch (FileNotFoundException e) {
            Log.w(TAG, "File not found: " + e.getMessage());
        } catch (IOException e) {
            Log.w(TAG, "Error accessing file: " + e.getMessage());
        }
        return pictureFile;
    }
}
