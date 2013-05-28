package com.vbo.harry_camera.view;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.hardware.Camera;
import android.hardware.Camera.AutoFocusCallback;
import android.hardware.Camera.CameraInfo;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.PictureCallback;
import android.hardware.Camera.ShutterCallback;
import android.hardware.Camera.Size;
import android.hardware.Sensor;
import android.media.CameraProfile;
import android.os.Build;
import android.util.AttributeSet;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.FrameLayout;

import com.weiplus.client.BuildConfig;
import com.vbo.harry_camera.activity.FittingRoom;
import com.vbo.harry_camera.utils.CameraUtil;
import com.vbo.harry_camera.utils.PictureUtil;

import java.io.IOException;
import java.lang.reflect.Method;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

@SuppressLint({
        "SimpleDateFormat", "NewApi"
})
public class CameraView extends SurfaceView {

    private static final String TAG = "CameraView";

    public static final int MODE_DEFAULT   = 0;

    private SurfaceHolder mHolder;
    private Camera mCamera;
    public Size mPictureSize;
    public Size mPreviewSize;
    public boolean mIsCanAutoFocus;
    private SurfaceHolder.Callback mCallBack;
    private Context mContext;

    @SuppressWarnings("deprecation")
    public CameraView(Context context, AttributeSet attrs) {
        super(context, attrs);
        if (BuildConfig.DEBUG) Log.d(TAG, "constructor");
        mContext = context;
        mHolder = this.getHolder();
        mCallBack = new SurfaceHolder.Callback() {

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                if (BuildConfig.DEBUG) Log.d(TAG, "surfaceDestroyed");
                if (mCamera != null) {
                    mCamera.stopPreview();
                    mCamera.release();
                    mCamera = null;
                }
            }

            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                if (BuildConfig.DEBUG)
                    Log.d(TAG, "surfaceCreated");
                try {
                    mCamera = Camera.open(CameraUtil.getCurrentId());
                    mCamera.setPreviewDisplay(holder);
                } catch (RuntimeException e) {
                    Log.w(TAG, e);
                    mCamera.release();
                    mCamera = null;
                } catch (IOException e) {
                    Log.w(TAG, e);
                    mCamera.release();
                    mCamera = null;
                }
            }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                if (BuildConfig.DEBUG) Log.d(TAG, "surfaceChanged and width = " + width + " height = " + height);
                if (mCamera != null) {
                    setCamareParameters(width, height);
                    mCamera.startPreview();
                    if (mIsCanAutoFocus) {
                        mCamera.autoFocus(new Camera.AutoFocusCallback() {

                            @Override
                            public void onAutoFocus(boolean sucess, Camera camera) {
                                if (BuildConfig.DEBUG) {
                                    Log.d(TAG, "onAutoFocus and sucess = " + sucess);
                                }
                            }
                        });
                    }
                }
            }
        };
        mHolder.addCallback(mCallBack);
        // Must set it
        mHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
    }

    public CameraView (Context context) {
        super(context);
        if (BuildConfig.DEBUG) Log.d(TAG, "constructor");
        mContext = context;
        mHolder = this.getHolder();
        mCallBack = new SurfaceHolder.Callback() {

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                if (BuildConfig.DEBUG) Log.d(TAG, "surfaceDestroyed");
                if (mCamera != null) {
                    mCamera.stopPreview();
                    mCamera.release();
                    mCamera = null;
                }
            }

            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                if (BuildConfig.DEBUG)
                    Log.d(TAG, "surfaceCreated");
                try {
                    mCamera = Camera.open(CameraUtil.getCurrentId());
                    mCamera.setPreviewDisplay(holder);
                } catch (RuntimeException e) {
                    Log.w(TAG, e);
                    mCamera.release();
                    mCamera = null;
                } catch (IOException e) {
                    Log.w(TAG, e);
                    mCamera.release();
                    mCamera = null;
                }
            }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                if (BuildConfig.DEBUG) Log.d(TAG, "surfaceChanged and width = " + width + " height = " + height);
                if (mCamera != null) {
                    setCamareParameters(width, height);
                    mCamera.startPreview();
                    if (mIsCanAutoFocus) {
                        mCamera.autoFocus(new Camera.AutoFocusCallback() {

                            @Override
                            public void onAutoFocus(boolean sucess, Camera camera) {
                                if (BuildConfig.DEBUG) {
                                    Log.d(TAG, "onAutoFocus and sucess = " + sucess);
                                }
                            }
                        });
                    }
                }
            }
        };
        mHolder.addCallback(mCallBack);
        // Must set it
        mHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
    }

    public void takePic(final OnPicTakeListener onPicTake) {
        if (mCamera != null) {
            if (mIsCanAutoFocus) {
                mCamera.autoFocus(new Camera.AutoFocusCallback() {

                    @Override
                    public void onAutoFocus(boolean sucess, Camera camera) {
                        if (BuildConfig.DEBUG) {
                            Log.d(TAG, "onAutoFocus and sucess = " + sucess);
                        }
                        mCamera.takePicture(new ShutterCallback() {

                            @Override
                            public void onShutter() {
                                if (BuildConfig.DEBUG) {
                                    Log.d(TAG, "onShutter");
                                }
                            }
                        }, new PictureCallback() {

                            @Override
                            public void onPictureTaken(byte[] data, Camera camera) {
                                if (BuildConfig.DEBUG) {
                                    Log.d(TAG, "onPictureTaken raw");
                                }
                            }
                            
                        }, new PictureCallback() {

                            @Override
                            public void onPictureTaken(byte[] data, Camera camera) {
                                Log.d(TAG, "onPictureTaken jpeg");
                                mCamera.stopPreview();
                                mCamera.release();
                                mCamera = null;
                                onPicTake.onPicTaked(data, camera);
                            }
                        });
                    }
                });
            } else {
                mCamera.takePicture(new ShutterCallback() {

                    @Override
                    public void onShutter() {
                        if (BuildConfig.DEBUG) {
                            Log.d(TAG, "onShutter");
                        }
                    }
                }, new PictureCallback() {

                    @Override
                    public void onPictureTaken(byte[] data, Camera camera) {
                        if (BuildConfig.DEBUG) {
                            Log.d(TAG, "onPictureTaken raw");
                        }
                    }
                    
                }, new PictureCallback() {

                    @Override
                    public void onPictureTaken(byte[] data, Camera camera) {
                        Log.d(TAG, "onPictureTaken jpeg");
                        mCamera.stopPreview();
                        mCamera.release();
                        mCamera = null;
                        onPicTake.onPicTaked(data, camera);
                    }
                });
            }
            /*mCamera.takePicture(new ShutterCallback() {

                @Override
                public void onShutter() {
                    if (BuildConfig.DEBUG) {
                        Log.d(TAG, "onShutter");
                    }
                }
            }, new PictureCallback() {

                @Override
                public void onPictureTaken(byte[] data, Camera camera) {
                    if (BuildConfig.DEBUG) {
                        Log.d(TAG, "onPictureTaken raw");
                    }
                }
                
            }, new PictureCallback() {

                @Override
                public void onPictureTaken(byte[] data, Camera camera) {
                    Log.d(TAG, "onPictureTaken jpeg");
                    mCamera.stopPreview();
                    mCamera.release();
                    mCamera = null;
                    onPicTake.onPicTaked(data, camera);
                }
            });*/
        } else {
            onPicTake.onPicTaked(null, null);
        }
    }

    @SuppressWarnings("deprecation")
    private void setCamareParameters(int width, int height) {
        Camera.Parameters parameters = mCamera.getParameters();
        if (BuildConfig.DEBUG) 
            Log.d(TAG, "Build.VERSION.SDK_INT = " + Build.VERSION.SDK_INT);
        int cameraOrientation = CameraUtil.getCurrentCameraOrientation();
        if (cameraOrientation != 0) {
            if (Build.VERSION.SDK_INT > 10) {
                mCamera.setDisplayOrientation(cameraOrientation);
            } else {
                setDisplayOrientation(mCamera, cameraOrientation);
            }
        }
        parameters.setPictureFormat(PixelFormat.JPEG);
        mPreviewSize = parameters.getPreviewSize();
        mPictureSize = parameters.getPictureSize();
        Log.d(TAG, "mPreviewSize = " + mPreviewSize.width + "," + mPreviewSize.height);
        Log.d(TAG, "mPictureSize = " + mPictureSize.width + "," + mPictureSize.height);
//        Size bestPreSize = CameraUtil.getBestPreviewSize(parameters, cameraOrientation);
        boolean lands = cameraOrientation % 180 == 0;
        Size bestPreSize = getOptimalPreviewSize(parameters.getSupportedPreviewSizes(), lands ? width : height, lands ? height : width);
        Size bestPicSize = CameraUtil.getBestPictureSize(parameters, cameraOrientation);
        if (bestPreSize != null) {
            parameters.setPreviewSize(bestPreSize.width, bestPreSize.height);
            mPreviewSize = bestPreSize;
        }

        if (bestPicSize != null) {
            parameters.setPictureSize(bestPicSize.width, bestPicSize.height);
            mPictureSize = bestPicSize;
        }

        Log.d(TAG, "after mPreviewSize = " + mPreviewSize.width + "," + mPreviewSize.height);
        Log.d(TAG, "after mPictureSize = " + mPictureSize.width + "," + mPictureSize.height);
//        parameters.setFocusMode(Parameters.FOCUS_MODE_AUTO);
        List<String> supportedMode = parameters.getSupportedFocusModes();
        if (supportedMode.contains(Parameters.FOCUS_MODE_AUTO)) {
            mIsCanAutoFocus = true;
            parameters.setFocusMode(Parameters.FOCUS_MODE_AUTO);
        }
        supportedMode = parameters.getSupportedFlashModes();
        if (supportedMode.contains(Parameters.FLASH_MODE_AUTO)) {
            parameters.setFlashMode(Parameters.FLASH_MODE_AUTO);
        }
        parameters.setJpegQuality(95); // 1-100
        mCamera.setParameters(parameters);
        // Front facing camera is inverted be default
        if (!CameraUtil.isBackCamera) mCamera.setDisplayOrientation(90);
    }

    private void setDisplayOrientation(Camera camera, int angle) {
        Method downPolymorphic;
        try {
            downPolymorphic = camera.getClass().getMethod("setDisplayOrientation", 
                    new Class[] { int.class });
            if (downPolymorphic != null)
                downPolymorphic.invoke(camera, new Object[] { angle });
        } catch (Exception e){
        }
    }

    public interface OnPicTakeListener {
        public void onPicTaked(byte[] data ,Camera camera);
    }

    public void cancelAutoFoucs() {
        if (mCamera != null) {
            mCamera.cancelAutoFocus();
        }
    }

    public void autoFoucs(AutoFocusCallback callback) {
        if (mCamera != null) {
            mCamera.autoFocus(callback);
        }
    }
    
    private Size getOptimalPreviewSize(List<Size> sizes, int w, int h) {
        final double ASPECT_TOLERANCE = 0.1;
        double targetRatio = (double) w / h;
        if (sizes == null) return null;

        Size optimalSize = null;
        double minDiff = Double.MAX_VALUE;

        int targetHeight = h;

        // Try to find an size match aspect ratio and size
        for (Size size : sizes) {
            double ratio = (double) size.width / size.height;
            if (Math.abs(ratio - targetRatio) > ASPECT_TOLERANCE) continue;
            if (Math.abs(size.height - targetHeight) < minDiff) {
                optimalSize = size;
                minDiff = Math.abs(size.height - targetHeight);
            }
        }

        // Cannot find the one match the aspect ratio, ignore the requirement
        if (optimalSize == null) {
            minDiff = Double.MAX_VALUE;
            for (Size size : sizes) {
                if (Math.abs(size.height - targetHeight) < minDiff) {
                    optimalSize = size;
                    minDiff = Math.abs(size.height - targetHeight);
                }
            }
        }
        return optimalSize;
    }

}
