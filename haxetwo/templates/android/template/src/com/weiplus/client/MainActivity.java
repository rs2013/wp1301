package com.weiplus.client;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.TreeSet;

import android.graphics.PixelFormat;
import android.graphics.Point;
import android.hardware.Camera;
import android.hardware.Camera.CameraInfo;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.Size;
import android.os.Bundle;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.util.Log;
import android.view.Display;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.widget.RelativeLayout;

public class MainActivity extends org.haxe.nme.GameActivity implements SurfaceHolder.Callback {
    
    public CamInfo camInfo;

    private static final String TAG = "MainActivity";
    
    private SurfaceView blank;
    private SurfaceView preview;
    private RelativeLayout previewFrame;

    private boolean cameraReady = false;
    
    private Comparator<Size> areaComp = new Comparator<Size>() {
        
        @Override
        public int compare(Size lhs, Size rhs) {
            return rhs.width * rhs.height - lhs.width * lhs.height;
        }
    };
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.i(TAG, "onCreate");
        getWindow().setFormat(PixelFormat.TRANSLUCENT);
        requestWindowFeature(Window.FEATURE_NO_TITLE);

        blank = new SurfaceView(this);
        SurfaceHolder holder = blank.getHolder();
        holder.addCallback(new SurfaceHolder.Callback() {
            @Override 
            public void surfaceDestroyed(SurfaceHolder holder) { }

            @Override 
            public void surfaceCreated(SurfaceHolder holder) { }

            @Override 
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                Log.i(TAG, "blank surfaceChanged: w=" + width+",h="+height);
            }
        });
        
        preview = new SurfaceView(this);
        holder = preview.getHolder();
        holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
        holder.addCallback(this);
        
        previewFrame = new RelativeLayout(this);
        
        previewFrame.addView(blank, new LayoutParams(1, 1));
        previewFrame.addView(preview, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        
        setContentView(previewFrame, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        addContentView(mView, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        
    }
    
    @Override
    public void onResume() {
        super.onResume();
        Log.i(TAG, "onResume");
        com.umeng.analytics.MobclickAgent.onResume(this);
        if (!cameraReady) {
            return;
        }
        
        previewFrame.removeView(preview);
        preview = new SurfaceView(this);
        SurfaceHolder holder = preview.getHolder();
        holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
        holder.addCallback(this);
        RelativeLayout.LayoutParams params = null;
        if (camInfo.isOpen) {
            CamParam cp = camInfo.params[camInfo.cameraId];
            params = new RelativeLayout.LayoutParams(cp.viewWidth, cp.viewHeight);
            params.leftMargin = 0;
            params.topMargin = cp.viewTopMargin;
        } else {
            params = new RelativeLayout.LayoutParams(1, 1);
        }
        previewFrame.addView(preview, params);
        
        ((ViewGroup) mView.getParent()).removeView(mView);
        addContentView(mView, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        mView.setFocusable(true);
        mView.setFocusableInTouchMode(true);
    }

    @Override
    public void onPause() {
        super.onPause();
        Log.i(TAG, "onPause");
        com.umeng.analytics.MobclickAgent.onPause(this);
        if (cameraReady) {
            camInfo.camera.stopPreview();
            camInfo.camera.release();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.i(TAG, "onActivityResult: code=" + requestCode + ",result=" + resultCode + ",data=" + data);
        super.onActivityResult(requestCode, resultCode, data);
        if (HpManager.getCandidate() != null) HpManager.getCandidate().onActivityResult(this, requestCode, resultCode, data);
        HaxeStub.onActivityResult(requestCode, resultCode, data);
    }

    @Override 
    public void surfaceDestroyed(SurfaceHolder holder) {
    }

    @Override 
    public void surfaceCreated(SurfaceHolder holder) {
        Log.i(TAG, "preview surfaceChanged: cameraReady=" + cameraReady);
        if (!cameraReady) {
            return;
        }
        innerOpen(camInfo.cameraId);
    }

    @Override 
    public void surfaceChanged(final SurfaceHolder holder, int format, final int width, final int height) {
        Log.i(TAG, "preview surfaceChanged: w=" + width+",h="+height);
        if (!cameraReady) {
            new Thread() {
                @Override public void run() {
                    initCameras(holder, height, width);// width/height reversed for portrait mode
                }
            }.start();
            return;
        }
        camInfo.camera.startPreview();
    }
    
    public void openCamera(int cameraId) {
        if (!cameraReady) return;
        Log.i(TAG, "openCamera " + cameraId + ": current=" + camInfo.cameraId);
        if (camInfo.cameraId != cameraId) { // switch camera
            camInfo.camera.stopPreview();
            camInfo.camera.release();
            
            innerOpen(cameraId);
            camInfo.cameraId = cameraId;
        }
        try {
            camInfo.camera.startPreview();
        } catch (Exception ex) {
            Log.e(TAG, "openCamera, startPreview failed, ex=" + ex);
        }
        switchSurface(cameraId);
    }
    
    public void closeCamera() {
        if (!cameraReady) return;
        Log.i(TAG, "closeCamera " + camInfo.cameraId);
        switchSurface(-1);
    }

    /**
     * NOTE: in this method, w must always great than h
     * @param w: pixel distance of the longer side 
     * @param h: pixel distance of the shorter side
     */
    private void initCameras(SurfaceHolder holder, int w, int h) {
        camInfo = new CamInfo();
        camInfo.winWidth = h;
        camInfo.winHeight = w;
        camInfo.isOpen = false;
        boolean hasCamera = this.getApplicationContext()
                .getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA);
        
        int count = hasCamera ? Camera.getNumberOfCameras() : 0;
        camInfo.params = new CamParam[count];

        if (!hasCamera) return;

        double ratio = w / (double) h;
        double area = w * h;
        double picArea = 1024 * 768;
        
        for (int i = 0; i < count; i++) {
            CamParam cp = camInfo.params[i] = new CamParam();
            
            Camera.CameraInfo ci = new Camera.CameraInfo();
            Camera.getCameraInfo(i, ci);
            cp.facing = ci.facing;
            cp.orientation = ci.orientation;
            
            Camera camera = Camera.open(i);
            Parameters params = cp.params = camera.getParameters();
            
            List<Camera.Size> preSizes = params.getSupportedPreviewSizes();
            for (Camera.Size s: preSizes) {
                Log.i(TAG, "Camera " + i + ": Preview: width=" + s.width + ",height=" + s.height);
            }
            Size preSize = chooseSize(preSizes, ratio, area, area * 0.67, Double.MAX_VALUE);
            params.setPreviewSize(preSize.width, preSize.height);

            List<Size> picSizes = params.getSupportedPictureSizes();
            for (Camera.Size s: picSizes) {
                Log.i(TAG, "Camera " + i + ": Picture: width=" + s.width + ",height=" + s.height);
            }
            Size picSize = chooseSize(picSizes, ratio, picArea, picArea * 0.8, picArea * 2.0);
            params.setPictureSize(picSize.width, picSize.height);

            List<String> flashModes = params.getSupportedFlashModes();
            List<String> usedModes = new ArrayList<String>();
            if (flashModes != null) {
                if (flashModes.contains(Camera.Parameters.FLASH_MODE_AUTO)) {
                    params.setFlashMode(Camera.Parameters.FLASH_MODE_AUTO);
                    usedModes.add(Camera.Parameters.FLASH_MODE_AUTO);
                }
                if (flashModes.contains(Camera.Parameters.FLASH_MODE_ON)
                        && flashModes.contains(Camera.Parameters.FLASH_MODE_OFF)) {
                    usedModes.add(Camera.Parameters.FLASH_MODE_ON);
                    usedModes.add(Camera.Parameters.FLASH_MODE_OFF);
                }
            }
            cp.flashModes = usedModes.toArray(new String[0]);
            List<String> focusModes = params.getSupportedFocusModes();
            if (focusModes != null && focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
                params.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
            }

            params.setPictureFormat(PixelFormat.JPEG);
            params.setJpegQuality(100); // 1-100

            cp.maxZoom = params.isZoomSupported() ? params.getMaxZoom() : -1;
            cp.rotation = 90;

            double scale = h / (double) preSize.height; // w > h for preview size
            cp.viewWidth = h;
            cp.viewHeight = (int) (preSize.width * scale);
            cp.viewTopMargin = (int) ((w - cp.viewHeight) / 2);

            camera.release();
        }
        
        camInfo.cameraId = 0;
        innerOpen(0);
        
        this.runOnUiThread(new Runnable() {
            @Override public void run() {
                switchSurface(-1);
            }
        });
        cameraReady = true;
    }
    
    private void switchSurface(int cameraId) {
        if (!cameraReady) return;
        Log.i(TAG, "switchSurface " + cameraId + ",isopen=" + camInfo.isOpen);
//        if (camInfo.isOpen && cameraId >= 0 || !camInfo.isOpen && cameraId == -1) {
//            return;
//        }
        SurfaceView open = cameraId >= 0 ? preview : blank;
        SurfaceView close = cameraId >= 0 ? blank : preview;
        CamParam cp = cameraId >= 0 ? camInfo.params[cameraId] : null;
        
        RelativeLayout.LayoutParams layoutParams = (RelativeLayout.LayoutParams) open.getLayoutParams();
        layoutParams.width = cp == null ? camInfo.winWidth : cp.viewWidth;
        layoutParams.height = cp == null ? camInfo.winHeight : cp.viewHeight;
        layoutParams.leftMargin = 0;
        layoutParams.topMargin = cp == null ? 0 : cp.viewTopMargin;
        previewFrame.updateViewLayout(open, layoutParams);
        
        layoutParams = (RelativeLayout.LayoutParams) close.getLayoutParams();
        layoutParams.width = 1;
        layoutParams.height = 1;
        layoutParams.leftMargin = 0;
        layoutParams.topMargin = 0;
        previewFrame.updateViewLayout(close, layoutParams);
        
        mView.setFocusable(true);
        mView.setFocusableInTouchMode(true);
        
        camInfo.isOpen = cameraId >= 0 ? true : false;
    }
    
    private void innerOpen(int cameraId) {
        Log.i(TAG, "innerOpen: " + cameraId);
        try {
            camInfo.camera = Camera.open(cameraId);
        } catch (Exception ex) {
            Log.e(TAG, "innerOpen: camera in use, ex=" + ex);
            return;
        }
        camInfo.camera.setParameters(camInfo.params[cameraId].params);
        camInfo.camera.setDisplayOrientation(camInfo.params[cameraId].rotation);
        try {
            camInfo.camera.setPreviewDisplay(preview.getHolder());
        } catch (IOException e) {
            Log.e(TAG, "openCamera " + cameraId + ", open camera failed, ex=" + e);
        }
    }

    /**
     * @param list
     * @param width
     * @param height
     * @return
     */
    private Size chooseSize(List<Camera.Size> list, final double ratio, final double area, double minArea, double maxArea) {
        Collections.sort(list, areaComp);
        Comparator<Size> comp = new Comparator<Size>() {
            @Override
            public int compare(Size s1, Size s2) {
                int w1 = s1.width, h1 = s1.height, w2 = s2.width, h2 = s2.height;
                if (w1 < h1) { w1 = h1; h1 = s1.width; }
                if (w2 < h2) { w2 = h2; h2 = s2.width; }
                double dr1 = (w1 / (float) h1) - ratio, dr2 = (w2 / (float) h2) - ratio;
                int ret = varianceComp(dr1, dr2);
                return ret != 0 ? ret : varianceComp(w1 * h1 - area, w2 * h2 - area);
            }
            
        };
        TreeSet<Size> set = new TreeSet<Size>(comp);
        for (Size size: list) {
            int ar = size.width * size.height;
            if (size.width >= size.height && ar >= minArea && ar < maxArea) set.add(size);
        }
//        for (Size s: set) {
//            Log.i(TAG, "width=" + s.width + ",height=" + s.height + ",ratio=" + (s.width / (float) s.height));
//        }
        if (set.size() == 0) {
            Log.w(TAG, "best size not found, use the first one");
            return list.get(0);
        }
        return set.first();
    }

    public static MainActivity getInstance() {
        return (MainActivity) org.haxe.nme.GameActivity.getInstance();
    }
    
    private static int varianceComp(double d1, double d2) {
        d1 = d1 * d1;
        d2 = d2 * d2;
        return d1 < d2 ? -1 : d1 > d2 ? 1 : 0;
    }

}

class CamInfo {
    public int cameraId;
    public Camera camera;
    public boolean isOpen;
    public CamParam[] params;
    public int winWidth;
    public int winHeight;
}

class CamParam {
    public int facing;
    public int orientation;
    public int viewTopMargin;
    public int viewWidth;
    public int viewHeight;
    public Camera.Parameters params;
    public int rotation;
    public double maxZoom;
    public String[] flashModes;
}
