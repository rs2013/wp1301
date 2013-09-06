package com.harryphoto.bind;


import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;
import com.renren.api.connect.android.Renren;
import com.renren.api.connect.android.exception.RenrenAuthError;
import com.renren.api.connect.android.feed.FeedPublishRequestParam;
import com.renren.api.connect.android.feed.FeedPublishResponseBean;
import com.renren.api.connect.android.view.RenrenAuthListener;
import com.weiplus.client.HpManager;
import com.weiplus.client.MainActivity;

public class RenrenWeibo extends Binding {

//    private static final String appId = "220963";
//    private static final String apiSecret = "60b5910c51e348d79c1cd2bceb9092e2";
//    private static final String apiKey = "7df935bc67c843adb1fd9a3dba61551a";
//    应用ID：230591
//    API Key：ccfdcd149d2a48c699c96d5330acfe3c
//    Secret Key：12b5efc8449b47a4949b8eae2abc7814 
    private static final String appId = "230591";
    private static final String apiSecret = "12b5efc8449b47a4949b8eae2abc7814";
    private static final String apiKey = "ccfdcd149d2a48c699c96d5330acfe3c";

    private Renren renren;
    private HpListener listener;
    
    public RenrenWeibo(String accessToken) {
        super();
        renren = new Renren(apiKey, apiSecret, appId, MainActivity.getInstance());
        if (!TextUtils.isEmpty(accessToken)) {
            renren.updateAccessToken(accessToken);
        }
    }
    
    @Override
    public String[] getBindInfo() {
        return new String[] { "accessToken", renren.getAccessToken() };
    }
    
    @Override
    public boolean isSessionValid() {
        return renren.isSessionKeyValid();
    }
    
    @Override
    public Type getType() {
        return Type.RENREN_WEIBO;
    }
    
    @Override
    public void startAuth(final Activity activity, HpListener listener) {
        this.listener = listener;
        if (renren.isSessionKeyValid()) { 
            logout();
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
        renren.logout(MainActivity.getInstance());
    }
    
    @Override
    public void postStatus(final String text, final String link, final String imgPath, 
            final String lat, final String lon, final HpListener listener) {
        new Thread() {
            @Override 
            public void run() {
                String imgUrl = HpManager.getImageUrl(imgPath);
                FeedPublishRequestParam feed = new FeedPublishRequestParam("来自哈利波图", text, link, 
                        imgUrl, null, null, null, null);
                try {
                    FeedPublishResponseBean bean = renren.publishFeed(feed);
                    long postId = bean.getPostId();
                    if (postId == 0) throw new Exception("postId is 0");
                    listener.onComplete("{\"postId\":" + postId + "}");
                } catch (Throwable e) {
                    listener.onError(new HpException(e));
                }
            }
        }.start();
    }
    
/********************************* Non-Binging routines *******************************/

    public void startAuthDialog(Activity activity) {
        final RenrenAuthListener rl = new RenrenAuthListener() {

            @Override
            public void onComplete(Bundle values) {
                Log.d("RenrenConnect", values.toString());
                listener.onComplete("ok"); 
            }

            @Override
            public void onRenrenAuthError(RenrenAuthError renrenAuthError) {
                listener.onError(new HpException(renrenAuthError));
            }

            @Override
            public void onCancelLogin() {
                listener.onComplete("cancel");
            }

            @Override
            public void onCancelAuth(Bundle values) {
                listener.onComplete("cancel");
            }
            
        };
        renren.authorize(activity, null, rl, 23875); // 23875: random requestCode
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        if (requestCode == 23875 && renren != null) {
            renren.authorizeCallback(requestCode, resultCode, data);
        }
    }

}
