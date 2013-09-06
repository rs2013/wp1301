package com.weiplus.client;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.TreeSet;

import android.graphics.PixelFormat;
import android.graphics.Point;
import android.hardware.Camera;
import android.hardware.Camera.Size;
import android.os.Bundle;
import android.content.Intent;
import android.util.Log;
import android.view.Display;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.widget.RelativeLayout;

public class HarryPhotoMainActivity extends org.haxe.nme.GameActivity {
    
    public CamInfo camInfo;

    private static final String TAG = "HarryPhotoMainActivity";
    
    private SurfaceView blank;
    private SurfaceView preview;
    private RelativeLayout previewFrame;
    public Point windowSize;
    private Comparator<Size> areaComp = new Comparator<Size>() {
        @Override
        public int compare(Size lhs, Size rhs) {
            return rhs.width * rhs.height - lhs.width * lhs.height;
        }
    };
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        Log.i(TAG, "My onCreate executed!!");

        camInfo = new CamInfo();
        int[][] cis = camInfo.cameraInfos = new int[Camera.getNumberOfCameras()][2];
        for (int i = 0; i < cis.length; i++) {
            Camera.CameraInfo ci = new Camera.CameraInfo();
            Camera.getCameraInfo(i, ci);
            cis[i][0] = ci.facing;
            cis[i][1] = ci.orientation;
        }
        camInfo.cameraId = -1;
 
        blank = new SurfaceView(this);
        SurfaceHolder holder = blank.getHolder();
        holder.addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceDestroyed(SurfaceHolder holder) { }

            @Override
            public void surfaceCreated(SurfaceHolder holder) { }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                Log.i(TAG, "blank surfaceChanged: format=" + format+",w=" + width+",h="+height);
                if (windowSize == null) {
                    windowSize = new Point(height, width); // width/height reversed for portrait mode
                }
            }
        });
        
        preview = new SurfaceView(this);
        holder = preview.getHolder();
        holder.addCallback(new SurfaceHolder.Callback() {

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) { }

            @Override
            public void surfaceCreated(SurfaceHolder holder) { }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                Log.i(TAG, "preview surfaceChanged: format=" + format+",w=" + width+",h="+height);
//                if (windowSize == null) {
//                    windowSize = new Point(height, width); // width/height reversed for portrait mode
//                }
//                if (camInfo.camera != null) camInfo.camera.startPreview();
            }
        });
        holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);

        previewFrame = new RelativeLayout(this);
        Display display = getWindowManager().getDefaultDisplay();
        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(display.getWidth(), display.getHeight());
        params.leftMargin = 0;
        params.topMargin = 0;
        previewFrame.addView(blank, params);
        params = new RelativeLayout.LayoutParams(1, 1);
        params.leftMargin = 0;
        params.topMargin = 0;
        previewFrame.addView(preview, params);
        
        setContentView(previewFrame, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        addContentView(mView, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        
    }
    
    public void closeCamera() {
        if (camInfo.camera != null) {
            try {
                camInfo.camera.stopPreview();
                camInfo.camera.release();
            } catch (Exception e) { }
            camInfo.camera = null;
        }
//        preview.getHolder().setType(SurfaceHolder.SURFACE_TYPE_NORMAL);
//        preview.setBackgroundColor(Color.BLACK);
//        Canvas canvas = preview.getHolder().lockCanvas();
//        if (canvas != null) {
//            canvas.drawColor(Color.BLACK);
//            preview.getHolder().unlockCanvasAndPost(canvas);
//        }
    }

    public void switchSurface(boolean openCamera, int top, int h) {
        SurfaceView open = openCamera ? preview : blank;
        SurfaceView close = openCamera ? blank : preview;
        RelativeLayout.LayoutParams layoutParams = (RelativeLayout.LayoutParams) open.getLayoutParams();
        layoutParams.width = windowSize.y;
        layoutParams.height = h;
        layoutParams.leftMargin = 0;
        layoutParams.topMargin = top;
        previewFrame.updateViewLayout(open, layoutParams);
        layoutParams = (RelativeLayout.LayoutParams) close.getLayoutParams();
        layoutParams.width = 1;
        layoutParams.height = 1;
        layoutParams.leftMargin = 0;
        layoutParams.topMargin = 0;
        previewFrame.updateViewLayout(close, layoutParams);
        mView.setFocusable(true);
        mView.setFocusableInTouchMode(true);
//        ViewGroup parent = (ViewGroup) mView.getParent();
//        parent.removeAllViews();
//        if (openCamera) {
//            setContentView(previewFrame, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
//        } else {
//            setContentView(blank, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
//        }
//        addContentView(mView, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
    }

    public void openCamera(int cameraId) {
        closeCamera();
//        preview.setBackgroundColor(Color.TRANSPARENT);
        camInfo.cameraId = cameraId;
        Camera camera = camInfo.camera = Camera.open(camInfo.cameraId);
        Camera.Parameters params = camInfo.params = camera.getParameters();

        int w = windowSize.x;
        int h = windowSize.y;
        double ratio = w / (double) h;
        double area = w * h;

        List<Camera.Size> preSizes = params.getSupportedPreviewSizes();
        for (Camera.Size s: preSizes) {
            Log.i(TAG, "Preview: width=" + s.width + ",height=" + s.height);
        }
        Size preSize = chooseSize(preSizes, ratio, area, area * 0.67, Double.MAX_VALUE);
        params.setPreviewSize(preSize.width, preSize.height);

        List<Size> picSizes = params.getSupportedPictureSizes();
        for (Camera.Size s: picSizes) {
            Log.i(TAG, "Picture: width=" + s.width + ",height=" + s.height);
        }
        int picArea = 1024 * 768;
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
        camInfo.flashModes = usedModes.toArray(new String[0]);
        List<String> focusModes = params.getSupportedFocusModes();
        if (focusModes != null && focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
            params.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
        }

        params.setPictureFormat(PixelFormat.JPEG);
        params.setJpegQuality(100); // 1-100

        camInfo.maxZoom = params.isZoomSupported() ? params.getMaxZoom() : -1;

//        Camera.CameraInfo info = new Camera.CameraInfo();
//        Camera.getCameraInfo(camInfo.cameraId, info);
//        if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
//            camInfo.rotation = 270;
//        } else {
//            camInfo.rotation = 90;
//        }
        camInfo.rotation = 90;

        double scale = windowSize.y / (double) preSize.height; // w > h for preview size
        int preHeight = (int) (preSize.width * scale);
//        RelativeLayout.LayoutParams layoutParams = (RelativeLayout.LayoutParams) preview.getLayoutParams();
//        layoutParams.width = windowSize.y;
//        layoutParams.height = preHeight;
//        layoutParams.leftMargin = 0;
//        layoutParams.topMargin = (w - preHeight) / 2;
//        previewFrame.updateViewLayout(preview, layoutParams);
//        layoutParams = (RelativeLayout.LayoutParams) blank.getLayoutParams();
//        layoutParams.width = 1;
//        layoutParams.height = 1;
//        layoutParams.leftMargin = 0;
//        layoutParams.topMargin = 0;
//        previewFrame.updateViewLayout(blank, layoutParams);
        switchSurface(true, (w - preHeight) / 2, preHeight);

        camera.setParameters(camInfo.params);
        try {
            camera.setDisplayOrientation(camInfo.rotation);
            camera.setPreviewDisplay(preview.getHolder());
        } catch (Exception ex) {
            Log.w(TAG, "openCamera failed, ex=" + ex.getMessage());
            ex.printStackTrace();
        }
        camera.startPreview();
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

    public static HarryPhotoMainActivity getInstance() {
        return (HarryPhotoMainActivity) org.haxe.nme.GameActivity.getInstance();
    }
    
    private static int varianceComp(double d1, double d2) {
        d1 = d1 * d1;
        d2 = d2 * d2;
        return d1 < d2 ? -1 : d1 > d2 ? 1 : 0;
    }

    @Override
    public void onResume() {
        super.onResume();
        Log.i(TAG, "onResume");
        com.umeng.analytics.MobclickAgent.onResume(this);
        if (camInfo.cameraId >= 0) {
            HaxeCamera.openCamera(camInfo.cameraId, null, null);
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        Log.i(TAG, "onPause");
        com.umeng.analytics.MobclickAgent.onPause(this);
        closeCamera();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.i(TAG, "onActivityResult: code=" + requestCode + ",result=" + resultCode + ",data=" + data);
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 22334) {
            HarryPhotoMainActivity.getInstance().mView.mActivity = this;
            return;
        }
        if (HpManager.getCandidate() != null) HpManager.getCandidate().onActivityResult(this, requestCode, resultCode, data);
        HaxeStub.onActivityResult(requestCode, resultCode, data);
    }

    public static void startCameraActivity() {
        HarryPhotoMainActivity main = HarryPhotoMainActivity.getInstance();
        Intent it = new Intent(main, CameraActivity.class);
        main.mView.mActivity = CameraActivity.getInstance();
        main.startActivityForResult(it, 22334);
        main.mView.renderNow();
    }
    
}

class CamInfo {
    public int[][] cameraInfos;
    public int cameraId;
    public Camera camera;
    public Camera.Parameters params;
    public int rotation;
    public double maxZoom;
    public String[] flashModes;
}
