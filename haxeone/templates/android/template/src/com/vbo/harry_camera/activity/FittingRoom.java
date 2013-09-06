package com.vbo.harry_camera.activity;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.graphics.PointF;
import android.graphics.drawable.BitmapDrawable;
import android.hardware.Camera;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.DisplayMetrics;
import android.util.FloatMath;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnTouchListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import android.widget.Toast;

import com.weiplus.client.BuildConfig;
import com.weiplus.client.R;
import com.vbo.harry_camera.data.DataHelper;
import com.vbo.harry_camera.utils.CameraUtil;
import com.vbo.harry_camera.utils.PictureUtil;
import com.vbo.harry_camera.view.CameraView;
import com.vbo.harry_camera.view.FittingView;

import java.io.File;

@SuppressLint("HandlerLeak")
public class FittingRoom extends Activity implements OnClickListener, OnTouchListener{

    private static final String TAG = "FittingRoom";

    private Context mContext;
    private boolean mIsBtnUnlock;

    private FrameLayout mMainView;
    private CameraView mCameraView;
    private FittingView mFittingView;
    private ImageView mRingView;
    private ViewGroup mRingSelectContainer;
    private HorizontalScrollView mRingScrollView;
    private RelativeLayout mFooter;
    private Button mBtnCapture;
    private Button mBtnRecapture;
    private Button mBtnSave;
    private Button mBtnView;
    private Button mBtnShare;

    private long mRingSelectId;
    private Bitmap mPicTaked;
    private File mPicSavedFile;

    private int mState;
    private long mDataIdSelected[];
    public static DisplayMetrics sDisplayMetrics;

    private int mFittingWidth;
    private int mFittingHeight;
    private int mFittingLeft;
    private int mFittingTop;

    // For zoom and drag fitting image view
    private int mTouchMode;
    private Matrix mRingMatrix = new Matrix();;
    private Matrix mSavedRingMatrix = new Matrix();
    private PointF mStartPoint = new PointF();
    private PointF mMidPoint = new PointF();
    private float mDis;
    private float mDegree;
    private static final int NONE = 0;
    private static final int DRAG = 1;
    private static final int ZOOM = 2;
    private static final int STATE_DEFAULT = 0;
    private static final int STATE_PREVIEW = 1;
    private static final int STATE_PIC_TAKED = 2;
    private static final int STATE_PIC_SAVED = 3;

    private static final int MSG_REFRESH_VIEW = 0;
    private static final int MSG_TOAST = 1;

    private Handler mHandler = new Handler(){

        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            switch (msg.what) {
                case MSG_REFRESH_VIEW:
                    refreshView();
                    mIsBtnUnlock = true;
                    break;
                case MSG_TOAST:
                    Toast.makeText(mContext, msg.arg1, Toast.LENGTH_LONG).show();
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_fitting_room);
        mContext = this;
        sDisplayMetrics = getResources().getDisplayMetrics();
        Intent intent = getIntent();
        if (intent != null) {
            mDataIdSelected = intent.getLongArrayExtra(ShowRoom.RINGS_SELECTED_ID);
            if (BuildConfig.DEBUG) {
                for (long i : mDataIdSelected) {
                    Log.d(TAG, "data selected : " + i);
                }
            }
            initView();
        }
    }

    private void initView() {
        mMainView = (FrameLayout) findViewById(R.id.main_view);
        mCameraView = (CameraView) findViewById(R.id.camera_view);
        mFittingView = (FittingView) findViewById(R.id.fitting_view);
        mRingView = (ImageView) findViewById(R.id.ring_view);
        mRingView.setImageMatrix(matrixDefaultInCenter());
        mRingScrollView = (HorizontalScrollView) findViewById(R.id.scroll);
        mRingSelectContainer = (ViewGroup) findViewById(R.id.ring_select_container);
        mFooter = (RelativeLayout) findViewById(R.id.footer);
        mBtnCapture = (Button)findViewById(R.id.btn_capture);
        mBtnRecapture = (Button)findViewById(R.id.btn_recapture);
        mBtnSave = (Button) findViewById(R.id.btn_save);
        mBtnView = (Button) findViewById(R.id.btn_view);
        mBtnShare = (Button) findViewById(R.id.btn_share);
        mBtnCapture.setOnClickListener(this);
        mBtnRecapture.setOnClickListener(this);
        mBtnSave.setOnClickListener(this);
        mBtnView.setOnClickListener(this);
        mBtnShare.setOnClickListener(this);
        mRingView.setOnTouchListener(this);
        boolean isFirst = true;
        mRingSelectContainer.setVisibility(View.VISIBLE);
        for (final long i : mDataIdSelected) {
            ImageView selectItem = new ImageView(this);
            selectItem.setImageBitmap(((BitmapDrawable) getResources()
                    .getDrawable(DataHelper.TEST_THUMBS[(int) i])).getBitmap());
            selectItem.setBackgroundColor(getResources().getColor(R.color.backgroud_show_item_ring));
            ViewGroup.LayoutParams params = new LayoutParams(100, 100);
            mRingSelectContainer.addView(selectItem, params);
            if (isFirst) {
                isFirst = false;
                mRingSelectId = i;
                mRingView.setImageBitmap(((BitmapDrawable) getResources().getDrawable(DataHelper.TEST_FITTING[(int) i])).getBitmap());
            }
            selectItem.setOnClickListener(new View.OnClickListener() {

                @Override
                public void onClick(View v) {
                    mRingSelectId = i;
                    mRingView.setImageBitmap(((BitmapDrawable) getResources().getDrawable(DataHelper.TEST_FITTING[(int) i])).getBitmap());
                }
            });
        }
        refreshView();
        mIsBtnUnlock = true;
    }

    private void refreshView() {
        switch (mState) {
            case STATE_DEFAULT:
            case STATE_PREVIEW:
                mFooter.setVisibility(View.VISIBLE);
                //mBtnCapture.setVisibility(View.VISIBLE);
                break;
            case STATE_PIC_TAKED:
                //mBtnCapture.setVisibility(View.GONE);
                mFooter.setVisibility(View.GONE);
                mBtnRecapture.setVisibility(View.VISIBLE);
                mBtnSave.setVisibility(View.VISIBLE);
                mFittingView.setup(mPicTaked);
                mFittingView.setVisibility(View.VISIBLE);
                //mRingView.setVisibility(View.VISIBLE);
                mCameraView.setVisibility(View.INVISIBLE);
                break;
            case STATE_PIC_SAVED:
                mBtnRecapture.setVisibility(View.GONE);
                mRingScrollView.setVisibility(View.GONE);
                mBtnSave.setVisibility(View.GONE);
                mBtnView.setVisibility(View.VISIBLE);
                mBtnShare.setVisibility(View.VISIBLE);
                mRingView.setOnTouchListener(null);
                break;
        }
    }

    @Override
    public void onClick(View v) {
        if (mIsBtnUnlock) {
            mIsBtnUnlock = false;
            switch (v.getId()) {
                case R.id.btn_capture:
                    if (mPicTaked != null) {
                        mPicTaked.recycle();
                        mPicTaked = null;
                    }
                    /*if (Camera.Parameters.FOCUS_MODE_AUTO.equals(CameraUtil.sCurrentFoucsMode)) {
                        mCameraView.autoFoucs(new Camera.AutoFocusCallback() {

                            @Override
                            public void onAutoFocus(boolean success, Camera camera) {
                                if (BuildConfig.DEBUG) {
                                    Log.d(TAG, "onAutoFocus success = " + success);
                                    takePic();
                                }
                            }
                        });
                    } else {
                        Log.d(TAG, "takePic CameraUtil.sCurrentFoucsMode = " + CameraUtil.sCurrentFoucsMode);
                        takePic();
                    }*/
                    
                    break;
                case R.id.btn_recapture:
                    mCameraView.setVisibility(View.VISIBLE);
                    mFittingView.setVisibility(View.INVISIBLE);
                    mBtnRecapture.setVisibility(View.GONE);
                    mBtnSave.setVisibility(View.GONE);
                    mFooter.setVisibility(View.VISIBLE);
                    mState = STATE_PREVIEW;
                    mHandler.sendEmptyMessage(MSG_REFRESH_VIEW);
                    break;
                case R.id.btn_save:
                    mState = STATE_PIC_SAVED;
                    mPicSavedFile = PictureUtil.savePic(mContext, (int) mRingSelectId,
                            mFittingView.getWidth(), mFittingView.getHeight(),
                            mRingMatrix,
                            mPicTaked, mFittingWidth, mFittingHeight, mFittingLeft, mFittingTop);
                    if (mPicSavedFile != null) {
                        Intent scanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
                        scanIntent.setData(Uri.fromFile(mPicSavedFile));
                        sendBroadcast(scanIntent);
                    }
                    mHandler.sendEmptyMessage(MSG_REFRESH_VIEW);
                    break;
                case R.id.btn_view:
                    if (mPicSavedFile != null) {
                        Intent intent = new Intent(Intent.ACTION_VIEW);
                        intent.setDataAndType(Uri.fromFile(mPicSavedFile), "image/jpeg");
                        startActivity(intent);
                    }
                    mIsBtnUnlock = true;
                    break;
                case R.id.btn_share:
                    Log.d(TAG, "share");
                    Intent shareIntent = new Intent(Intent.ACTION_SEND);
                    if (mPicSavedFile != null) {
                        shareIntent.setType("image/jpeg");
                        shareIntent.putExtra(Intent.EXTRA_STREAM, Uri.fromFile(mPicSavedFile));
                    }
                    shareIntent.putExtra(Intent.EXTRA_SUBJECT, getString(R.string.share_subject));
                    shareIntent.putExtra(Intent.EXTRA_TITLE, getString(R.string.share_subject));
                    shareIntent.putExtra(Intent.EXTRA_TEXT, getString(R.string.share_text));
                    startActivity(Intent.createChooser(shareIntent, getString(R.string.share_via)));
                    mIsBtnUnlock = true;
                    break;
            }
        }
    }

    @Override
    public boolean onTouch(View view, MotionEvent event) {
            switch(event.getAction() & MotionEvent.ACTION_MASK) {
                // Drag 单点
                case MotionEvent.ACTION_DOWN:
                    mRingMatrix.set(mRingView.getImageMatrix());
                    if (outOfImage(event, mRingMatrix)) {
                        mTouchMode = NONE;
                        return false;
                    }
                    mSavedRingMatrix.set(mRingMatrix);
                    mStartPoint.set(event.getX(), event.getY());
                    mTouchMode = DRAG;
                    break;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_POINTER_UP:
                    mTouchMode = NONE;
                    break;
                    // Zoom 多点
                case MotionEvent.ACTION_POINTER_DOWN:
                    mDis = computeDistance(event);
                    mDegree = computeDegree(event);
                    mSavedRingMatrix.set(mRingMatrix);
                    mMidPoint = computeMidPoint(event);
                    mTouchMode = ZOOM;
                    break;
                case MotionEvent.ACTION_MOVE:
                    if (!outOfScreen(event)) {
                        if(mTouchMode == DRAG){
                            mRingMatrix.set(mSavedRingMatrix);
                            mRingMatrix.postTranslate(
                                    event.getX() - mStartPoint.x, event.getY() - mStartPoint.y);
                        }
                        if (mTouchMode == ZOOM) {
                            float newDis = computeDistance(event);
                            float newDegree = computeDegree(event);
                            mRingMatrix.set(mSavedRingMatrix);
                            float scale = newDis / mDis;
                            mRingMatrix.postScale(scale, scale, mMidPoint.x, mMidPoint.y);
                            mRingMatrix.postRotate(newDegree - mDegree, mMidPoint.x, mMidPoint.y);
                        }
                    }
                    break;
            }
        mRingView.setImageMatrix(mRingMatrix);
        return true;
    }

    private Matrix matrixDefaultInCenter() {
        // XXX Just for Nexus S
        Matrix matrix = mRingView.getImageMatrix();
        matrix.postScale(0.8f, 0.8f);
        matrix.postTranslate(sDisplayMetrics.xdpi / 2 + 50, sDisplayMetrics.ydpi / 2 + 100);
        return matrix;
    }

    private boolean outOfImage(MotionEvent event, Matrix imageMatrix) {
        // TODO to implements
        float[] points = new float[9];
        imageMatrix.getValues(points);
        if (BuildConfig.DEBUG) {
            for (float point : points) {
                Log.d(TAG, " point = " + point);
            }
            Log.d(TAG, " imageMatrix = " + imageMatrix.toShortString());
            Log.d(TAG, " imageMatrix = " + imageMatrix.toString());
        }
        
        //float pointX = event.getX();
        //float pointY = event.getY();
        return false;
    }

    private boolean outOfScreen(MotionEvent event) {
        // TODO to implements
        return false;
    }

    @SuppressLint("FloatMath")
    private float computeDistance(MotionEvent event) {
        float xDis = event.getX(0) - event.getX(1);
        float yDis = event.getY(0) - event.getY(1);
        return FloatMath.sqrt((xDis * xDis) + (yDis * yDis));
        //return xDis > yDis ? xDis : yDis;
    }

    private PointF computeMidPoint(MotionEvent event) {
        float x = event.getX(0) + event.getX(1);
        float y = event.getY(0) + event.getY(1);
        return new PointF(x / 2, y / 2);
    }

    private float computeDegree(MotionEvent event) {
        float xDis = event.getX(1) - event.getX(0);
        float yDis = event.getY(1) - event.getY(0);
        double angle = Math.atan2(yDis, xDis);
        if (BuildConfig.DEBUG) {
            double degree = Math.toDegrees(angle);
            Log.d(TAG, "xDis = " + xDis + " yDis = " + yDis);
            if (BuildConfig.DEBUG) Log.d(TAG, "angle = " + angle + " degree = " + degree);
        }
        return (float) Math.toDegrees(angle);
    }

    private void takePic() {
        /*mCameraView.takePic(0, 0, new CameraView.OnPicTakeListener() {

            @Override
            public void onPicTaked(final byte[] data, int width, int height, int left, int top) {
                if (data != null) {
                    mState = STATE_PIC_TAKED;
                    mFittingWidth = width;
                    mFittingHeight = height;
                    mFittingLeft = left;
                    mFittingTop = top;
                    new Thread(new  Runnable() {

                        @Override
                        public void run() {
                            mPicTaked = PictureUtil.scalePic(PictureUtil.rotatePic(data), mMainView.getWidth());
                            mHandler.sendEmptyMessage(MSG_REFRESH_VIEW);
                        }
                    }).run();
                } else {
                    // Camera has't been ready or camera is busy
                    Message msg = new Message();
                    msg.what = MSG_TOAST;
                    msg.arg1 = R.string.toast_camera_error;
                    mHandler.sendMessage(msg);
                    mIsBtnUnlock = true;
                }
            }
        });*/
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mPicTaked != null) {
            mPicTaked.recycle();
            mPicTaked = null;
        }
    }
}
