package com.weiplus.client;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.InputMethodManager;
import android.webkit.WebSettings;
import android.webkit.WebSettings.LayoutAlgorithm;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;

public class RichEditActivity extends Activity {

    private Button btnBack, btnPost;
    private Button btnImage, btnRecord, btnLocation, btnMagic, btnGift, btnRandom;
    private Button btnWeibo, btnQq, btnRenren, btnSohu, btnFacebook, btnTwitter;
    private WebView webview;
//    private InputMethodManager imm;
    public static final String TAG = "weiplus.Editor";

    private static String APP_DIR = "/sdcard/.weiplus/";
    private static String RICHEDIT_DIR = "www";
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.editor_layout);

        btnBack = (Button) findViewById(R.id.btnBack);
        btnBack.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                RichEditActivity.this.finish();
            }
        });
        btnPost = (Button) findViewById(R.id.btnPost);
        btnPost.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                RichEditActivity.this.webview.loadUrl("javascript:$('form').submit();");
            }
        });
        btnImage = (Button) findViewById(R.id.btnImage);
        btnImage.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.i(TAG, "btnImage clicked");
                Intent intent = new Intent(RichEditActivity.this, MainActivity.class);
                RichEditActivity.this.startActivityForResult(intent, 100);
            }
        });
        btnRecord = (Button) findViewById(R.id.btnRecord);
        btnLocation = (Button) findViewById(R.id.btnLocation);
        btnLocation.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
//                imm.showSoftInput(webview, 0);
            }
        });
        btnMagic = (Button) findViewById(R.id.btnMagic);
        btnGift = (Button) findViewById(R.id.btnGift);
        btnRandom = (Button) findViewById(R.id.btnRandom);
        webview = (WebView) findViewById(R.id.richedit_webview);
        WebSettings webSettings = webview.getSettings();
        webSettings.setSavePassword(false);
        webSettings.setSaveFormData(false);
        webSettings.setJavaScriptEnabled(true);
        webSettings.setSupportZoom(false);
        webSettings.setBuiltInZoomControls(false);
        webSettings.setLayoutAlgorithm(LayoutAlgorithm.NARROW_COLUMNS);
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setUseWideViewPort(true);

        webview.setWebViewClient(new MyWebViewClient());
        loadEditor();
//        imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
    }
    
    private final void loadEditor() {
        webview.loadUrl("file://" + APP_DIR + RICHEDIT_DIR + "/edit.html");
        Log.i(TAG, "webview.w=" + webview.getWidth() + ",h=" + webview.getHeight());
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        String dataString = data != null ? data.getStringExtra("data") : null;
        Log.i(TAG, "EditActivity.onResult: request=" + requestCode + ",result=" + resultCode 
                + ",data=" + dataString);
        switch (requestCode) {
        case 100: // from imageEditor
            webview.loadUrl("javascript:setImage('" + dataString + "');");
            break;
        }
    }
    
    private class MyWebViewClient extends WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            Log.e(TAG, "shouldOverrideUrlLoading " + url);
            if (!url.contains("SUBMIT_EDIT")) {
                view.loadUrl(url);
            }
            return true;
        }
        
        @Override
        public void onLoadResource(WebView view, String url) {
            Log.i(TAG, "onLoadResource: " + url);
        }
        
        @Override
        public void onPageFinished(WebView view, String url) {
            Log.e(TAG, "onPageFinished " + url + ",js=" + ("javascript:$('body').width(" + view.getWidth() + ");$('body').height(" + view.getHeight() + ");"));
            //view.setInitialScale((int) (view.getWidth() / 6.4));
            view.loadUrl("javascript:screenHeight(" + view.getHeight() + ");");
        }
    }

}
