package com.harryphoto.api;

import android.text.TextUtils;

public class UserAPI extends HpAPI {

    public UserAPI(HpAccessToken accessToken) {
        super(accessToken);
    }

    public void show(String uid, HpListener listener) {
        HpParameters parm = new HpParameters();
        uid = TextUtils.isEmpty(uid) ? accessToken.getUid() : uid;
        get("users/show" + uid, parm, listener);
    }
    
}
