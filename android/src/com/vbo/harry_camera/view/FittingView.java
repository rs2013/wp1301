package com.vbo.harry_camera.view;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.PointF;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.FloatMath;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.weiplus.client.BuildConfig;
import com.vbo.harry_camera.data.DataHelper;

@SuppressLint("SimpleDateFormat")
public class FittingView extends SurfaceView/* implements OnTouchListener*/{

    //private Context mContext;
    private SurfaceHolder mHolder;
    private SurfaceHolder.Callback mCallBack;
    private Bitmap mBackgroud;
    /*private Bitmap mRingBitmap;
    private long mRingId;*/

    // For zoom and drag fitting image view
    /*private int mTouchMode;
    private Matrix mRingMatrix;
    private Matrix mSavedRingMatrix;
    private PointF mStartPoint = new PointF();
    private PointF mMidPoint = new PointF();
    private float mDis;
    private float mDegree;*/

    private static final String TAG = "FittingView";

    /*private static final int NONE = 0;
    private static final int DRAG = 1;
    private static final int ZOOM = 2;*/

    public FittingView(Context context, AttributeSet attrs) {
        super(context, attrs);
        /*mContext = context;
        mRingBitmap = ((BitmapDrawable) context.getResources()
                .getDrawable(DataHelper.TEST_FITTING[(int) mRingId])).getBitmap();// TODO will getImage from database
        RingMatrix = matrixDefaultInCenter();*/
        mHolder = this.getHolder();
        mCallBack = new SurfaceHolder.Callback() {

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                if (BuildConfig.DEBUG) Log.d(TAG, "surfaceDestroyed ");
            }

            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                if (BuildConfig.DEBUG) Log.d(TAG, "surfaceCreated ");
            }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                if (BuildConfig.DEBUG) Log.d(TAG, "surfaceChanged  width = " + width + " height = " + height );
                if (mBackgroud != null) {
                    Canvas canvas = mHolder.lockCanvas();
                    if (canvas != null) {
                        canvas.drawBitmap(mBackgroud, 0, 0, null);
                        mHolder.unlockCanvasAndPost(canvas);
                    } else {
                        Log.w(TAG, "surface chaged and can't lock canvas");
                    }
                }
            }
        };
        mHolder.addCallback(mCallBack);
    }

    public void setup(Bitmap background) {
        mBackgroud = background;
    }

    /*@Override
    public boolean onTouch(View view, MotionEvent event) {
        switch(event.getAction() & MotionEvent.ACTION_MASK) {
            // Drag 单点
            case MotionEvent.ACTION_DOWN:
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
                    drawRing(mRingMatrix);
                }
                break;
        }
        
        return false;
    }

    private Matrix matrixDefaultInCenter() {
        return null;
    }

    private boolean outOfImage(MotionEvent event, Matrix imageMatrix) {
        float[] points = new float[9];
        imageMatrix.getValues(points);
        if (BuildConfig.DEBUG) {
            for (float point : points) {
                Log.d(TAG, " point = " + point);
            }
            Log.d(TAG, " imageMatrix = " + imageMatrix.toShortString());
            Log.d(TAG, " imageMatrix = " + imageMatrix.toString());
        }
        
        float pointX = event.getX();
        float pointY = event.getY();
        return false;
    }

    private boolean outOfScreen(MotionEvent event) {
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

    private void drawRing(Matrix matrix) {
        Canvas canvas = mHolder.lockCanvas();
        if (canvas != null) {
            canvas.drawBitmap(mRingBitmap, matrix, null);
            mHolder.unlockCanvasAndPost(canvas);
        } else {
            Log.w(TAG, "can't lock canvas");
        }
    }*/
}
