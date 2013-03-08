package com.weiplus.client;

import java.io.IOException;
import java.util.HashMap;

import org.haxe.nme.HaxeObject;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.util.Log;
import android.widget.Toast;

import com.harryphoto.api.HpAccessToken;
import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;
import com.harryphoto.api.StatusAPI;
import com.harryphoto.api.UserAPI;
import com.harryphoto.api.Utility;
import com.harryphoto.bind.*;

public class HpManager {
    
    private static String PREFERENCES_NAME = "com_harryphoto_api_HpAPI";
    private static String LINK = "http://s-56378.gotocdn.com/harryphoto/statuses/show/${ID}.json";
    
    private static HpAccessToken accessToken;
    
    private static HashMap<String, Binding> bindings;
    private static HashMap<String, String> imgMapping = new HashMap<String, String>();
    
    public static boolean check() {
        return getAccessToken().isSessionValid();
    }
    
    public static void login() {
        Activity activity = MainActivity.getInstance();
        HpAccessToken token = getAccessToken();
        if (!token.isSessionValid()) {
            Intent intent = new Intent(activity, LoginActivity.class); 
            activity.startActivity(intent);
        }
    }
    
    public static void getPublicTimeline(HaxeObject callback) {
        StatusAPI api = new StatusAPI(accessToken);
        api.publicTimeline(new HaxeCallback("statuses_public_timeline", callback)); 
    }
    
    public static void getHomeTimeline(HaxeObject callback) {
        StatusAPI api = new StatusAPI(accessToken);
        api.homeTimeline("", new HaxeCallback("statuses_home_timeline", callback));
    }
    
    public static void getUserTimeline(String uid, HaxeObject callback) {
        StatusAPI api = new StatusAPI(accessToken);
        api.userTimeline(uid != null ? uid : "", new HaxeCallback("statuses_user_timeline", callback));
    }
    
    public static void getUserInfo(String uid, HaxeObject callback) {
        UserAPI api = new UserAPI(accessToken);
        api.show(uid, new HaxeCallback("users_show", callback));
    }
    
    public static void postStatus(final String text, final String imgPath, 
            final String type, final String filePath, 
            final String lat, final String lon, final HaxeObject callback) {
        StatusAPI api = new StatusAPI(accessToken);
//        api.post(text, imgPath, type, filePath, lat, lon, new HaxeCallback("statuses_create", callback));
        api.post(text, imgPath, type, filePath, lat, lon, new HpListener() {

            @Override
            public void onComplete(String response) {
                try {
                    JSONObject json = new JSONObject(response);
                    if (json.getInt("code") == 200) {
                        JSONObject st = json.getJSONArray("statuses").getJSONObject(0);
                        long statusId = st.getLong("id");
                        String imgUrl = st.getJSONArray("attachments").getJSONObject(0).getString("thumbUrl");
                        imgMapping.put(imgPath, imgUrl);
                        String link = LINK.replace("${ID}", "" + statusId);
                        for (Binding b: bindings.values()) {
                            b.postStatus(text, link, imgPath, lat, lon, new ToastCallback(MainActivity.getInstance(), b.getType() + "同步"));
                        }
                        Utility.haxeOk(callback, "statuses_create", response);
                    } else {
                        throw new Exception("error, code=" + json.getInt("code"));
                    }
                } catch (Exception e) {
                    onError(new HpException(e));
                }
            }

            @Override
            public void onIOException(IOException e) {
                onError(new HpException(e));
            }

            @Override
            public void onError(final HpException e) {
                Log.e("HpManager", e.getMessage());
                Utility.haxeError(callback, "statuses_create", e);
            }
            
        });
    }
    
    public static HpAccessToken getAccessToken() {
        if (accessToken == null) {
            SharedPreferences pref = MainActivity.getInstance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_APPEND);
            HpAccessToken token = accessToken = new HpAccessToken();
            token.setToken(pref.getString("accessToken", ""));
            token.setRefreshToken(pref.getString("refreshToken", ""));
            token.setExpiresTime(pref.getLong("expiresTime", 0));
            token.setUid(pref.getString("uid", ""));
        }
        return accessToken;
    }
    
    public static void setAccessToken(HpAccessToken token) {
        accessToken = token;
        saveAccessToken();
    }
    
    public static void saveAccessToken() {
        SharedPreferences pref = MainActivity.getInstance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_APPEND);
        Editor editor = pref.edit();
        editor.putString("accessToken", accessToken.getToken());
        editor.putString("refreshToken", accessToken.getRefreshToken());
        editor.putLong("expiresTime", accessToken.getExpiresTime());
        editor.putString("uid", accessToken.getUid());
        editor.commit();
    }
    
    public static void logout() {
        SharedPreferences pref = MainActivity.getInstance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_APPEND);
        Editor editor = pref.edit();
        editor.clear();
        editor.commit();
        if (accessToken != null) {
            accessToken.setExpiresTime(0);
            accessToken.setToken("");
            accessToken.setRefreshToken("");
            accessToken.setUid("");
        }
        for (Binding b: bindings.values()) b.logout();
    }
    
    public static void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        for (Binding b: bindings.values()) b.onActivityResult(activity, requestCode, resultCode, data);
    }
    
    public static Binding getBinding(Binding.Type type) {
        return bindings.get(type.name());
    }
    
    public static String getImageUrl(String imagePath) {
        return imgMapping.get(imagePath);
    }
    
    static {
        bindings = new HashMap<String, Binding>();
        bindings.put(Binding.Type.SINA_WEIBO.name(), new SinaWeibo());
        bindings.put(Binding.Type.TENCENT_WEIBO.name(), new TencentWeibo());
        bindings.put(Binding.Type.RENREN_WEIBO.name(), new RenrenWeibo());
    }
    
}

