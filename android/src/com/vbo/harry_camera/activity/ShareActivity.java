package com.vbo.harry_camera.activity;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import com.weiplus.client.BuildConfig;
import com.weiplus.client.R;
import com.vbo.harry_camera.utils.PictureUtil;

public class ShareActivity extends Activity implements View.OnClickListener{

    private static final String TAG = "ShareActivity";

    private TextView mActionTitle;
    private ImageView mSharePicView;
    private String mPicFilePath;
    private Bitmap mPicBitmap;
    private ImageView mBottomButton;

    private static final int HANDLE_SET_IMAGE = 0;

    private Handler mHandler = new Handler() {

        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            switch (msg.what) {
                case HANDLE_SET_IMAGE:
                    mSharePicView.setImageBitmap(mPicBitmap);
                    break;

                default:
                    break;
            }
        }

    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_share);
        initView();
        getData();
    }

    private void initView() {
        mActionTitle = (TextView) findViewById(R.id.action_bar_title);
        mActionTitle.setText(R.string.share);
        mSharePicView = (ImageView) findViewById(R.id.share_pic);
        mBottomButton = (ImageView) findViewById(R.id.bottom_button);
        mBottomButton.setImageResource(R.drawable.ok);
        mBottomButton.setOnClickListener(this);
    }

    private void getData() {
        Intent intent = getIntent();
        mPicFilePath = intent.getStringExtra(CameraActivity.KEY_PIC_SAVED);
        new Thread(new Runnable() {

            @Override
            public void run() {
                mPicBitmap = PictureUtil.decodePicToBitmap(mPicFilePath, PictureUtil.PIC_SIZE_NORMAL);
                mHandler.sendEmptyMessage(HANDLE_SET_IMAGE);
            }
        }).start();
        if (BuildConfig.DEBUG)
            Log.d(TAG, "filePath = " + mPicFilePath);
    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.bottom_button:
                // TODO
                break;

        }
    }
}
