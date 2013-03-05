package com.harryphoto.api;

import android.text.TextUtils;

public class StatusAPI extends HpAPI {

    public StatusAPI(HpAccessToken accessToken) {
        super(accessToken);
    }

    public void publicTimeline(HpListener listener) {
        HpParameters parm = new HpParameters();
        get("statuses/public_timeline", parm, listener);
    }
    
    public void homeTimeline(String uid, HpListener listener) {
        HpParameters parm = new HpParameters();
        uid = TextUtils.isEmpty(uid) ? accessToken.getUid() : uid;
        get("statuses/home_timeline/" + uid, parm, listener);
    }
    
    public void userTimeline(String uid, HpListener listener) {
        HpParameters parm = new HpParameters();
        uid = TextUtils.isEmpty(uid) ? accessToken.getUid() : uid;
        get("statuses/user_timeline/" + uid, parm, listener);
    }
    
    public void post(String text, String imgPath, String type, String filePath, 
            String lat, String lon, HpListener listener) {
        HpParameters parm = new HpParameters();
        parm.add("status", text);
        parm.add("channel", "");
        parm.add("latitude", lat);
        parm.add("longitude", lon);
        parm.add("digest", "");
        parm.add("delay", 0);
        parm.add("vlocation", "");
        parm.add("location", "");
        parm.add("geo", "");
        parm.add("tag", "");
        parm.add("format", "json");
        boolean hasImage = !TextUtils.isEmpty(imgPath);
        parm.add("thumbData", true, hasImage ? imgPath : "", -1);
//        int idx = hasImage ? imgPath.lastIndexOf('/') : 0;
//        parm.add("thumbName", hasImage ? imgPath.substring(idx + 1) : "");
        int[] info = hasImage ? BitmapHelper.bitmapInfo(imgPath) : null;
        parm.add("thumbWidth", hasImage ? "" + info[0] : "");
        parm.add("thumbHeight", hasImage ? "" + info[1] : "");
        boolean hasFile = !TextUtils.isEmpty(filePath);
        int idx = hasFile ? filePath.lastIndexOf('/') : 0;
        parm.add("attachName", hasFile ? filePath.substring(idx + 1) : "");
        parm.add("attachData", true, hasFile ? filePath : "", -1);
        parm.add("attachType", hasFile ? type : "");
        parm.add("attachMime", hasFile ? Utility.getMimeType(Utility.getFileExt(filePath)) : "");
//        parm.add("attachSize", hasFile ? (int) new File(filePath).length() : 0);
        parm.add("attachSource", 1);
        request("statuses/create", parm, HpAPI.POST, listener);
    }
    
}
