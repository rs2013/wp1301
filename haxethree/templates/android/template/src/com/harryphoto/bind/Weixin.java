package com.harryphoto.bind;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.text.TextUtils;
import android.util.Log;

import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;
import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.SendMessageToWX;
import com.tencent.mm.sdk.openapi.WXAPIFactory;
import com.tencent.mm.sdk.openapi.WXImageObject;
import com.tencent.mm.sdk.openapi.WXMediaMessage;
import com.tencent.mm.sdk.openapi.WXWebpageObject;
import com.weiplus.client.MainActivity;

public class Weixin extends Binding {

    private static final String APP_ID = "wx2b1d26c618452126";
    private static final String TAG = "WeixinBinding";

    private static IWXAPI api;
    
    public Weixin(String accessToken) {
        super();
        if (api == null) {
        api = WXAPIFactory.createWXAPI(MainActivity.getInstance(), APP_ID, true);
        api.registerApp(APP_ID);      
        }
    }
    
    @Override
    public String[] getBindInfo() {
        return new String[] { "accessToken", "" };
    }
    
    @Override
    public boolean isSessionValid() {
        return true;
    }
    
    @Override
    public Type getType() {
        return Type.WEIXIN;
    }
    
    @Override
    public void startAuth(final Activity activity, final HpListener listener) {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                listener.onComplete("ok");
            }
        });
    }
    
    @Override
    public void logout() {
    }
    
    @Override
    public void postStatus(final String text, final String link, final String imgPath, 
            final String lat, final String lon, final HpListener listener) {
        new Thread() {
            @Override 
            public void run() {
                try {
                    Bitmap bmp = null;
                    if (!TextUtils.isEmpty(imgPath)) {
                        bmp = BitmapFactory.decodeFile(imgPath);
                    }
                    WXMediaMessage.IMediaObject object = null;
                    if ("image".equals(lat)) {
                        object = new WXImageObject(bmp);
                     } else {
                        object = new WXWebpageObject();
                        ((WXWebpageObject) object).webpageUrl = link;
                    }
                    WXMediaMessage msg = new WXMediaMessage(object);
                    msg.title = "来自哈利波图";
                    msg.description = text;
                    Bitmap newbmp = null;
                    if (bmp != null) {
                        double ratio = Math.sqrt((320 * 240) / (double) (bmp.getWidth() * bmp.getHeight()));
                        newbmp = Bitmap.createScaledBitmap(bmp, (int) (bmp.getWidth() * ratio), 
                                (int) (bmp.getHeight() * ratio), false);
                        msg.setThumbImage(newbmp);
                    }
                    
                    SendMessageToWX.Req req = new SendMessageToWX.Req();
                    req.transaction = buildTransaction("webpage");
                    req.message = msg;
                    req.scene = /*isTimelineCb.isChecked() ? */SendMessageToWX.Req.WXSceneTimeline/* : SendMessageToWX.Req.WXSceneSession*/;
                    boolean result = api.sendReq(req);
                    if (result) {
                        listener.onComplete("ok");
                    } else {
                        listener.onError(new HpException("sendReq failed"));
                    }
                    if (bmp != null) bmp.recycle();
                    if (newbmp != null) newbmp.recycle();
                } catch (Throwable e) {
                    listener.onError(new HpException(e));
                }
            }
        }.start();
    }
    
    private String buildTransaction(final String type) {
        return (type == null) ? String.valueOf(System.currentTimeMillis()) : type + System.currentTimeMillis();
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
    }
    
}
