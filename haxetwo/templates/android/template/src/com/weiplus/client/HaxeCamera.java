package com.weiplus.client;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;

import org.haxe.nme.HaxeObject;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.hardware.Camera;
import android.hardware.Camera.AutoFocusCallback;
import android.hardware.Camera.CameraInfo;
import android.util.Log;

public class HaxeCamera {
    
    private static final String TAG = "HaxeCamera";

    private HaxeCamera() { }
    
    public static int getNumberOfCameras() {
        return MainActivity.getInstance().camInfo.params.length;
    }
    
    public static int getCurrentCameraId() {
        return MainActivity.getInstance().camInfo.cameraId;
    }
    
    /**
     * 
     * @param cameraId
     * @return [ facing (0/1), orientation(0/90/180/270) ]
     */
    public static int[] getCameraInfo(int cameraId) {
        CamParam param = MainActivity.getInstance().camInfo.params[cameraId];
        int[] ret = new int[] { param.facing, param.orientation };
        return ret;
    }
    
    public static void switchOrientation() {
        CamInfo info = MainActivity.getInstance().camInfo;
        CamParam param = info.params[info.cameraId];
        if (info.params[info.cameraId].facing == Camera.CameraInfo.CAMERA_FACING_BACK) return;
        param.rotation = param.rotation == 90 ? 270 : 90;
        info.camera.stopPreview();
        try {
            info.camera.setDisplayOrientation(param.rotation);
        } catch (Exception ex) {
            Log.w(TAG, "setDisplayOrientation failed, ex=" + ex.getMessage());
        }
        info.camera.startPreview();
    }
    
    public static void openCamera(final int cameraId, final HaxeObject haxeObj, final String callbackName) {
        final MainActivity inst = MainActivity.getInstance();
        inst.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                CamInfo info = inst.camInfo;
                if (cameraId >= 0 && cameraId < info.params.length) {
                    inst.openCamera(cameraId);
                }
                if (haxeObj != null && callbackName != null) {
                    //try { Thread.sleep(300); } catch (Exception ex) { }
                    haxeObj.call2(callbackName, "ok", "");
                }
            }
        });
    }
    
    public static void closeCamera() {
        final MainActivity inst = MainActivity.getInstance();
        inst.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                inst.closeCamera();
            }
        });
    }
    
    public static String[] getFlashModes() {
        CamInfo info = MainActivity.getInstance().camInfo;
        CamParam param = info.params[info.cameraId];
        return param.flashModes;
    }
    
    public static void switchFlashMode() {
        CamInfo info = MainActivity.getInstance().camInfo;
        CamParam param = info.params[info.cameraId];
        String[] modes = param.flashModes;
        if (modes.length == 0) return;
        Camera.Parameters params = info.camera.getParameters();
        String curm = params.getFlashMode();
        int i = 0;
        for (; i < modes.length; i++) {
            if (modes[i].equals(curm)) {
                params.setFlashMode(modes[(i + 1) % modes.length]);
                break;
            }
        }
        if (i == modes.length) { // not found
            params.setFlashMode(modes[0]);
        }
        info.camera.setParameters(params);
    }
    
    public static double getMaxZoom() {
        CamInfo info = MainActivity.getInstance().camInfo;
        CamParam param = info.params[info.cameraId];
        return param.maxZoom;
    }
    
    public static double getZoom() {
        if (getMaxZoom() < 0) return 0;
        CamInfo info = MainActivity.getInstance().camInfo;
        return info.camera.getParameters().getZoom();
    }
    
    public static void setZoom(double zoom) {
        double maxZoom = getMaxZoom();
        if (maxZoom < 0) return;
        zoom = zoom < 0 ? 0 : zoom > maxZoom ? maxZoom : zoom;
        Camera camera = MainActivity.getInstance().camInfo.camera;
        Camera.Parameters params = camera.getParameters();
        params.setZoom((int) zoom);
        camera.setParameters(params);
    }
    
    public static void snap(final String path, final HaxeObject haxeObj, final String callbackName) {
        final CamInfo info = MainActivity.getInstance().camInfo;
        final CamParam param = info.params[info.cameraId];
        final Camera.PictureCallback jpegCb = new Camera.PictureCallback() {
            
            @Override
            public void onPictureTaken(byte[] data, Camera camera) {
                try {
                    Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
                    Matrix matrix = new Matrix();
                    matrix.postRotate(param.orientation);
                    if (param.facing == CameraInfo.CAMERA_FACING_FRONT) {
                        matrix.postScale(-1, 1);
                        matrix.postTranslate(bitmap.getHeight(),0);
                    }
                    Bitmap newbmp = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), 
                            bitmap.getHeight(), matrix, false);
                    File f = new File(path);
                    if (!f.getParentFile().exists()) f.getParentFile().mkdirs();
                    BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(f));
                    newbmp.compress(Bitmap.CompressFormat.JPEG, 85, bos);
                    bos.close();
                    HaxeCamera.closeCamera();
                    //Thread.sleep(1800);
                    haxeObj.call2(callbackName, "ok", path);
                } catch (Exception ex) {
                    Log.e(TAG, "failed to save picture: " + path);
                    haxeObj.call2(callbackName, "error", ex.getMessage());
                }
            }
        };
        if (param.params.getFocusMode() == Camera.Parameters.FOCUS_MODE_AUTO) {
            info.camera.autoFocus(new AutoFocusCallback() {

                @Override
                public void onAutoFocus(boolean success, Camera camera) {
                    if (success) {
                        camera.takePicture(null, null, jpegCb);
                    }
                }
                
            });
        } else {
            info.camera.takePicture(null, null, jpegCb);
        }
    }
    
}
