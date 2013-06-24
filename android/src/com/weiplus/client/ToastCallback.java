package com.weiplus.client;

import java.io.IOException;

import android.app.Activity;
import android.widget.Toast;

import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;

class ToastCallback implements HpListener {
    
    private Activity activity;
    private String msg;
    
    public ToastCallback(Activity activity, String msg) {
        this.activity = activity;
        this.msg = msg;
    }

    @Override
    public void onComplete(String response) {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(activity, msg + " ok", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onIOException(final IOException e) {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(activity, msg + " error, ex=" + e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onError(final HpException e) {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(activity, msg + " error, error=" + e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }
    
}