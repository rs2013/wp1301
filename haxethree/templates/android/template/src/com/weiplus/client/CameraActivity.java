package com.weiplus.client;

import java.io.*;
import java.util.*;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.graphics.PointF;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.BitmapDrawable;
import android.hardware.Camera;
import android.hardware.Camera.AutoFocusCallback;
import android.hardware.Camera.CameraInfo;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.Size;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.util.Log;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnTouchListener;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.widget.HorizontalScrollView;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ImageView.ScaleType;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import org.json.*;

public class CameraActivity extends Activity implements SurfaceHolder.Callback, OnTouchListener {
    
    private static final String TAG = "CameraActivity";
    private static final int ALBUM_AS_BG = 1110;
    private static final int ALBUM_AS_AR = 1111;
    private static final int AR_ICON_SIZE = 140;
    private static final int AR_ICON_MAX_AREA = 14400; // 120^2
    private static final int AR_MAX_AREA = 200000;
    
    private static CamInfo camInfo;
    private static double dpFactor = 1.0;
    
    private static JSONArray folderList;

    private PointF prevCanvasTouch0 = null;
    private PointF prevCanvasTouch1 = null;
    private PointF prevCtrlTouch = null;
    
    private static Comparator<Size> areaComp = new Comparator<Size>() {
        
        @Override
        public int compare(Size lhs, Size rhs) {
            return rhs.width * rhs.height - lhs.width * lhs.height;
        }
    };
    
    private RelativeLayout previewFrame;
    private SurfaceView preview;
    private RelativeLayout canvas;
    private RelativeLayout arBoxFrame;
    private RelativeLayout arBox;
    private ImageView currentAr;
    private int currentCid = -1;
    private LinearLayout arSelect;
    
    private ImageButton btnClose;
    private ImageButton btnSwitch;
    private ImageButton btnFlash;
    private ImageButton btnArDel;
    private ImageButton btnArInf;
    private ImageButton btnArMir;
    private ImageButton btnArRot;
    private ImageButton btnArCtrl;
    private ImageButton btnAlbum;
    private ImageButton btnSnap;
//    private ImageButton btnUpdate;
    
    private boolean currentArChanged = true;
    
    private JSONObject drawingData;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.i(TAG, "onCreate");
        
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        this.setContentView(R.layout.activity_camera);

        previewFrame = (RelativeLayout) findViewById(R.id.previewFrame);
        previewFrame.post(new Runnable() {

            @Override
            public void run() {
                int w = previewFrame.getWidth();
                int h = previewFrame.getHeight();
                findSizes(h, w);
                dpFactor = w / 640.0;
                if (camInfo.params.length < 2) { // no switch
                    btnSwitch.setVisibility(View.INVISIBLE);
                }
                createPreview();
                showFolder(-1);
                initCanvas();
            }
            
        });
        
        canvas = (RelativeLayout) findViewById(R.id.canvas);
        canvas.setOnTouchListener(new OnTouchListener() {

            @Override
            public boolean onTouch(View v, MotionEvent event) {
                if ((event.getAction() & MotionEvent.ACTION_MASK) != MotionEvent.ACTION_DOWN) return false;
                float x = event.getX(0), y = event.getY(0);
                int found = 0; // 0: not found, 1: currentAr, 2: found new
                for (int i = canvas.getChildCount(); --i >= 0;) {
                    View sub = canvas.getChildAt(i);
                    if (sub instanceof RelativeLayout) continue; // arbox
                    ImageView im = (ImageView) sub;
                    Bitmap bm = ((BitmapDrawable) im.getDrawable()).getBitmap();
                    RectF r = new RectF(0, 0, bm.getWidth(), bm.getHeight());
                    Matrix matrix = im.getImageMatrix();
                    matrix.mapRect(r);
                    if (r.contains(x, y)) {
                        if (currentAr != im) {
                            currentAr = im;
                            currentArChanged = true;
                            found = 2;
                            updateArBox();
                        } else {
                            found = 1;
                        }
                        break;
                    }
                }
                if (found == 0) {
                    currentAr = null;
                    currentArChanged = true;
                    updateArBox();
                }
                return found != 1;
            }

        });
        
        arBoxFrame = (RelativeLayout) findViewById(R.id.arBoxFrame);
        arBox = (RelativeLayout) findViewById(R.id.arBox);
        arBox.setOnTouchListener(this);
        
        arSelect = (LinearLayout) findViewById(R.id.arSelect);
        
        btnClose = (ImageButton) findViewById(R.id.btnClose);
        btnClose.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                CameraActivity.this.close(Activity.RESULT_CANCELED, null);
            }
            
        });
       
        btnSwitch = (ImageButton) findViewById(R.id.btnSwitch);
        btnSwitch.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                if (camInfo.params.length < 2) return;
                closeCamera();
                camInfo.cameraId = (camInfo.cameraId + 1) % camInfo.params.length;
                createPreview();
            }
            
        });
       
        btnFlash = (ImageButton) findViewById(R.id.btnFlash);
        btnFlash.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                String m = switchFlashMode();
                resetFlashButton(m);
            }
            
        });
       
        btnArDel = (ImageButton) findViewById(R.id.btnArDel);
        btnArDel.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                if (currentAr != null) {
                    canvas.removeView(currentAr);
                    ((BitmapDrawable) currentAr.getDrawable()).getBitmap().recycle();
                    currentAr = null;
                    updateArBox();
                }
            }
            
        });
       
        btnArInf = (ImageButton) findViewById(R.id.btnArInf);
        btnArInf.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                String url = null;
                JSONObject json = CameraUtils.getUserData(currentAr);
                if (json != null) {
                    String[] urlInfo = CameraUtils.getUrlInfo(json.optString("description"));
                    if (urlInfo != null) url = urlInfo[1].trim();
                }
                if (url != null) {
                    Intent intent = new Intent();
                    intent.setAction("android.intent.action.VIEW");
                    Uri content_url = Uri.parse(url);
                    intent.setData(content_url);
                    CameraActivity.this.startActivity(intent);
                }
            }
            
        });
       
        btnArMir = (ImageButton) findViewById(R.id.btnArMir);
        btnArMir.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                Matrix matrix = currentAr.getImageMatrix();
                Bitmap bm = ((BitmapDrawable) currentAr.getDrawable()).getBitmap();
                float[] center = new float[] { bm.getWidth() / 2.0f, bm.getHeight() / 2.0f };
                matrix.mapPoints(center);
                matrix.postScale(-1, 1, center[0], center[1]);
                currentAr.setImageMatrix(matrix);
                currentAr.invalidate();
                updateArBox();
            }
            
        });
       
        btnArRot = (ImageButton) findViewById(R.id.btnArRot);
        
        btnArCtrl = (ImageButton) findViewById(R.id.btnArCtrl);
        btnArCtrl.setOnTouchListener(new OnTouchListener() {

            @Override
            public boolean onTouch(View v, MotionEvent event) {
                switch ((event.getAction() & MotionEvent.ACTION_MASK)) {
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_OUTSIDE:
                case MotionEvent.ACTION_CANCEL:
                    prevCtrlTouch = null;
                    return true;
                case MotionEvent.ACTION_MOVE:
                    int[] gloc = new int[2];
                    v.getLocationOnScreen(gloc);
                    if (prevCtrlTouch == null) {
                        prevCtrlTouch = new PointF (gloc[0] + event.getX(0), gloc[1] + event.getY(0));
                        return true;
                    }
                    Matrix matrix = currentAr.getImageMatrix();
                    Bitmap bm = ((BitmapDrawable) currentAr.getDrawable()).getBitmap();
                    float[] center = new float[] { bm.getWidth() / 2.0f, bm.getHeight() / 2.0f };
                    matrix.mapPoints(center);
//                    int x = btnArCtrl.getLeft(), y = btnArCtrl.getTop();
                    PointF npt = new PointF(gloc[0] + event.getX(0), gloc[1] + event.getY(0));
                    float oldLen = PointF.length(prevCtrlTouch.x - center[0], prevCtrlTouch.y - center[1]);
                    float newLen = PointF.length(npt.x - center[0], npt.y - center[1]);
                    double oldAng = Math.atan2(prevCtrlTouch.y - center[1], prevCtrlTouch.x - center[0]);
                    double newAng = Math.atan2(npt.y - center[1], npt.x - center[0]);
                    matrix.postScale(newLen / oldLen, newLen / oldLen, center[0], center[1]);
                    matrix.postRotate((float) ((newAng - oldAng) * 180.0 / Math.PI), center[0], center[1]);
                    prevCtrlTouch.x = gloc[0] + event.getX(0);
                    prevCtrlTouch.y = gloc[1] + event.getY(0);
                        
                    currentAr.setImageMatrix(matrix);
                    currentAr.invalidate();
                    updateArBox();
//                    RelativeLayout.LayoutParams param = (RelativeLayout.LayoutParams) btnArCtrl.getLayoutParams();
//                    param.leftMargin += npt.x - old.x;
//                    param.topMargin += npt.y - old.y;
                    return true;
                default:
                    return true;
                }
            }
            
        });
       
        btnAlbum = (ImageButton) findViewById(R.id.btnAlbum);
        btnAlbum.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                Intent innerIntent = new Intent(Intent.ACTION_GET_CONTENT); // "android.intent.action.GET_CONTENT"
                innerIntent.setType("image/*"); // for more info about available types, see com.google.android.mms.ContentType
                Intent it = Intent.createChooser(innerIntent, null);
                CameraActivity.this.startActivityForResult(it, ALBUM_AS_BG);
            }
            
        });
       
        btnSnap = (ImageButton) findViewById(R.id.btnSnap);
        btnSnap.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                btnSnap.setEnabled(false);
                File dir = new File(CameraUtils.ALBUM_DIR);
                if (!dir.exists()) {
                    dir.mkdirs();
                }
                String name = "HP_MC_" + (int) (System.currentTimeMillis() / 1000L) + "_" + new Random().nextInt(10000) + ".jpg";
                String snapPath = CameraUtils.ALBUM_DIR + "/" + name;
                snap(snapPath);
            }
            
        });
       
        Intent intent = getIntent();
        String jsonStr = intent != null ? intent.getStringExtra("drawingData") : null;
        if (jsonStr != null && jsonStr.trim().length() > 0) {
            try {
                drawingData = (JSONObject) new JSONTokener(jsonStr).nextValue();
            } catch (Exception ex) { }
        }
        
        if (drawingData == null) drawingData = new JSONObject();
//        try {
//            drawingData = (JSONObject) new JSONTokener("{\"bg\":{\"path\":\"\\/sdcard\\/hp001.jpg\"},\"ars\":[{\"path\":\"\\/sdcard\\/.harryphoto\\/ars_cache\\/784c4ee6e276e5ff8e6121153438beff.jpg\",\"compact\":true,\"matrix\":[-1.0770138502120972,-0.139130100607872,377.0042419433594,-0.139130100607872,1.0770138502120972,107.7896728515625]},{\"path\":\"\\/mnt\\/sdcard\\/我的快盘\\/javaichiban@sina.com\\/pictures\\/全家\\/2005-10 山东\\/IMG_2615.JPG\",\"compact\":false,\"matrix\":[0.5787240862846375,0.2518572211265564,136.5377197265625,-0.2518572211265564,0.5787240862846375,247.42352294921875]}]}").nextValue();
//        } catch (JSONException e) { }
        
        currentAr = null;
        updateArBox();
    }
    
    @Override
    public void onResume() {
        super.onResume();
        Log.i(TAG, "onResume");
        com.umeng.analytics.MobclickAgent.onResume(this);
        if (camInfo != null) {
            createPreview();
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
        Uri uri = data != null ? data.getData() : null;
        if (resultCode == Activity.RESULT_CANCELED || uri == null) return;
        String path = null;
        if (uri.toString().startsWith("content://")) {
            String[] proj = { MediaStore.Images.Media.DATA };     
            Cursor actualimagecursor = this.managedQuery(uri, proj, null, null, null);
            int actual_image_column_index = actualimagecursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
            actualimagecursor.moveToFirst();
          
            String img_path = actualimagecursor.getString(actual_image_column_index);    
            File file = new File(img_path);
            path = file.getAbsolutePath();
        } else {
            path = uri.getPath();
        }
        switch (requestCode) {
        case ALBUM_AS_BG:
            close(Activity.RESULT_OK, path);
            break;
        case ALBUM_AS_AR:
            addAr(path, "", false, null, true);
            break;
        }
    }

    @Override 
    public void surfaceDestroyed(SurfaceHolder holder) {
        Log.i(TAG, "preview surfaceDestroyed");
    }

    @Override 
    public void surfaceCreated(SurfaceHolder holder) {
        Log.i(TAG, "preview surfaceCreated");
    }

    @Override 
    public void surfaceChanged(final SurfaceHolder holder, int format, final int width, final int height) {
        Log.i(TAG, "preview surfaceChanged: w=" + width+",h=" + height);
        if (camInfo != null && camInfo.camera == null) {
            openCamera(camInfo.cameraId);
        }
    }
    
    @Override
    public void onBackPressed() {
        if (currentCid >= 0) { // in folder 
            showFolder(-1);
        } else {
            super.onBackPressed();
        }
        
    }
    
    @Override
    public boolean onTouch(View view, MotionEvent event) {
        switch ((event.getAction() & MotionEvent.ACTION_MASK)) {
        case MotionEvent.ACTION_UP:
        case MotionEvent.ACTION_OUTSIDE:
        case MotionEvent.ACTION_CANCEL:
        case MotionEvent.ACTION_POINTER_UP:
            prevCanvasTouch0 = prevCanvasTouch1 = null;
            return true;
        case MotionEvent.ACTION_MOVE:
            boolean isDrag = event.getPointerCount() == 1;
            int[] gloc = new int[2];
            view.getLocationOnScreen(gloc);
            if (prevCanvasTouch0 == null) {
                prevCanvasTouch0 = new PointF(gloc[0] + event.getX(0), gloc[1] + event.getY(0));
                return true;
            }
            Matrix matrix = currentAr.getImageMatrix();
            if (isDrag) {
                float dx = gloc[0] + event.getX(0) - prevCanvasTouch0.x;
                float dy = gloc[1] + event.getY(0) - prevCanvasTouch0.y;
                matrix.postTranslate(dx, dy);
            } else {
                if (prevCanvasTouch1 == null) {
                    prevCanvasTouch1 = new PointF(gloc[0] + event.getX(1), gloc[1] + event.getY(1));
                    return true;
                }
                PointF old0 = prevCanvasTouch0;
                PointF old1 = prevCanvasTouch1;
                PointF new0 = new PointF(gloc[0] + event.getX(0), gloc[1] + event.getY(0));
                PointF new1 = new PointF(gloc[0] + event.getX(1), gloc[1] + event.getY(1));
                float oldLen = PointF.length(old1.x - old0.x, old1.y - old0.y);
                float newLen = PointF.length(new1.x - new0.x, new1.y - new0.y);
                double oldAng = Math.atan2(old1.y - old0.y, old1.x - old0.x);
                double newAng = Math.atan2(new1.y - new0.y, new1.x - new0.x);
                Bitmap bm = ((BitmapDrawable) currentAr.getDrawable()).getBitmap();
                float[] center = new float[] { bm.getWidth() / 2.0f, bm.getHeight() / 2.0f };
                matrix.mapPoints(center);
                matrix.postScale(newLen / oldLen, newLen / oldLen, center[0], center[1]);
                matrix.postRotate((float) ((newAng - oldAng) * 180.0 / Math.PI), center[0], center[1]);
            }
            prevCanvasTouch0.x = gloc[0] + event.getX(0);
            prevCanvasTouch0.y = gloc[1] + event.getY(0);
            if (!isDrag) {
                prevCanvasTouch1.x = gloc[0] + event.getX(1);
                prevCanvasTouch1.y = gloc[1] + event.getY(1);
            }
            currentAr.setImageMatrix(matrix);
            currentAr.invalidate();
            updateArBox();
            return true;
        default: 
            return true;
        }
    }

    private void createPreview() {
        preview = new SurfaceView(this);
        SurfaceHolder holder = preview.getHolder();
        holder.addCallback(this);
        holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
        CamParam cp = camInfo.params[camInfo.cameraId];
        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(cp.viewWidth, cp.viewHeight);
        params.leftMargin = 0;
        params.topMargin = cp.viewTopMargin;
        previewFrame.addView(preview, params);
//        canvas.setLayoutParams(params);
    }
    
    private void openCamera(int cameraId) {
        Log.i(TAG, "openCamera: cameraId=" + cameraId + ",currId=" + camInfo.cameraId);
        
        camInfo.cameraId = cameraId;
        Camera camera = null;
        try {
            camera = camInfo.camera = Camera.open(cameraId);
        } catch (Exception ex) {
            Log.e(TAG, "openCamera: camera in use, ex=" + ex);
            return;
        }
        CamParam camParam = camInfo.params[cameraId];
        Camera.Parameters params = camParam.params;
        if (camParam.flashModes.length < 2) {
            btnFlash.setVisibility(View.INVISIBLE);
        } else {
            btnFlash.setVisibility(View.VISIBLE);
            resetFlashButton(params.getFlashMode());
        }
        camera.setParameters(params);
        camera.setDisplayOrientation(camParam.rotation);
        try {
            camera.setPreviewDisplay(preview.getHolder());
        } catch (IOException e) {
            Log.e(TAG, "openCamera " + cameraId + ", open camera failed, ex=" + e);
        }
        camera.startPreview();
    }
    
    private void closeCamera() {
        Log.i(TAG, "closeCamera");
        if (camInfo == null || camInfo.camera == null) return;
        
        camInfo.camera.stopPreview();
        camInfo.camera.release();
        camInfo.camera = null;
        previewFrame.removeAllViews();
        preview = null;
    }
    
    private void close(int resultCode, String path) {
        Intent result = new Intent();
        if (path != null) {
            try {
                JSONObject bg = new JSONObject();
                bg.put("path", path);
                JSONArray ars = new JSONArray();
                for (int i = 0, n = canvas.getChildCount(); i < n; i++) {
                    View v = canvas.getChildAt(i);
                    if (v instanceof RelativeLayout) continue; // it's arbox
                    ImageView im = (ImageView) v;
                    JSONObject info = CameraUtils.getUserData(im);
                    float[] values = new float[9];
                    Matrix m = im.getImageMatrix();
                    m.getValues(values);
                    JSONArray matrix = new JSONArray();
                    for (int j = 0; j < 6; matrix.put(values[j++]));
                    info.put("matrix", matrix);
                    ars.put(info);
                }
                drawingData.put("bg", bg);
                drawingData.put("ars", ars);
                result.putExtra("drawingData", drawingData.toString());
            } catch (JSONException e) {
                Log.e(TAG, "close, jsonEx=" + e);
            }
        }
        setResult(resultCode, result);
        finish();
    }
    
    private void initCanvas() {
        JSONArray ars = drawingData.optJSONArray("ars");
        if (ars != null) {
            for (int i = 0, n = ars.length(); i < n; i++) {
                JSONObject ar = ars.optJSONObject(i);
                String path = ar.optString("path");
                boolean compact = ar.optBoolean("compact");
                String descr = ar.optString("description");
                JSONArray mat = ar.optJSONArray("matrix");
                float[] values = new float[] { 1, 0, 0, 0, 1, 0, 0, 0, 1 };
                for (int j = 0; j < 6; j++) values[j] = (float) mat.optDouble(j);
                Matrix matrix = new Matrix();
                matrix.setValues(values);
                addAr(path, descr, compact, matrix, false);
            }
            View v;
            int count;
            if ((count = canvas.getChildCount()) > 0 && (v = canvas.getChildAt(count - 1)) instanceof ImageView) {
                currentAr = (ImageView) v;
                currentArChanged = true;
                updateArBox();
            }
        }
    }
    
    private void addAr(String path, String description, boolean isAr, Matrix matrix, boolean changeCurrentAr) {
        Bitmap bm = isAr ? CameraUtils.loadArImage(path, 0) : CameraUtils.loadImage(path, AR_MAX_AREA);
        if (bm == null) {
            Log.e(TAG, "OOM while adding AR: " + path + ",isAr=" + isAr);
            return;
        }
        ImageView im = new ImageView(this);
        im.setImageBitmap(bm);
        im.setPadding(0, 0, 0, 0);
        im.setScaleType(ScaleType.MATRIX);
        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT);
        params.topMargin = params.leftMargin = 0;
        canvas.addView(im, params);
        
        JSONObject info = new JSONObject();
        try {
            info.put("path", path);
            info.put("compact", isAr);
            info.put("description", description);
        } catch (JSONException e) { }
        im.setContentDescription(info.toString());

        if (matrix == null) { // newly added
            matrix = new Matrix();
            int cw = canvas.getWidth(), ch = canvas.getHeight();
            float area = bm.getWidth() * bm.getHeight();
            float maxArea = cw * ch * 0.5f, r = 1.0f;
            if (area > maxArea) {
                r = (float) Math.sqrt(maxArea / area);
                matrix.postScale(r, r);
            }
            matrix.postTranslate((cw - bm.getWidth() * r) / 2.0f, (ch - bm.getHeight() * r) / 2.0f);
        }
        im.setImageMatrix(matrix);
        
        if (changeCurrentAr) {
            currentAr = im;
            currentArChanged = true;
            updateArBox();
        }
    }
    
    private void updateArBox() {
        if (currentAr == null) { // do hide only
            arBox.setVisibility(View.INVISIBLE);
            btnArDel.setVisibility(View.INVISIBLE);
            btnArInf.setVisibility(View.INVISIBLE);
//            btnArMir.setVisibility(View.INVISIBLE);
            btnArRot.setVisibility(View.INVISIBLE);
            btnArCtrl.setVisibility(View.INVISIBLE);
            return;
        }
        if (currentArChanged) {
            currentArChanged = false;
            arBox.setVisibility(View.VISIBLE);
            btnArDel.setVisibility(View.VISIBLE);
            String urlType = null;
            JSONObject json = CameraUtils.getUserData(currentAr);
            if (json != null) {
                String[] urlInfo = CameraUtils.getUrlInfo(json.optString("description"));
                if (urlInfo != null) urlType = urlInfo[0];
            }
            btnArInf.setVisibility(urlType != null ? View.VISIBLE : View.INVISIBLE);
            if (urlType != null) {
                int resId = "url".equals(urlType) ? R.drawable.ar_obj_inf : R.drawable.ar_obj_buy;
                btnArInf.setImageResource(resId);
            }
//            btnArMir.setVisibility(View.VISIBLE);
            btnArRot.setVisibility(View.VISIBLE);
            btnArCtrl.setVisibility(View.VISIBLE);
            canvas.removeView(arBoxFrame);
            if (canvas.indexOfChild(currentAr) != canvas.getChildCount() - 1) {
                canvas.removeView(currentAr);
                canvas.addView(currentAr);
            }
            canvas.addView(arBoxFrame);
        }
        Bitmap bm = ((BitmapDrawable) currentAr.getDrawable()).getBitmap();
        RectF rectf = new RectF(0, 0, bm.getWidth(), bm.getHeight());
        Matrix matrix = currentAr.getImageMatrix();
        matrix.mapRect(rectf);
        RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams) arBox.getLayoutParams();
        params.leftMargin = (int) rectf.left;
        params.topMargin = (int) rectf.top;
        params.width = (int) rectf.width();
        params.height = (int) rectf.height();
        arBox.setLayoutParams(params);
    }
    
    private void showFolder(final int cid) {
        final boolean isFolder = cid == -1;
        currentCid = cid;
        for (int i = arSelect.getChildCount(); --i >= 1;) {
            ImageButton btn = (ImageButton) arSelect.getChildAt(i);
            ((BitmapDrawable) btn.getDrawable()).getBitmap().recycle();
        }
        arSelect.removeAllViews();
        ImageButton btn = new ImageButton(this);
        btn.setImageResource(isFolder ? R.drawable.icon_ar_local : R.drawable.ar_prev);
        btn.setBackgroundColor(Color.TRANSPARENT);
        btn.setPadding(0, 0, 0, 0);
        btn.setScaleType(ScaleType.FIT_CENTER);
        LayoutParams params = new LayoutParams((int) (AR_ICON_SIZE * dpFactor), (int) (AR_ICON_SIZE * dpFactor));
        arSelect.addView(btn, params);
        
        View.OnClickListener onClick = isFolder ? new OnClickListener() {

            @Override
            public void onClick(View v) {
                Intent innerIntent = new Intent(Intent.ACTION_GET_CONTENT); // "android.intent.action.GET_CONTENT"
                innerIntent.setType("image/*"); // for more info about available types, see com.google.android.mms.ContentType
                Intent it = Intent.createChooser(innerIntent, null);
                CameraActivity.this.startActivityForResult(it, ALBUM_AS_AR);
            }
            
        } : new OnClickListener() {

            @Override
            public void onClick(View v) {
                onBackPressed();
            }
            
        };
        btn.setOnClickListener(onClick);
        
        if (isFolder) {
            addButtons(folderList, true);
            new Thread() {
                
                @Override
                public void run() {
                    loadFolderList();
                }
                
            }.start();
        } else {
            new Thread() {
                
                @Override
                public void run() {
                    try {
                        String path = CameraUtils.AR_CACHE_DIR + "/arlist_" + cid + ".json";
                        JSONObject data = CameraUtils.readJsonFromFile(path);
                        final JSONArray records = data.getJSONObject("goods").getJSONArray("records");
                        CameraActivity.this.runOnUiThread(new Runnable() {
        
                            @Override
                            public void run() {
                                addButtons(records, false);
                            }
                            
                        });
                    } catch (Exception ex) {
                        Log.e(TAG, "showFolder: cid = " + cid + ",ex=" + ex);
                    }
    
                }
                
            }.start();
        }
        ((HorizontalScrollView) arSelect.getParent()).scrollTo(0, 0);
    }
    
    private void addButtons(JSONArray recs, boolean isFolder) {
        for (int i = 0, n = recs.length(); i < n; i++) {
            JSONObject rec = recs.optJSONObject(i);
            try {
                rec.put("isFolder", isFolder);
            } catch (Exception shouldNotHappen) { }
            String url = rec.optString(isFolder ? "icon" : "image");
            if (!CameraUtils.arCacheExists(url)) continue;
            ImageButton btn = new ImageButton(CameraActivity.this);
            btn.setContentDescription(rec.toString());
            btn.setBackgroundColor(Color.TRANSPARENT);
            btn.setPadding(0, 0, 0, 0);
            btn.setScaleType(ScaleType.FIT_CENTER);
            LayoutParams params = new LayoutParams((int) (AR_ICON_SIZE * dpFactor), (int) (AR_ICON_SIZE * dpFactor));
            arSelect.addView(btn, params);
            new ImageButtonLoader(CameraActivity.this, btn, url).start();
        }
    }
    
    public static void initCameras() {
        if (camInfo != null) return; // already initialized
        
        camInfo = new CamInfo();

        int count = Camera.getNumberOfCameras();
        camInfo.params = new CamParam[count];

        if (count == 0) return;

        for (int i = 0; i < count; i++) {
            CamParam cp = camInfo.params[i] = new CamParam();
            
            Camera.CameraInfo ci = new Camera.CameraInfo();
            Camera.getCameraInfo(i, ci);
            cp.facing = ci.facing;
            cp.orientation = ci.orientation;
            
            Camera camera = Camera.open(i);
            Parameters params = cp.params = camera.getParameters();
            
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
            if (cp.flashModes.length > 0) params.setFlashMode(cp.flashModes[0]);
            
            List<String> focusModes = params.getSupportedFocusModes();
            if (focusModes != null && focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
                params.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
            }

            params.setPictureFormat(PixelFormat.JPEG);
            params.setJpegQuality(100); // 1-100

            cp.maxZoom = params.isZoomSupported() ? params.getMaxZoom() : -1;
            cp.rotation = 90;

            camera.release();
        }
        
        camInfo.cameraId = 0;

    }
    
    public static void loadFolderList() {
        Log.i(TAG, "loadFolderList");
        try {
            String path = CameraUtils.AR_CACHE_DIR + "/arfolders.json";
            JSONObject data = CameraUtils.readJsonFromFile(path);
            folderList = data.getJSONObject("catalogs").getJSONArray("records");
        } catch (Exception ex) {
            Log.e(TAG, "loadFolderList error, ex=" + ex);
        }
    }
    
    /**
     * NOTE: in this method, w must always great than h
     * @param w: pixel distance of the longer side 
     * @param h: pixel distance of the shorter side
     */
    private static void findSizes(int w, int h) {
        camInfo.winWidth = h;
        camInfo.winHeight = w;
        double ratio = w / (double) h;
        double area = w * h;
        double picArea = 1024 * 768;
        
        for (int i = 0; i < camInfo.params.length; i++) {
            CamParam cp = camInfo.params[i];
            Parameters params = cp.params;
            
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

            double scale = h / (double) preSize.height; // w > h for preview size
            cp.viewWidth = h;
            cp.viewHeight = (int) (preSize.width * scale);
            cp.viewTopMargin = (int) ((w - cp.viewHeight) / 2);
        }
        
    }
    
    private void resetFlashButton(String mode) {
        int resId = "auto".equals(mode) ? R.drawable.camera_flash_auto : 
            "off".equals(mode) ? R.drawable.camera_flash_off :
                R.drawable.camera_flash_on;
        btnFlash.setImageResource(resId);
    }
    
    /**
     * @param list
     * @param width
     * @param height
     * @return
     */
    private static Size chooseSize(List<Camera.Size> list, final double ratio, final double area, double minArea, double maxArea) {
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

    private static int varianceComp(double d1, double d2) {
        d1 = d1 * d1;
        d2 = d2 * d2;
        return d1 < d2 ? -1 : d1 > d2 ? 1 : 0;
    }

    /**
     * 
     * @return the new flash mode
     */
    private String switchFlashMode() {
        CamInfo info = camInfo;
        CamParam param = info.params[info.cameraId];
        String[] modes = param.flashModes;
        if (modes.length < 2) return null;
        Camera.Parameters params = info.camera.getParameters();
        String curm = params.getFlashMode();
        String newm = null;
        for (int i = 0; i < modes.length; i++) {
            if (modes[i].equals(curm)) {
                newm = modes[(i + 1) % modes.length];
                break;
            }
        }
        if (newm == null) { // not found
            newm = modes[0];
        }
        params.setFlashMode(newm);
        info.camera.setParameters(params);
        return newm;
    }
    
    private void snap(final String path) {
        final CamInfo info = camInfo;
        final CamParam param = info.params[info.cameraId];
        final Camera.PictureCallback jpegCb = new Camera.PictureCallback() {
            
            @Override
            public void onPictureTaken(byte[] data, Camera camera) {
                try {
                    Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
                    float bmpw = bitmap.getWidth(), bmph = bitmap.getHeight();
                    float preRatio = param.viewHeight / (float) param.viewWidth;
                    float bmpRatio = bmpw / bmph;
                    float subx = 0, suby = 0, subw = bmpw, subh = bmph;
                    if (bmpRatio < preRatio) {
                        subh = bmpw / preRatio;
                        suby = (bmph - subh) / 2.0f;
                    } else {
                        subw = bmph * preRatio;
                        subx = (bmpw - subw) / 2.0f;
                    }
                    Matrix matrix = new Matrix();
                    matrix.postRotate(param.orientation);
                    if (param.facing == CameraInfo.CAMERA_FACING_FRONT) {
                        matrix.postScale(-1, 1);
                        matrix.postTranslate(subh, 0);
                    }
                    Bitmap newbmp = Bitmap.createBitmap(bitmap, (int) subx, (int) suby, 
                            (int) subw, (int) subh, matrix, false);
                    bitmap.recycle();
                    File f = new File(path);
                    if (!f.getParentFile().exists()) f.getParentFile().mkdirs();
                    BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(f));
                    newbmp.compress(Bitmap.CompressFormat.JPEG, 85, bos);
                    bos.close();
                    newbmp.recycle();
                    close(Activity.RESULT_OK, path);
                } catch (Exception ex) {
                    Log.e(TAG, "failed to save picture: " + path);
                    close(Activity.RESULT_OK, null);
                }
            }
        };
        if (param.params.getFocusMode() == Camera.Parameters.FOCUS_MODE_AUTO) {
            info.camera.autoFocus(new AutoFocusCallback() {

                @Override
                public void onAutoFocus(boolean success, Camera camera) {
                    camera.takePicture(null, null, jpegCb); // do snap anyhow
                }
                
            });
        } else {
            info.camera.takePicture(null, null, jpegCb);
        }
    }
    
    static class CamInfo {
        public int cameraId;
        public Camera camera;
        public CamParam[] params;
        public int winWidth;
        public int winHeight;
    }

    static class CamParam {
        public int facing;
        public int orientation;
        public int viewWidth;
        public int viewHeight;
        public int viewTopMargin;
        public Camera.Parameters params;
        public int rotation;
        public double maxZoom;
        public String[] flashModes;
    }

    static class ImageButtonLoader extends Thread {
        
        CameraActivity activity;
        ImageButton btn;
        String url;
        
        public ImageButtonLoader(CameraActivity activity, ImageButton btn, String url) {
            this.activity = activity;
            this.btn = btn;
            this.url = url;
        }
        
        @Override
        public void run() {
            String path = CameraUtils.arCachePath(url);
            try {
                final Bitmap bm = CameraUtils.loadArImage(path, AR_ICON_MAX_AREA);
                if (bm == null) {
                    Log.e(TAG, "OOM while loading AR Button: " + path);
                    return;
                }
                
                activity.runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        btn.setImageBitmap(bm);
                        btn.setOnClickListener(new OnClickListener() {

                            @Override
                            public void onClick(View view) {
                                ImageButton btn = (ImageButton) view;
                                String userData = btn.getContentDescription().toString();
                                try {
                                    JSONObject json = (JSONObject) new JSONTokener(userData).nextValue();
                                    boolean isFolder = json.getBoolean("isFolder");
                                    if (isFolder) {
                                        int id = json.getInt("id");
                                        activity.showFolder(id);
                                    } else {
                                        String path = CameraUtils.arCachePath(json.getString("image"));
                                        activity.addAr(path, json.optString("description"), true, null, true);
                                    }
                                } catch (Exception ex) { }
                            }
                            
                        });
                    }
                    
                });
            } catch (Exception e) {
                Log.e(TAG, "ImageButtonLoader, ex=" + e);
            }
        }
    }

}
