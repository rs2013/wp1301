package com.vbo.harry_camera.utils;

import android.content.Context;
import android.content.pm.PackageManager;
import android.hardware.Camera;
import android.hardware.Camera.CameraInfo;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.Size;
import android.util.Log;

import com.weiplus.client.BuildConfig;
import com.vbo.harry_camera.HarryCameraApp;
import com.weiplus.client.R;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class CameraUtil {

    private static final String TAG = "CameraUtil";
    private static List<MyCameraInfo> sInfos = new ArrayList<MyCameraInfo>();
    private static boolean sHasCamera;
    private static int sCurrentCameraId = -1;
    //public static List<Size> sSupportedPreviewSizes;
    private static Size sBestPreviewSize;
    private static Size sBestPicture;
    public static boolean isBackCamera = true;

    public static boolean hasFrontCamera(Context context) {
        return hasCamera(context, CameraInfo.CAMERA_FACING_FRONT);
    }

    public static boolean hasBackCamera(Context context) {
        return hasCamera(context, CameraInfo.CAMERA_FACING_BACK);
    }

    private static boolean hasCamera(Context context, int Mode) {
        if (sHasCamera) {
            for (MyCameraInfo info : sInfos) {
                if (info.mCameraInfo.facing == Mode) {
                    return true;
                }
            }
        }
        return false;
    }

    private static boolean hasCamera(Context context) {
        if (context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA)){
            return true;
        } else {
            return false;
        }
    }

    public static boolean init(Context context) {
        if (hasCamera(context)) {
            int count = Camera.getNumberOfCameras();
            if (BuildConfig.DEBUG) 
                Log.d(TAG, "init and camera count = " + count);
            for (int i = 0; i < count; i++) {
                CameraInfo info = new CameraInfo();
                Camera.getCameraInfo(i, info);
                Camera camera = Camera.open(i);
                Parameters parameters = camera.getParameters();
                camera.release();
                camera = null;
                sInfos.add(new MyCameraInfo(info, parameters));
            }
            return sHasCamera = true;
        } else {
            return sHasCamera = false;
        }
    }

    private static int getFrontCameraId() {
        return getCameraId(CameraInfo.CAMERA_FACING_FRONT);
    }

    private static int getBackCameraId() {
        return getCameraId(CameraInfo.CAMERA_FACING_BACK);
    }

    private static int getCameraId(int mode) {
        if (sHasCamera) {
            if (BuildConfig.DEBUG)
                Log.d(TAG, "getCameraId and sHasCamera");
            for (int id = 0; id < sInfos.size(); id++) {
                if (BuildConfig.DEBUG)
                    Log.d(TAG, "sInfos.get(id).facing = " + sInfos.get(id).mCameraInfo.facing);
                if (sInfos.get(id).mCameraInfo.facing == mode) {
                    return id;
                }
            }
        }
        Log.w(TAG, "getCameraId and no id");
        return -1;
    }

    public static int getCurrentId() {
        return sCurrentCameraId;
    }

    public static int setCurrentMode(boolean isBack) {
        if (BuildConfig.DEBUG)
            Log.d(TAG, "setCurrentMode and isBack = " + isBack
                    + " getBackCameraId() = " + getBackCameraId()
                    + " getFrontCameraId() = " + getFrontCameraId());
        if (isBack && getBackCameraId() >= 0){
            isBackCamera = true;
            return sCurrentCameraId = getBackCameraId();
        } else {
            isBackCamera = false;
            return sCurrentCameraId = getFrontCameraId();
        }
    }

    public static int getCurrentCameraOrientation() {
        if (sCurrentCameraId < 0) {
            throw new IllegalStateException(" current camera id is " + sCurrentCameraId);
        }
        if (BuildConfig.DEBUG)
            Log.d(TAG, "camera orientation" +  sInfos.get(sCurrentCameraId).mCameraInfo.orientation);
        return sInfos.get(sCurrentCameraId).mCameraInfo.orientation;
    }

    private static class MyCameraInfo {

        private CameraInfo mCameraInfo;
        private Parameters mParameters;

        private MyCameraInfo(CameraInfo cameraInfo, Parameters parameters) {
            mCameraInfo = cameraInfo;
            mParameters = parameters;
        }
    }

    @SuppressWarnings("deprecation")
    public static int[] makesurePreviewPadding(Context context, boolean isBack) {
        int[] paddings = new int[4];
        float screenWidth = HarryCameraApp.sDefaultDisplay.getWidth();
        float screenHeight = HarryCameraApp.sDefaultDisplay.getHeight();
        float previewWidth = 0;
        float previewHeight = 0;
        float bottomHeight = context.getResources().getDimension(R.dimen.bottom_bar_height);
        if (sInfos == null || sInfos.size() == 0)
            return new int[]{0,50,0,(int) bottomHeight + 50};
        Parameters parameters = isBack
                ? sInfos.get(getBackCameraId()).mParameters 
                        : sInfos.get(getFrontCameraId()).mParameters;
        int cameraOrientation = getCurrentCameraOrientation();
//        List<Size> sizes =  parameters.getSupportedPreviewSizes();
//        for (Size size : sizes) {
//            if (BuildConfig.DEBUG)
//                Log.d(TAG, "size = [" + size.width + "," + size.height + "]");
//            previewWidth = size.width;
//            previewHeight = size.height;
//            break;
//        }
        Size bestPreviewSize = getBestPreviewSize(parameters, cameraOrientation);
        if (bestPreviewSize != null) {
            previewWidth = bestPreviewSize.width;
            previewHeight = bestPreviewSize.height;
        }
        float paddinghorizontal = 0f;
        float paddingvertical = 0f;
        float ratioScreen = screenWidth / (screenHeight - bottomHeight);
        float ratioPreview = (cameraOrientation % 180) == 90 ? previewHeight / previewWidth : previewWidth / previewHeight;
        if (BuildConfig.DEBUG)
            Log.d(TAG, "screenWidth = " + screenWidth
                    + " screenHeight = " + screenHeight
                    + " previewWidth = " + previewWidth
                    + " previewHeight = " + previewHeight
                    + " bottomHeight = " + bottomHeight
                    + " ratioScreen = " + ratioScreen
                    + " ratioPreview = " + ratioPreview);
        if (ratioScreen > ratioPreview) {
            paddingvertical = screenHeight - bottomHeight - (previewHeight * screenWidth / previewWidth);
        } else if (ratioPreview > ratioScreen){
            paddinghorizontal = screenWidth - (previewWidth * (screenHeight - bottomHeight) / previewHeight);
        }
        paddings[0] = (int) (paddinghorizontal / 2);
        paddings[1] = (int) (paddingvertical / 2);
        paddings[2] = (int) (paddinghorizontal / 2);
        paddings[3] = (int) (paddingvertical / 2 + bottomHeight);
        //return paddings;
        // TODO
        return new int[]{0,50,0,(int) bottomHeight + 50};
    }

    public static Size getBestPreviewSize(Camera.Parameters parameters, int cameraOrientation) {
        List<Size> sizes = parameters.getSupportedPreviewSizes();
        Collections.sort(sizes, new Comparator<Size>() {
            @Override
            public int compare(Size lhs, Size rhs) {
                int result = lhs.width - rhs.width; 
                if (result == 0) result = lhs.height - rhs.height;
                return result;
            }

        });
        for (Size size : sizes) {
            Log.d(TAG, "preview size = " + size.width + "," + size.height);
            if (cameraOrientation % 180 == 0 ? size.width >= 720 : size.height >= 720){
                return size;
            }
        }
        return null;
    }

    public static Size getBestPictureSize(Camera.Parameters parameters,int cameraOrientation ) {
        List<Size> sizes = parameters.getSupportedPictureSizes();
        Collections.sort(sizes, new Comparator<Size>() {
            @Override
            public int compare(Size lhs, Size rhs) {
                int result = lhs.width - rhs.width; 
                if (result == 0) result = lhs.height - rhs.height;
                return result;
            }

        });
        for (Size size : sizes) {
            Log.d(TAG, "pic size = " + size.width + "," + size.height);
            if (cameraOrientation % 180 == 0 ? size.width >= 720 : size.height >= 720){
                return size;
            }
        }
        return null;
    }
}
