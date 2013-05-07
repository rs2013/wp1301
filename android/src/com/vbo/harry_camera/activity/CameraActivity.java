package com.vbo.harry_camera.activity;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.PointF;
import android.hardware.Camera;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.DisplayMetrics;
import android.util.FloatMath;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.FrameLayout;
import android.widget.GridView;
import android.widget.ImageView;
import android.widget.ImageView.ScaleType;
import android.widget.TextView;

import com.weiplus.client.BuildConfig;
import com.vbo.harry_camera.HarryCameraApp;
import com.weiplus.client.R;
import com.vbo.harry_camera.data.Category;
import com.vbo.harry_camera.data.DataHelper;
import com.vbo.harry_camera.data.Good;
import com.vbo.harry_camera.data.DataHelper.GoodLoadListener;
import com.vbo.harry_camera.data.DataHelper.ImageDownloadTask;
import com.vbo.harry_camera.utils.CameraUtil;
import com.vbo.harry_camera.utils.PictureUtil;
import com.vbo.harry_camera.view.CameraView;

import java.io.File;
import java.util.ArrayList;

public class CameraActivity extends Activity implements View.OnClickListener, View.OnTouchListener{

    private static final String TAG = "CameraActivity";

    private static final int CATEGORY_DATA_INIT = 0;
    private static final int GOODS_DATA_INIT = 1;
    private static final int UPDATE_CATEGPRY_NAME = 2;
    private static final int UPDATE_STATE = 3;
    private static final int INIT_VIEW = 4;

    private FrameLayout mMainView;
    private CameraView mCameraView;
    private GridView mCategorysView;
    private TextView mCategoryTitleView;
    private ImageView mFittingView;

    private LayoutInflater mLayoutInflater;
    private ArrayList<Category> mCategorys;
    private ArrayList<Good> mFittingSelectItems;
    private CategoryAdapter mCategoryAdapter;
    private ImageFittingAdapter mImageFittingAdapter;
    private ImageView mBottomButton;
    private ImageView mBottomButton2;
    private ImageView mFittingImageView;

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

    private int[] mCameraViewPadding;
    private int mFittingImageWidth;
    private int mFittingImageHeight;
    private String mPicSavedPath;
    private Bitmap mPicTaked;
    private File mPicSavedFile;
    private Bitmap mRingSelectedBitmap;
    private String mSelectedCategoryName;

    private int mViewState;
    private static final int STATE_DEFAULT = 0;
    private static final int STATE_CATEGORYS = STATE_DEFAULT;
    private static final int STATE_CATEGORY_SELECTED = STATE_CATEGORYS + 1;
    private static final int STATE_FITTING_SELECTED = STATE_CATEGORY_SELECTED + 1;
    private static final int STATE_PIC_TAKED = STATE_FITTING_SELECTED + 1;
    private static final int STATE_PIC_SAVED = STATE_PIC_TAKED + 1;

    private boolean mFittingMatrixInit;
    private boolean mIsAutoFocusingInTouch;

    public static final String KEY_PIC_SAVED = "file saved";

    private boolean mNeedFinish;
    private boolean mIsTakingPic;

    private static final int AUTO_FOCUS_INTERVAL = 1000 * 2;
    public static DisplayMetrics sDisplayMetrics;
//    public ArrayList<ImageDownloadTask> mTasks = new ArrayList<DataHelper.ImageDownloadTask>();

    private Handler mHandler = new Handler(){

        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            switch (msg.what) {
                case CATEGORY_DATA_INIT:
                    mCategorysView.setVisibility(View.VISIBLE);
                    mCategorysView.setAdapter(mCategoryAdapter);
                    break;
                case GOODS_DATA_INIT:
                    mCategorysView.setAdapter(mImageFittingAdapter);
                    break;
                case UPDATE_CATEGPRY_NAME:
                    mCategoryTitleView.setText((String) msg.obj);
                    break;
                case UPDATE_STATE:
                    switch (mViewState) {
                        case STATE_CATEGORYS:
                            mCategorysView.setVisibility(View.VISIBLE);
                            mCategoryTitleView.setVisibility(View.VISIBLE);
                            mCategoryTitleView.setText(R.string.category_title);
                            mCategorysView.setAdapter(mCategoryAdapter);
                            mBottomButton.setImageResource(R.drawable.capture);
                            mBottomButton2.setVisibility(View.GONE);
                            mFittingImageView.setVisibility(View.GONE);
                            mCameraView.setVisibility(View.VISIBLE);
                            mFittingView.setVisibility(View.GONE);
                            break;
                        case STATE_CATEGORY_SELECTED:
                            mCategorysView.setVisibility(View.VISIBLE);
                            mCategorysView.setAdapter(mImageFittingAdapter);
                            mCategoryTitleView.setVisibility(View.VISIBLE);
                            mCategoryTitleView.setText(mSelectedCategoryName);
                            mFittingView.setVisibility(View.GONE);
                            break;
                        case STATE_FITTING_SELECTED:
                            mCategorysView.setVisibility(View.GONE);
                            mCategoryTitleView.setVisibility(View.GONE);
                            mFittingView.setVisibility(View.VISIBLE);
                            break;
                        case STATE_PIC_TAKED:
                            mBottomButton.setImageResource(R.drawable.ok);
                            mBottomButton2.setVisibility(View.VISIBLE);
                            mBottomButton2.setImageResource(R.drawable.cancel);
                            mFittingImageView.setImageBitmap(mPicTaked);
                            mFittingImageView.setVisibility(View.VISIBLE);
                            mCameraView.setVisibility(View.GONE);
                            mIsTakingPic = false;
                            break;
                        case STATE_PIC_SAVED:
                            break;
                    }
                    break;
                case INIT_VIEW:
                    initView();
                    break;
            }
        }
    };
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_camara);
        mLayoutInflater = getLayoutInflater();
        sDisplayMetrics = getResources().getDisplayMetrics();
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "densityDpi" + sDisplayMetrics.densityDpi + " density = " + sDisplayMetrics.density);
            Log.d(TAG, "category_width = " + getResources().getDimension(R.dimen.category_width));
            Log.d(TAG, "select_fitting_width = " + getResources().getDimension(R.dimen.select_fitting_width));
        }
        Intent intent = getIntent();
        if (intent != null) {
            Uri data = intent.getData();
            if (data != null) {
                if (data.getScheme().equals("catelog")) {
                    mNeedFinish = true;
                    if (!HarryCameraApp.sCameraPrepared) {
                        HarryCameraApp.setCameraPrepareListener(new HarryCameraApp.CameraPrepareListener() {

                            @Override
                            public void onCameraPrepared() {
                                mHandler.sendEmptyMessage(INIT_VIEW);
                                initData();
                            }
                        });
                        return;
                    }
                }
            }
        }
        initView();
        initData();
    }

    private void initView(){
        mMainView = (FrameLayout) findViewById(R.id.main_view);
        // TODO For more devices
        //mCameraViewPadding = CameraUtil.makesurePreviewPadding(this, true);
        //mMainView.setPadding(mCameraViewPadding[0], mCameraViewPadding[1], mCameraViewPadding[2], mCameraViewPadding[3]);
//        if (BuildConfig.DEBUG)
//            Log.d(TAG, "paddings = [" + mCameraViewPadding[0] + "," + mCameraViewPadding[1]
//                    + "," + mCameraViewPadding[2]+ "," + mCameraViewPadding[3] + "]");
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        mCameraView = new CameraView(this);
        mFittingImageView = new ImageView(this);
        mMainView.addView(mCameraView, 0, lp);
        mMainView.addView(mFittingImageView, 0, lp);
        mFittingImageView.setVisibility(View.GONE);
        mFittingImageView.setScaleType(ScaleType.CENTER_CROP);
        mCategorysView = (GridView) findViewById(R.id.categorys);
        mCategoryTitleView = (TextView) findViewById(R.id.category_title);
        mFittingView = (ImageView) findViewById(R.id.fitting_view);
        mBottomButton = (ImageView) findViewById(R.id.bottom_button);
        mBottomButton2 = (ImageView) findViewById(R.id.bottom_button2);
        mBottomButton.setImageResource(R.drawable.capture);
        mBottomButton.setOnClickListener(this);
        mBottomButton2.setOnClickListener(this);
        mFittingView.setOnTouchListener(this);
    }

    private void initData() {
        new Thread(new Runnable() {

            @Override
            public void run() {
                DataHelper.getCategory(new DataHelper.CategoryLoadListener() {

                    @Override
                    public void onCategoryLoaded(ArrayList<Category> categorys) {
                        mCategorys = categorys;
                        mCategoryAdapter = new CategoryAdapter(mCategorys);
                        mHandler.sendEmptyMessage(CATEGORY_DATA_INIT);
                    }
                });
            }
        }).start();
    }

    private class CategoryAdapter extends BaseAdapter {

        private ArrayList<Category> mCategorys;

        public CategoryAdapter(ArrayList<Category> categorys) {
            mCategorys = categorys;
        }

        @Override
        public int getCount() {
            return mCategorys.size() + 1;
        }

        @Override
        public Object getItem(int position) {
            return null;
        }

        @Override
        public long getItemId(int position) {
            return 0;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            ViewHolder holder;
            if (convertView == null) {
                holder = new ViewHolder();
                convertView = mLayoutInflater.inflate(R.layout.categorys_item, null);
                holder.mText = (TextView) convertView.findViewById(R.id.category_name);
                holder.mImage = (ImageView) convertView.findViewById(R.id.category_add);
                convertView.setTag(holder);
            } else {
                holder = (ViewHolder) convertView.getTag();
            }
            if (position == mCategorys.size()) {
                holder.mImage.setImageResource(R.drawable.add);
                convertView.setOnClickListener(new View.OnClickListener() {

                    @Override
                    public void onClick(View v) {
                        // TODO
                        if (BuildConfig.DEBUG) Log.d(TAG, "add");
                    }
                });
            } else {
                final Category category = mCategorys.get(position);
                holder.mText.setText(category.mName);
                convertView.setOnClickListener(new View.OnClickListener() {

                    @Override
                    public void onClick(View v) {
                        new Thread(new Runnable() {

                            @Override
                            public void run() {
                                DataHelper.getGoods(category.mId, category.mName, new GoodLoadListener() {

                                    @Override
                                    public void onGoodLoaded(ArrayList<Good> goods, String categoryName) {
                                        mViewState = STATE_CATEGORY_SELECTED;
                                        mFittingSelectItems = goods;
                                        mImageFittingAdapter = new ImageFittingAdapter(mFittingSelectItems);
                                        Message msg = new Message();
                                        mSelectedCategoryName = categoryName;
                                        msg.what = UPDATE_STATE;
                                        mHandler.sendMessage(msg);
                                    }
                                });
                            }
                        }).start();
                    }
                });
            }
            return convertView;
        }
    }

    private class ImageFittingAdapter extends BaseAdapter{

        private ArrayList<Good> mItems;

        public ImageFittingAdapter(ArrayList<Good> goods) {
            mItems = goods;
        }

        @Override
        public int getCount() {
            return mItems.size();
        }

        @Override
        public Object getItem(int position) {
            return null;
        }

        @Override
        public long getItemId(int position) {
            return 0;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            final ViewHolder holder;
            if (convertView == null) {
                holder = new ViewHolder();
                convertView = mLayoutInflater.inflate(R.layout.select_fitting_item, null);
                holder.mImage = (ImageView) convertView.findViewById(R.id.select_fitting);
                convertView.setTag(holder);
            } else {
                holder = (ViewHolder) convertView.getTag();
            }
            final Good item = mItems.get(position);
            if (item.mIconBitmap == null) {
                if (item.mIconPathLocal == null) {
                    DataHelper.ImageDownloadTask task = new DataHelper.ImageDownloadTask(){
    
                        @Override
                        protected void onPostExecute(Bitmap result) {
                            super.onPostExecute(result);
                            item.mIconBitmap = result;
//                            item.mIconPathLocal = PictureUtil.saveIcon(CameraActivity.this, result);
                            item.mIconPathLocal = new File(PictureUtil.getARPathForUrl(item.mIconPath));
                            holder.mImage.setImageBitmap(item.mIconBitmap);
                        }
                    };
                    task.execute(item.mIconPath);
                } else {
                    item.mIconBitmap = PictureUtil.decodePicToBitmap(item.mIconPathLocal.getPath(), PictureUtil.PIC_SIZE_SMALL);
                    holder.mImage.setImageBitmap(item.mIconBitmap);
                }
                
            } else {
                holder.mImage.setImageBitmap(item.mIconBitmap);
            }
            convertView.setOnClickListener(new View.OnClickListener() {

                @Override
                public void onClick(View v) {
                    if (BuildConfig.DEBUG)
                        Log.d(TAG, "image category");
                    if (item.mImageBitmap == null) {
                        if (item.mImagePathLocal == null) {
                        final DataHelper.ImageDownloadTask task = new DataHelper.ImageDownloadTask(){

                            @Override
                            protected void onPostExecute(Bitmap result) {
                                super.onPostExecute(result);
                                item.mImageBitmap = result;
//                              item.mImagePathLocal = PictureUtil.saveIcon(CameraActivity.this, result);
                                item.mImagePathLocal = new File(PictureUtil.getARPathForUrl(item.mIconPath));
                                mFittingImageWidth = result.getWidth();
                                mFittingImageHeight = result.getHeight();
                                mFittingView.setImageBitmap(item.mImageBitmap);
                                mRingSelectedBitmap = item.mImageBitmap;
                                mFittingView.setImageMatrix(matrixDefaultInCenter());
                                mFittingMatrixInit = true;
                                mViewState = STATE_FITTING_SELECTED;
                                mHandler.sendEmptyMessage(UPDATE_STATE);
                                if (BuildConfig.DEBUG)
                                    Log.d(TAG, "mFittingImageWidth = " + mFittingImageWidth + " mFittingImageHeight = " + mFittingImageHeight);
                            }
                        };
//                        mTasks.add(task);
                        task.execute(item.mImagePath);
                    } else {
                            item.mImageBitmap = PictureUtil.decodePicToBitmap(item.mImagePathLocal.getPath(), PictureUtil.PIC_SIZE_SMALL);
                            mFittingImageWidth = item.mImageBitmap.getWidth();
                            mFittingImageHeight = item.mImageBitmap.getHeight();
                            mFittingView.setImageBitmap(item.mImageBitmap);
                            mRingSelectedBitmap = item.mImageBitmap;
                            mFittingView.setImageMatrix(matrixDefaultInCenter());
                            mFittingMatrixInit = true;
                            mViewState = STATE_FITTING_SELECTED;
                            mHandler.sendEmptyMessage(UPDATE_STATE);
                            if (BuildConfig.DEBUG)
                                Log.d(TAG, "mFittingImageWidth = " + mFittingImageWidth + " mFittingImageHeight = " + mFittingImageHeight);
                        }
                    } else {
                        mFittingImageWidth = item.mImageBitmap.getWidth();
                        mFittingImageHeight = item.mImageBitmap.getHeight();
                        mFittingView.setImageBitmap(item.mImageBitmap);
                        mRingSelectedBitmap = item.mImageBitmap;
                        mFittingView.setImageMatrix(matrixDefaultInCenter());
                        mFittingMatrixInit = true;
                        mViewState = STATE_FITTING_SELECTED;
                        mHandler.sendEmptyMessage(UPDATE_STATE);
                        if (BuildConfig.DEBUG)
                            Log.d(TAG, "mFittingImageWidth = " + mFittingImageWidth + " mFittingImageHeight = " + mFittingImageHeight);
                    }
                }
            });
            return convertView;
        }
    }

    static class ViewHolder {
        TextView mText;
        ImageView mImage;
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.bottom_button:
                if (mViewState == STATE_FITTING_SELECTED && !mIsTakingPic) {
                    mIsTakingPic = true;
                    mCameraView.takePic(new CameraView.OnPicTakeListener() {

                        @Override
                        public void onPicTaked(byte[] data, Camera camera) {
                            mPicTaked = /*PictureUtil.scalePic(*/PictureUtil.rotatePic(data)/*, mCameraView.getWidth())*/;
                            mViewState = STATE_PIC_TAKED;
                            mHandler.sendEmptyMessage(UPDATE_STATE);
                        }
                    });
                } else if (mViewState == STATE_PIC_TAKED) {
                    if (BuildConfig.DEBUG)
                        Log.d(TAG, "pic take");
                    mRingMatrix.set(mFittingView.getImageMatrix());
                    mPicSavedFile = PictureUtil.savePic(
                            CameraActivity.this, mRingSelectedBitmap, mRingMatrix, mPicTaked, 
                            /*mCameraView.getWidth() - mCameraViewPadding[0] - mCameraViewPadding[2],
                            mCameraView.getHeight() - mCameraViewPadding[1] - mCameraViewPadding[3]
                                    - ((int) getResources().getDimension(R.dimen.bottom_bar_height))*/mFittingImageView.getWidth(), mFittingImageView.getHeight());
                    mViewState = STATE_PIC_SAVED;
                    if (mNeedFinish) {
                        Intent result = new Intent();
                        result.setData(Uri.fromFile(mPicSavedFile));
                        setResult(RESULT_OK, result);
                        finish();
                    } else {
                        Intent starter = new Intent(CameraActivity.this, ShareActivity.class);
                        starter.putExtra(KEY_PIC_SAVED, mPicSavedFile.getAbsolutePath());
                        startActivity(starter);
                    }
                }
                break;
            case R.id.bottom_button2:
                if (BuildConfig.DEBUG)
                    Log.d(TAG, "bottom_button2 onclick");
                mViewState = STATE_CATEGORYS;
                mHandler.sendEmptyMessage(UPDATE_STATE);
                //initData();
                break;
            default:
                break;
        }
    }

    @Override
    public boolean onTouch(View view, MotionEvent event) {
        if (mViewState == STATE_FITTING_SELECTED && mCameraView != null && !mIsAutoFocusingInTouch) {
            mIsAutoFocusingInTouch = true;
            mCameraView.autoFoucs(new Camera.AutoFocusCallback() {

                @Override
                public void onAutoFocus(boolean paramBoolean, Camera paramCamera) {
                    if (BuildConfig.DEBUG)
                        Log.d(TAG, "onTouch and paramBoolean = " + paramBoolean);
                    mHandler.postDelayed(new Runnable() {
                        
                        @Override
                        public void run() {
                            mIsAutoFocusingInTouch = false;
                        }
                    }, AUTO_FOCUS_INTERVAL);
                }
            });
        }
            switch(event.getAction() & MotionEvent.ACTION_MASK) {
                // Drag 单点
                case MotionEvent.ACTION_DOWN:
                    mRingMatrix.set(mFittingView.getImageMatrix());
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
        mFittingView.setImageMatrix(mRingMatrix);
        return true;
    }

    private Matrix matrixDefaultInCenter() {
       
        Matrix matrix = mFittingView.getImageMatrix();
        if (mFittingMatrixInit) 
            return matrix;
        matrix.postTranslate((sDisplayMetrics.widthPixels - mFittingImageWidth) / 2,
                (sDisplayMetrics.heightPixels/* - mCameraViewPadding[1] - mCameraViewPadding[3] */
                        - getResources().getDimension(R.dimen.bottom_bar_height) - mFittingImageHeight) / 2);
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

    @Override
    public void onBackPressed() {
        mViewState--;
        if (BuildConfig.DEBUG)
            Log.d(TAG, "onBackPressed and mState = " + mViewState);
        if (mViewState >= 0) { 
            mHandler.sendEmptyMessage(UPDATE_STATE);
        } else {
            super.onBackPressed();
        }
        
    }
}
