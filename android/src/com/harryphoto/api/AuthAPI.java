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
    
    public void bind(Binding.Type bindType, String bindAccessToken, HpListener listener) {
        HpParameters parm = new HpParameters();
        parm.add("bindType", bindType.name());
        parm.add("accessToken", bindAccessToken);
        get("auth/bind", parm, listener);
    }
    
    public void unbind() {
        
    }
    
    public void update() {
        
    }
    
    public void merge() {
        
    }
    
}
