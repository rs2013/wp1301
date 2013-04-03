package com.harryphoto.bind;

import java.io.IOException;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.webkit.CookieSyncManager;
import android.widget.Toast;

import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;
import com.weibo.sdk.android.Oauth2AccessToken;
import com.weibo.sdk.android.Weibo;
import com.weibo.sdk.android.WeiboAuthListener;
import com.weibo.sdk.android.WeiboDialogError;
import com.weibo.sdk.android.WeiboException;
import com.weibo.sdk.android.api.AccountAPI;
import com.weibo.sdk.android.api.StatusesAPI;
import com.weibo.sdk.android.sso.SsoHandler;
import com.weiplus.client.MainActivity;

public class SinaWeibo extends Binding implements WeiboAuthListener {

    public static String URL_OAUTH2_ACCESS_AUTHORIZE = "https://open.weibo.cn/oauth2/authorize";
    private static String PREFERENCES_NAME = "com_harryphoto_bind_SinaWeibo";
    public static final String KEY_TOKEN = "access_token";
    public static final String KEY_EXPIRES = "expires_in";
    public static final String KEY_REFRESHTOKEN = "refresh_token";
    
    private static final String app_key = "2392272878";// 替换为开发者的appkey，例如"1646212860";
    private static final String redirecturl = "http://hi.baidu.com/new/rockswang";
    private Oauth2AccessToken accessToken;
    private HpListener listener;
    public SsoHandler ssoHandler;
    
    public SinaWeibo(String accessToken) {
        super();
        loadAccessToken();
        if (!TextUtils.isEmpty(accessToken)) {
            this.accessToken.setToken(accessToken);
            this.accessToken.setExpiresTime(Long.MAX_VALUE);
        }
    }
    
    @Override
    public String[] getBindInfo() {
        return new String[] { "accessToken", accessToken.getToken() };
    }
    
    @Override
    public boolean isSessionValid() {
        return accessToken.isSessionValid();
    }
    
    @Override
    public Type getType() {
        return Type.SINA_WEIBO;
    }
    
    private void loadAccessToken() {
        accessToken = new Oauth2AccessToken();
        SharedPreferences pref = MainActivity.getInstance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_APPEND);
        accessToken.setToken(pref.getString("token", ""));
        accessToken.setRefreshToken(pref.getString("refreshToken", ""));
        accessToken.setExpiresTime(pref.getLong("expiresTime", 0));
    }
    
    @Override
    public void startAuth(final Activity activity, HpListener listener) {
        this.listener = listener;
        if (accessToken.isSessionValid()) { // make test
            logout();
//            AccountAPI accountApi = new AccountAPI(accessToken);
//            accountApi.getUid(new com.weibo.sdk.android.net.RequestListener() {
//                
//                @Override
//                public void onComplete(String text) { 
//                    Bundle values = new Bundle();
//                    values.putString(KEY_TOKEN, accessToken.getToken());
//                    values.putString(KEY_EXPIRES, "" + (accessToken.getExpiresTime() - System.currentTimeMillis()) / 1000);
//                    values.putString(KEY_REFRESHTOKEN, accessToken.getRefreshToken());
//                    SinaWeibo.this.onComplete(values);
//                }
//
//                @Override
//                public void onError(WeiboException arg0) {
//                    startAuthDialog(activity);
//                }
//
//                @Override
//                public void onIOException(IOException arg0) {
//                    startAuthDialog(activity);
//                }
//            });
//            
//            return;
        }
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                startAuthDialog(activity);
            }
        });
    }
    
    @Override
    public void logout() {
        SharedPreferences pref = MainActivity.getInstance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_APPEND);
        Editor editor = pref.edit();
        editor.clear();
        editor.commit();
        accessToken.setExpiresTime(0);
        accessToken.setToken("");
        accessToken.setRefreshToken("");
    }
    
    @Override
    public void postStatus(String text, String link, String imgPath, String lat, String lon, HpListener listener) {
        this.listener = listener;  
        StatusesAPI statusApi = new StatusesAPI(accessToken);
        com.weibo.sdk.android.net.RequestListener l = new com.weibo.sdk.android.net.RequestListener() {
            
            @Override
            public void onComplete(String text) { 
                SinaWeibo.this.listener.onComplete(text);
            }

            @Override
            public void onError(WeiboException e) {
                SinaWeibo.this.listener.onError(new HpException(e));
            }

            @Override
            public void onIOException(IOException e) {
                SinaWeibo.this.listener.onIOException(e);
            }
        };
        text = text + " See: " + link; // TODO: text length must <= 140
        if (TextUtils.isEmpty(imgPath)) {
            statusApi.update(text, lat, lon, l);
        } else {
            statusApi.upload(text, imgPath, lat, lon, l);
        }
    }
    
/********************************* Non-Binging routines *******************************/
    @Override
    public void onComplete(Bundle values) {
        // ensure any cookies set by the dialog are saved
//        CookieSyncManager.getInstance().sync();
        accessToken.setToken(values.getString(KEY_TOKEN));
        accessToken.setExpiresIn(values.getString(KEY_EXPIRES));
        accessToken.setRefreshToken(values.getString(KEY_REFRESHTOKEN));
        if (accessToken.isSessionValid()) {
            Log.d("Weibo-authorize",
                    "Login Success! access_token=" + accessToken.getToken() + " expires="
                            + accessToken.getExpiresTime() + " refresh_token="
                            + accessToken.getRefreshToken());
            
            
            SharedPreferences pref = MainActivity.getInstance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_APPEND);
            Editor editor = pref.edit();
            editor.putString("token", accessToken.getToken());
            editor.putLong("expiresTime", accessToken.getExpiresTime());
            editor.putString("refreshToken", accessToken.getRefreshToken());
            editor.commit();
            listener.onComplete("ok"); 
        } else {
            Log.d("Weibo-authorize", "Failed to receive access token");
            listener.onError(new HpException(new WeiboException("Failed to receive access token.")));
        }
    }

    @Override
    public void onError(WeiboDialogError error) {
        Log.d("Weibo-authorize", "Login failed: " + error);
        listener.onError(new HpException(error));
    }

    @Override
    public void onWeiboException(WeiboException error) {
        Log.d("Weibo-authorize", "Login failed: " + error);
        listener.onError(new HpException(error));
    }

    @Override
    public void onCancel() {
        Log.d("Weibo-authorize", "Login canceled");
        listener.onComplete("cancel");
    }
    
    public void startAuthDialog(Activity activity) {
        Weibo mWeibo = Weibo.getInstance(app_key, redirecturl);
        ssoHandler = new SsoHandler(activity, mWeibo);
        ssoHandler.authorize(this);
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        if (ssoHandler != null) {
            ssoHandler.authorizeCallBack(requestCode, resultCode, data);
        }
    }

}
