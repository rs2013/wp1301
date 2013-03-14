package com.harryphoto.api;

import com.harryphoto.bind.Binding;

public class AuthAPI extends HpAPI {

    public AuthAPI(HpAccessToken accessToken) {
        super(accessToken);
    }

    public void login(HpListener listener) {
        HpParameters parm = new HpParameters();
        get("auth/login", parm, listener);
    }
    
    public void logout(HpListener listener) {
        
    }
    
    public void bind(Binding.Type bindType, String[] bindInfo, HpListener listener) {
        HpParameters parm = new HpParameters();
        parm.add("bindType", bindType.name());
        if (bindInfo != null && bindInfo.length > 0) {
            for (int i = 0, n = (bindInfo.length >> 1); i < n; i++) {
                parm.add(bindInfo[i * 2], bindInfo[i * 2 + 1]);
            }
            parm.add("refreshToken", "");
        }
        get("auth/bind", parm, listener);
    }
    
    public void unbind() {
        
    }
    
    public void update() {
        
    }
    
    public void merge(String accessToken, HpListener listener) {
        HpParameters parm = new HpParameters();
        parm.add("accessToken", accessToken);
        parm.add("refreshToken", "");
        get("auth/merge", parm, listener);
    }
    
}
