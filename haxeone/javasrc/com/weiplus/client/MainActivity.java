package ::APP_PACKAGE::;

import android.app.Activity;
import android.content.Intent;

import android.graphics.ImageFormat;
import android.graphics.PixelFormat;
import android.hardware.Camera;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.Size;
import android.hardware.Camera.PreviewCallback;
import android.os.Bundle;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup.LayoutParams;
import android.util.Log;

import java.io.IOException;
import java.util.List;

public class MainActivity extends org.haxe.nme.GameActivity implements SurfaceHolder.Callback, Camera.PreviewCallback {

    private SurfaceHolder holder;
    private Camera camera;
    public static int[] buffer;

    protected void onCreate(Bundle state) {
        super.onCreate(state);
        Log.i("MainActivity", "My onCreate executed!!");
//        SurfaceView preview = new SurfaceView(this);
//        holder = preview.getHolder();
//        holder.addCallback(this);
//        holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS); // TODO: is this api really deprecated?
//        addContentView(preview, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        try {
            //Open the Camera in preview mode
            this.camera = Camera.open();
            this.camera.setPreviewDisplay(this.holder);
        } catch(IOException ioe) {
            ioe.printStackTrace(System.out);
        }
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        if (width < height) camera.setDisplayOrientation(90);
        // Now that the size is known, set up the camera parameters and begin
        // the preview.
        Camera.Parameters parameters = camera.getParameters();
        List<Camera.Size> previewSizes = parameters.getSupportedPreviewSizes();
        Log.e("CameraSize", "surfaceChanged:width=" + width + "," + height);
        for (Camera.Size s: previewSizes) {
            Log.e("CameraSize", "width=" + s.width + ",height=" + s.height);
        }
        // You need to choose the most appropriate previewSize for your app
        //Camera.Size previewSize = previewSizes.get(1);// .... select one of previewSizes here

        parameters.setPreviewSize(800, 480); // TODO
//        Log.e("Preview", "supportedFormat=" + parameters.getSupportedPreviewFormats());
        parameters.setPreviewFormat(ImageFormat.NV21);
        camera.setParameters(parameters);
        camera.startPreview();
//        camera.setPreviewCallback(this);
    }


    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        // Surface will be destroyed when replaced with a new screen
        //Always make sure to release the Camera instance
        camera.stopPreview();
        camera.release();
        camera = null;
    }

    @Override
    public void onPreviewFrame(byte[] data, Camera camera) {
//        Log.e("Preview", "onPreviewFrame,bb=" + bb.length +",first="+bb[0]+","+bb[1]+","+bb[2]+","+bb[3]);
        if (data != null) {
//            Log.i("DEBUG", "data Not Null");

            // Preprocessing
//            Log.i("DEBUG", "Try For Image Processing");
//            Camera.Parameters mParameters = camera.getParameters();
            long time = System.currentTimeMillis();
            Size mSize = camera.getParameters().getPreviewSize();
            int mWidth = mSize.width;
            int mHeight = mSize.height;
            int[] mIntArray = buffer = new int[mWidth * mHeight];

            // Decode Yuv data to integer array
            decodeYUV420SP(mIntArray, data, mWidth, mHeight);
            Log.e("DEBUG", "previewsize=" + mWidth + "," + mHeight +",time=" + (System.currentTimeMillis() - time));

            // Converting int mIntArray to Bitmap and
            // than image preprocessing
            // and back to mIntArray.

            // Encode intArray to Yuv data
//            encodeYUV420SP(data, mIntArray, mWidth, mHeight);
        }
    }

    static public void decodeYUV420SP(int[] rgba, byte[] yuv420sp, int width, int height) {
        final int frameSize = width * height;
        for (int j = 0, yp = 0; j < height; j++) {
            int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
            for (int i = 0; i < width; i++, yp++) {
                int y = (0xff & ((int) yuv420sp[yp])) - 16;
                if (y < 0)
                    y = 0;
                if ((i & 1) == 0) {
                    v = (0xff & yuv420sp[uvp++]) - 128;
                    u = (0xff & yuv420sp[uvp++]) - 128;
                }

                int y1192 = 1192 * y;
                int r = (y1192 + 1634 * v);
                int g = (y1192 - 833 * v - 400 * u);
                int b = (y1192 + 2066 * u);

                if (r < 0)
                    r = 0;
                else if (r > 262143)
                    r = 262143;
                if (g < 0)
                    g = 0;
                else if (g > 262143)
                    g = 262143;
                if (b < 0)
                    b = 0;
                else if (b > 262143)
                    b = 262143;

                // rgb[yp] = 0xff000000 | ((r << 6) & 0xff0000) | ((g >> 2) &
                // 0xff00) | ((b >> 10) & 0xff);
                // rgba, divide 2^10 ( >> 10)
                rgba[yp] = (((r << 14) & 0xff000000) | ((g << 6) & 0xff0000)
                        | ((b >> 2) | 0xff00)) >> 8; // to argb
            }
        }
    }

    public static org.haxe.nme.GameActivity getInstance() {
        return org.haxe.nme.GameActivity.getInstance();
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.i("MainActivity", "onActivityResult: code=" + requestCode + ",result=" + resultCode + ",data=" + data);
        super.onActivityResult(requestCode, resultCode, data);
        if (HpManager.getCandidate() != null) HpManager.getCandidate().onActivityResult(this, requestCode, resultCode, data);
        HaxeStub.onActivityResult(requestCode, resultCode, data);
    }
    
}
