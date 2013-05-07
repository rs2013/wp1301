package com.weiplus.client;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.haxe.nme.HaxeObject;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Bitmap.Config;
import android.graphics.Matrix;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import com.harryphoto.api.AuthAPI;
import com.harryphoto.api.BitmapHelper;
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
    private static String LINK = "http://www.appmagics.com/w/statuses/show/${ID}";
    
    private static HpAccessToken accessToken;
    
    private static HashMap<String, Binding> bindings = new HashMap<String, Binding>();
    private static HashMap<String, String> imgMapping = new HashMap<String, String>();
    
    static Binding candidate = null;
    
    public static boolean login() {
        getAccessToken();
        if (accessToken.isSessionValid() && bindings.size() == 0) {
            AuthAPI api = new AuthAPI(accessToken);
            api.login(new HpListener() {

                @Override
                public void onComplete(String response) {
                    try {
                        JSONObject obj = new JSONObject(response);
                        if (obj.getInt("code") != 200) throw new Exception("error code " + obj.getInt("code"));
                        JSONArray bindUsers = obj.getJSONArray("users").getJSONObject(0).getJSONArray("bindUsers");
                        restoreBindings(bindUsers);
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
                    Utility.safeToast("登陆哈利波图服务器失败，请检查网络。ex=" + e.getMessage(), Toast.LENGTH_LONG);
                }
                
            });
        }
        return accessToken.isSessionValid();
    }
    
    public static void restoreBindings(JSONArray bindUsers) throws JSONException {
        for (int i = 0, n = bindUsers.length(); i < n; i++) {
            JSONObject bu = bindUsers.getJSONObject(i);
            Type type = Type.valueOf(bu.getString("bindType"));
            String[] param = new String[] { bu.optString("accessToken", ""), bu.optString("bindId", "") };
            Binding b = HpManager.createBinding(type, param);
            HpManager.addBinding(b);
            if (accessToken.getDisabledBindings().contains(type.name())) {
                b.setEnabled(false);
            }
        }
    }
    
    public static void loginOld() {
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
    
    public static void postStatus(final String[] bindTypes, 
            final String text, final String imgPath, 
            final String type, final String filePath, 
            final String lat, final String lon, final HaxeObject callback) {
        StatusAPI api = new StatusAPI(accessToken);
        String smallpath = null;
        if (!TextUtils.isEmpty(imgPath)) {
            int[] info = BitmapHelper.bitmapInfo(imgPath);
            if (info[0] > 480) {
                Bitmap bmp = BitmapFactory.decodeFile(imgPath);
                float ratio = 480 / (float) bmp.getWidth();
                Bitmap newbmp = Bitmap.createBitmap(480, (int) (bmp.getHeight() * ratio), Config.ARGB_8888);
                Canvas cv = new Canvas(newbmp);
                Matrix mat = new Matrix();
                mat.setScale(ratio, ratio);
                cv.drawBitmap(bmp, mat, null);
                cv.save(Canvas.ALL_SAVE_FLAG);
                int idx = imgPath.lastIndexOf('.');
                smallpath = imgPath.substring(0, idx) + "_small.jpg";
                try {
                    FileOutputStream fos = new FileOutputStream(smallpath);
                    newbmp.compress(Bitmap.CompressFormat.JPEG, 80, fos);
                     fos.close();
                } catch (IOException e) {
                    Log.w("HpManager", "Error creating bitmap file " + smallpath + ", ex=" + e.getMessage());
                }
            }
        }
        final String smallImgPath = smallpath == null ? imgPath : smallpath; 
        api.post(text, imgPath, type, filePath, lat, lon, new HpListener() {

            @Override
            public void onComplete(String response) {
                try {
                    JSONObject json = new JSONObject(response);
                    if (json.getInt("code") == 200) {
                        JSONObject st = json.getJSONArray("statuses").getJSONObject(0);
                        long statusId = st.getLong("id");
                        String imgUrl = st.getJSONArray("attachments").getJSONObject(0).getString("thumbUrl");
                        imgMapping.put(smallImgPath, imgUrl);
                        String link = LINK.replace("${ID}", "" + statusId);
                        List<String> list = bindTypes != null ? Arrays.asList(bindTypes) : null;
                        for (Binding b: bindings.values()) {
                            if (b.isSessionValid() && (list == null || list.contains(b.getType().name()))) {
                                b.postStatus(text, link, smallImgPath, lat, lon, new ToastCallback(MainActivity.getInstance(), b.getType() + "同步"));
                            }
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
            token.setDisabledBindingsFromString(pref.getString("disabledBindings", ""));
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
        editor.putString("disabledBindings", accessToken.getDisabledBindingsAsString());
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
            accessToken.setDisabledBindings(new HashSet<String>());
        }
        Binding.Type[] types = new Binding.Type[] { 
                Binding.Type.SINA_WEIBO, Binding.Type.TENCENT_WEIBO, Binding.Type.RENREN_WEIBO,
        };
        for (Binding.Type t: types) {
            createBinding(t, new String[] { "", "" } ).logout();
        }
        bindings.clear();
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
    
    public static boolean isBindingEnabled(String type) {
        return bindings.containsKey(type) && bindings.get(type).isEnabled();
    }
    
    public static void setBindingEnabled(String type, boolean enabled) {
        if (bindings.containsKey(type)) {
            bindings.get(type).setEnabled(enabled);
            Set<String> disabled = accessToken.getDisabledBindings();
            if (enabled) {
                disabled.remove(type);
            } else {
                disabled.add(type);
            }
            accessToken.setDisabledBindings(disabled);
            saveAccessToken();
        }
    }
    
    public static boolean isBindingSessionValid(String type) {
        Binding b;
        return (b = bindings.get(type)) != null ? b.isSessionValid() : false;
    }
    
    public static void startAuth(final String type, final HaxeObject callback) {
        candidate = bindings.get(type);
        if (candidate == null) candidate = createBinding(Binding.Type.valueOf(type));
        candidate.startAuth(MainActivity.getInstance(), new HpListener() {

            @Override
            public void onComplete(String response) {
                if ("ok".equals(response)) {
                    new AuthAPI(HpManager.getAccessToken())
                            .bind(candidate.getType(), candidate.getBindInfo(), new BindListener(callback));
                } else if ("cancel".equals(response)) {
                    Utility.haxeOk(callback, "startAuth", "cancel");
                }
            }

            @Override
            public void onIOException(IOException e) {
                onError(new HpException(e));
            }

            @Override
            public void onError(HpException e) {
                Utility.safeToast(Binding.Type.valueOf(type) + "登录失败，请重试", Toast.LENGTH_SHORT);
                Utility.haxeError(callback, "startAuth", e);
                candidate = null;
            }
            
        });
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
    
    public static Binding getCandidate() {
        return candidate;
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

class BindListener implements HpListener {
    
    private static final String TAG = "BindListener";
    private HaxeObject callback;
    
    public BindListener(HaxeObject callback) {
        this.callback = callback;
    }
    
    @Override
    public void onComplete(String response) {
        Log.i(TAG, "onComplete: " + response);
        try {
            JSONObject json = new JSONObject(response);
            if (json.getInt("code") != 200) {
                throw new Exception("error code=" + json.getInt("code"));
            }
            JSONArray users = json.getJSONArray("users");
            Activity activity = MainActivity.getInstance();
            if (users.length() == 1) {
                HpAccessToken tok = new HpAccessToken();
                tok.setToken(json.getString("accessToken"));
                tok.setRefreshToken(json.getString("refreshToken"));
                tok.setExpiresTime(Long.MAX_VALUE);
                tok.setUid("" + json.getJSONArray("users").getJSONObject(0).getLong("id"));
                HpManager.setAccessToken(tok);
            }
            if (users.length() > 1) { // needing merge
                JSONObject second = null;
                Binding cand = HpManager.candidate;
outer:
                for (int i = users.length(); --i >= 0;) {
                    JSONObject u = users.getJSONObject(i);
                    JSONArray bindusers = u.getJSONArray("bindUsers");
                    for (int j = bindusers.length(); --j >= 0;) {
                        JSONObject bu = bindusers.getJSONObject(j);
                        if (cand.getType().name().equals(bu.getString("bindType")) && 
                                cand.getBindInfo()[1].equals(bu.getString("accessToken"))) {
                            second = u;
                            break outer;
                        }
                    }
                }
                AuthAPI api = new AuthAPI(HpManager.getAccessToken());
                api.merge(second.getString("accessToken"), new HpListener() {

                    @Override
                    public void onComplete(String response) {
                        try {
                            JSONObject json = new JSONObject(response);
                            if (json.getInt("code") != 200) {
                                throw new Exception("error code=" + json.getInt("code"));
                            }
                            HpManager.addBinding(HpManager.candidate);
                            Utility.safeToast(MainActivity.getInstance(), HpManager.candidate.getType() + "账号合并成功", Toast.LENGTH_SHORT);
                            HpManager.candidate = null;
                            HpManager.login();
                            Utility.haxeOk(callback, "startAuth", "ok");
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
                        Log.i(TAG, "Merge.onError: " + e);
                        Activity activity = MainActivity.getInstance();
                        Utility.safeToast(activity, HpManager.candidate.getType() + "账号合并失败, ex=" + e.getMessage(), Toast.LENGTH_LONG);
                        Utility.haxeError(callback, "startAuth", e);
                    }
                    
                });
            } else {
//                HpManager.addBinding(HpManager.candidate);
                HpManager.restoreBindings(users.getJSONObject(0).getJSONArray("bindUsers"));
                Utility.safeToast(activity, HpManager.candidate.getType() + "账号登录成功", Toast.LENGTH_SHORT);
                HpManager.candidate = null;
                Utility.haxeOk(callback, "startAuth", "ok");
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
        Log.i(TAG, "onError: " + e);
        Activity activity = MainActivity.getInstance();
        Utility.safeToast(activity, HpManager.candidate.getType() + "账号绑定失败, ex=" + e.getMessage(), Toast.LENGTH_LONG);
        Utility.haxeError(callback, "startAuth", e);
    }
    
}
