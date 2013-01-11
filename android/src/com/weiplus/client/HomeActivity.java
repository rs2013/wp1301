package com.weiplus.client;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import com.weibo.sdk.android.Oauth2AccessToken;
import com.weibo.sdk.android.WeiboException;
import com.weibo.sdk.android.api.StatusesAPI;
import com.weibo.sdk.android.api.WeiboAPI.FEATURE;
import com.weibo.sdk.android.net.RequestListener;

import android.app.Activity;
import android.content.Intent;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.Toast;

public class HomeActivity extends Activity implements RequestListener {

    private Button btnRefresh;
    private Button btnHome, btnSelected, btnWrite, btnMessage, btnAccount;
    private WebView webview;
    public static final String TAG = "weiplus.home";
    
    private static String EXT_ROOT = Environment.getExternalStorageDirectory().getPath(); // TODO checks mount state
    private static String APP_DIR = "/sdcard/.weiplus/";
    private static String HOME_DIR = "www";
    
    public Oauth2AccessToken accessToken;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.home_layout);

        btnRefresh = (Button) findViewById(R.id.btnRefresh);
        btnRefresh.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.i(TAG, "btnRefresh clicked");
                updateTimeline();
            }
        });
        btnHome = (Button) findViewById(R.id.btnHome);
        btnSelected = (Button) findViewById(R.id.btnSelected);
        btnSelected.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.i(TAG, "btnSelected clicked");
                Intent intent = new Intent(HomeActivity.this, MainActivity.class); // TODO: for quick test only
                HomeActivity.this.startActivityForResult(intent, 100);
            }
        });
        btnWrite = (Button) findViewById(R.id.btnWrite);
        btnWrite.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.i(TAG, "btnRich clicked");
                Intent intent = new Intent(HomeActivity.this, RichEditActivity.class);
                HomeActivity.this.startActivityForResult(intent, 2);
            }
        });
        btnMessage = (Button) findViewById(R.id.btnMessage);
        btnAccount = (Button) findViewById(R.id.btnAccount);
        btnAccount.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                AccessTokenKeeper.clear(HomeActivity.this);
                Intent intent = new Intent(HomeActivity.this, LoginActivity.class);
                HomeActivity.this.startActivityForResult(intent, 1);
            }
        });
        webview = (WebView) findViewById(R.id.home_webview);
        WebSettings webSettings = webview.getSettings();
        webSettings.setAllowFileAccess(true);
        webSettings.setSavePassword(false);
        webSettings.setSaveFormData(false);
        webSettings.setJavaScriptEnabled(true);
        webSettings.setSupportZoom(false);

        webview.setWebViewClient(new MyWebViewClient());
        
        accessToken = AccessTokenKeeper.readAccessToken(this);
        if (!accessToken.isSessionValid()) {
            Intent intent = new Intent(this, LoginActivity.class);
            this.startActivityForResult(intent, 1);
        }
        loadHomeUrl();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        String dataString = data != null ? data.getStringExtra("data") : null;
        Log.i(TAG, "HomeActivity.onResult: request=" + requestCode + ",result=" + resultCode 
                + ",data=" + dataString);
        if (requestCode == 1) {
            super.onActivityResult(requestCode, resultCode, data);
            File f = new File(APP_DIR + HOME_DIR + "/content.js");
            if (!f.exists()) {
                updateTimeline();
            }
            loadHomeUrl();
        }
    }
    
    private final void updateTimeline() {
        accessToken = AccessTokenKeeper.readAccessToken(this);
        StatusesAPI statusApi = new StatusesAPI(accessToken);
        statusApi.friendsTimeline(0, 0, 50, 1, false, FEATURE.ALL, false, this);
        Toast.makeText(this, "api访问请求已执行，请等待结果", Toast.LENGTH_LONG).show();
    }
    
    private final void loadHomeUrl() {
        try {
            File f = new File(APP_DIR + HOME_DIR);
            //if (!f.exists()) { // TODO: uncomment this
                copyAssets(HOME_DIR);
                copyAssets(HOME_DIR + "/img");
            //}
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        //webview.loadDataWithBaseURL("http://andcli.wk.com/", html.toString(), "text/html", "utf-8", null);
        webview.loadUrl("file://" + APP_DIR + HOME_DIR + "/home.html");
    }
    
    private final void copyAssets(String dir) throws IOException {
        File dest = new File(APP_DIR + dir);
        dest.mkdirs();
        AssetManager assets = getResources().getAssets();
        String[] ff = assets.list(dir);
        byte[] bb = new byte[4000];
        for (String fname: ff) {
            Log.i(TAG, "file=" + fname);
            try {
                InputStream is = assets.open(dir + "/" + fname);
                OutputStream os = new FileOutputStream(new File(dest, fname));
                for (int len = is.read(bb); len >= 0; len = is.read(bb)) {
                    os.write(bb, 0, len);
                }
                is.close();
                os.close();
            } catch (FileNotFoundException e) { // it's a directory, just continue
            }
        }
    }
    
    @Override
    public void onComplete(String response) {
        try {
            OutputStream os = new FileOutputStream(APP_DIR + HOME_DIR + "/content.js");
            os.write(("var content=" + response).getBytes("UTF-8"));
            os.close();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        loadHomeUrl();
    }

    @Override
    public void onIOException(IOException e) {
        e.printStackTrace();
    }

    @Override
    public void onError(WeiboException e) {
        e.printStackTrace();
        
    }
    private class MyWebViewClient extends WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            Log.i(TAG, "shouldOverrideUrlLoading: " + url);
            view.loadUrl(url);
            return true;
        }
        
        @Override
        public void onLoadResource(WebView view, String url) {
            Log.i(TAG, "onLoadResource: " + url);
        }
    }

}
