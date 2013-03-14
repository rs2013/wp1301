package com.weiplus.client;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;

import org.haxe.nme.HaxeObject;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.util.Log;
import android.widget.Toast;

import com.harryphoto.api.AuthAPI;
import com.harryphoto.api.HpAccessToken;
import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;
import com.harryphoto.api.StatusAPI;
import com.harryphoto.api.UserAPI;
import com.harryphoto.api.Utility;
import com.harryphoto.bind.*;
import com.harryphoto.bind.Binding.Type;

public class HpManager {
    
    private static String PREFERENCES_NAME = "com_harryphoto_api_HpAPI";
    private static String LINK = "http://s-56378.gotocdn.com/harryphoto/statuses/show/${ID}.json";
    
    private static HpAccessToken accessToken;
    
    private static HashMap<String, Binding> bindings = new HashMap<String, Binding>();
    private static HashMap<String, String> imgMapping = new HashMap<String, String>();
    
    public static boolean check() {
        getAccessToken();
        if (accessToken.isSessionValid() && bindings.size() == 0) {
            AuthAPI api = new AuthAPI(accessToken);
            api.login(new HpListener() {

                @Override
                public void onComplete(String response) {
                    try {
                        JSONObject obj = new JSONObject(response);
                        if (obj.getInt("code") != 200) throw new Exception("login error, code=" + obj.getInt("code"));
                        JSONArray bindUsers = obj.getJSONArray("users").getJSONObject(0).getJSONArray("bindUsers");
                        for (int i = 0, n = bindUsers.length(); i < n; i++) {
                            JSONObject bu = bindUsers.getJSONObject(i);
                            Type type = Type.valueOf(bu.getString("bindType"));
                            String[] param = new String[] { bu.optString("accessToken", ""), bu.optString("bindId", "") };
                            Binding b = HpManager.createBinding(type, param);
                            HpManager.addBinding(b);
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
                public void onError(HpException e) {
                    Utility.safeToast("账户同步异常。ex=" + e.getMessage(), Toast.LENGTH_SHORT);
                }
                
            });
        }
        return accessToken.isSessionValid();
    }
    
    public static void login() {
        Activity activity = MainActivity.getInstance();
        HpAccessToken token = getAccessToken();
        Intent intent = new Intent(activity, LoginActivity.class); 
        if (token.isSessionValid()) {
            ArrayList<String> l = new ArrayList<String>();
            l.add(Binding.Type.SINA_WEIBO.name());
            l.add(Binding.Type.TENCENT_WEIBO.name());
            l.add(Binding.Type.RENREN_WEIBO.name());
            for (Binding b: bindings.values()) {
                if (b.isSessionValid()) {
                    l.remove(b.getType().name());
                }
            }
            intent.putExtra("bindTypes", l.toArray(new String[0]));
        }
        activity.startActivity(intent);
    }
    
    public static void bind(String type) {
        Activity activity = MainActivity.getInstance();
        HpAccessToken token = getAccessToken();
        Intent intent = new Intent(activity, LoginActivity.class); 
        if (token.isSessionValid()) {
            intent.putExtra("bindTypes", new String[] { type });
        }
        activity.startActivity(intent);
    }
    
    public static void getPublicTimeline(int page, int rows, long sinceId, HaxeObject callback) {
        StatusAPI api = new StatusAPI(accessToken);
        api.publicTimeline(page, rows, sinceId, new HaxeCallback("statuses_public_timeline", callback)); 
    }
    
    public static void getHomeTimeline(int page, int rows, long sinceId, HaxeObject callback) {
        StatusAPI api = new StatusAPI(accessToken);
        api.homeTimeline("", page, rows, sinceId, new HaxeCallback("statuses_home_timeline", callback));
    }
    
    public static void getUserTimeline(String uid, int page, int rows, long sinceId, HaxeObject callback) {
        StatusAPI api = new StatusAPI(accessToken);
        api.userTimeline(uid != null ? uid : "", page, rows, sinceId, new HaxeCallback("statuses_user_timeline", callback));
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
    
    /**
     * 
     * @return <accessToken>\n<refreshToken>
     */
    public static String getTokenAsJson() {
        HpAccessToken t = getAccessToken();
        return "{\"accessToken\":\"" + t.getToken() + "\"," +
                "\"refreshToken\":\"" + t.getRefreshToken() + "\"," +
                "\"expiresTime\":" + t.getExpiresTime() + "," + 
                "\"uid\":\"" + t.getUid() + "\"}";
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
    
    public static boolean hasBinding(String type) {
        return bindings.containsKey(type);
    }
    
    public static boolean isBindingSessionValid(String type) {
        Binding b;
        return (b = bindings.get(type)) != null ? b.isSessionValid() : false;
    }
    
    public static String getImageUrl(String imagePath) {
        return imgMapping.get(imagePath);
    }
    
    public static void addBinding(Binding b) {
        bindings.put(b.getType().name(), b);
    }
    
    public static Binding createBinding(Binding.Type type) {
        return createBinding(type, new String[] { "", "" });
    }
    
    public static Binding createBinding(Binding.Type type, String[] param) {
        Binding b = null;
        switch (type) {
        case TENCENT_WEIBO:
            b = new TencentWeibo(param[0], param[1]);
            break;
        case SINA_WEIBO:
            b = new SinaWeibo(param[0]);
            break;
        case RENREN_WEIBO:
            b = new RenrenWeibo(param[0]);
            break;
        default:
            
        }
        return b;
    }
    
}

