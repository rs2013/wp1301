package com.weiplus.client;

import com.umeng.analytics.MobclickAgent;
import com.umeng.update.UmengUpdateAgent;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;

public class MainActivity extends org.haxe.nme.GameActivity {
    
    private static final String TAG = "MainActivity";
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(mView, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        
        new Thread() {
            
            @Override
            public void run() {
                CameraActivity.initCameras();
            }
            
        }.start();

        UmengUpdateAgent.setUpdateOnlyWifi(false);
        UmengUpdateAgent.update(this);
        MobclickAgent.onError(this);
    }
    
    @Override
    public void onResume() {
        super.onResume();
        Log.i(TAG, "onResume");
        MobclickAgent.onResume(this);
    }

    @Override
    public void onPause() {
        super.onPause();
        Log.i(TAG, "onPause");
        MobclickAgent.onPause(this);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.i(TAG, "onActivityResult: code=" + requestCode + ",result=" + resultCode + ",data=" + data);
        super.onActivityResult(requestCode, resultCode, data);
        if (HpManager.getCandidate() != null) HpManager.getCandidate().onActivityResult(this, requestCode, resultCode, data);
        HaxeStub.onActivityResult(requestCode, resultCode, data);
    }

    public static MainActivity getInstance() {
        return (MainActivity) org.haxe.nme.GameActivity.getInstance();
    }
    
}

