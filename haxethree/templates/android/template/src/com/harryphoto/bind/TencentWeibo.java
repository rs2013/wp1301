package com.harryphoto.bind;

import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.text.TextUtils;
import android.util.Log;

import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;
import com.tencent.weibo.api.TAPI;
import com.tencent.weibo.api.UserAPI;
import com.tencent.weibo.constants.OAuthConstants;
import com.tencent.weibo.oauthv2.OAuthV2;
import com.tencent.weibo.webview.OAuthV2AuthorizeWebView;
import com.weiplus.client.MainActivity;

public class TencentWeibo extends Binding {

    private static String PREFERENCES_NAME = "com_harryphoto_bind_TencentWeibo";
    
//    private static final String appKey = "801281378"; // "801323295";
//    private static final String appSecret = "eda1cb33187242501117d7d8b53d8f24"; // "6583db36c3f4b745c555f92e2249614c";
//    private static final String redirecturl = "http://www.baidu.com"; // "http://blog.csdn.net/rocks_lee";
//    App Key：801345195
//    App Secret：e625c709d89bdd187a7862fa2b0f6fa5
//    RedirectURL: http://www.appmagics.com
    private static final String appKey = "801345195"; // "801323295";
    private static final String appSecret = "e625c709d89bdd187a7862fa2b0f6fa5"; // "6583db36c3f4b745c555f92e2249614c";
    private static final String redirecturl = "http://www.appmagics.com"; // "http://blog.csdn.net/rocks_lee";
    
    private OAuthV2 oAuth;
    private HpListener listener;
    
    public TencentWeibo(String accessToken, String openid) {
        super();
        loadOAuth();
        if (!TextUtils.isEmpty(accessToken) && !TextUtils.isEmpty(openid)) {
            oAuth.setAccessToken(accessToken);
            oAuth.setOpenid(openid);
            oAuth.setExpiresIn("604800"); // 7 days
        }
    }
    
    @Override
    public String[] getBindInfo() {
        return new String[] { 
                "accessToken", oAuth.getAccessToken(), 
                "openId", oAuth.getOpenid() };
    }
    
    @Override
    public boolean isSessionValid() {
        return oAuth.getAccessToken().length() > 0;
    }
    
    @Override
    public Type getType() {
        return Type.TENCENT_WEIBO;
    }
    
    private void loadOAuth() {
        oAuth = new OAuthV2(redirecturl);
        oAuth.setClientId(appKey);
        oAuth.setClientSecret(appSecret);
        SharedPreferences pref = MainActivity.getInstance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_APPEND);
        oAuth.setAccessToken(pref.getString("accessToken", ""));
        oAuth.setExpiresIn(pref.getString("expiresIn", ""));
        oAuth.setOpenid(pref.getString("openid", ""));
        oAuth.setOpenkey(pref.getString("openKey", ""));
    }
    
    @Override
    public void startAuth(final Activity activity, HpListener listener) {
        this.listener = listener;
        if (isSessionValid()) {
            logout();
//            new Thread() {
//                @Override
//                public void run() {
//                    UserAPI accountApi = new UserAPI(OAuthConstants.OAUTH_VERSION_2_A);
//                    try {
//                        String info = accountApi.info(oAuth, "json");
//                        if (info == null || info.length() == 0) throw new Exception();
//                    } catch (Exception ex) {
//                        startAuthDialog(activity);
//                    }
//                }
//            }.start();
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
        oAuth.setAccessToken("");
        oAuth.setExpiresIn("");
        oAuth.setOpenid("");
        oAuth.setOpenkey("");
    }
    
    @Override
    public void postStatus(final String text, final String link, final String imgPath, 
            final String lat, final String lon, final HpListener listener) {
        new Thread() {
            @Override 
            public void run() {
                TAPI statusApi = new TAPI(OAuthConstants.OAUTH_VERSION_2_A);
                String content = text + " See: " + link; // TODO: text length must <= 140
                String response = "";
                try {
                    if (TextUtils.isEmpty(imgPath)) {
                        response = statusApi.add(oAuth, "json", content, "127.0.0.1", "", "", "");
                    } else {
                        response = statusApi.addPic(oAuth, "json", content, "127.0.0.1", "", "", imgPath, "");
                    }
                    JSONObject obj = new JSONObject(response);
                    if (obj.getInt("errcode") != 0) {
                        throw new HpException("error, errcode=" + obj.getInt("errcode") + 
                                ",msg=" + obj.getString("msg"));
                    }
                    listener.onComplete(response);
                } catch (Exception e) {
                    listener.onError(new HpException(e));
                }
                
            }
        }.start();
    }
    
/********************************* Non-Binging routines *******************************/
    public void startAuthDialog(Activity activity) {
        OAuthV2 oAuth = new OAuthV2(redirecturl);
        oAuth.setClientId(appKey);
        oAuth.setClientSecret(appSecret);
        Intent intent = new Intent(activity, OAuthV2AuthorizeWebView.class);
        intent.putExtra("oauth", oAuth);  
        activity.startActivityForResult(intent, 13123);
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        if (requestCode != 13123) return;
        if (resultCode == OAuthV2AuthorizeWebView.RESULT_CODE) {
            oAuth = (OAuthV2) data.getExtras().getSerializable("oauth");
            SharedPreferences pref = MainActivity.getInstance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_APPEND);
            Editor editor = pref.edit();
            editor.putString("accessToken", oAuth.getAccessToken());
            editor.putString("expiresIn", oAuth.getExpiresIn());
            editor.putString("openid", oAuth.getOpenid());
            editor.putString("openKey", oAuth.getOpenkey());
            editor.commit();
            listener.onComplete("ok");
        } else {
            listener.onComplete("cancel");
        }
    }

}
