package com.weiplus.client;

import java.io.IOException;

import org.haxe.nme.HaxeObject;

import android.util.Log;

import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;
import com.harryphoto.api.Utility;

class HaxeCallback implements HpListener {
    
    public HaxeObject callback;
    public String apiName;
    
    public HaxeCallback(String name, HaxeObject callback) {
        this.apiName = name;
        this.callback = callback;
    }

    @Override
    public void onComplete(String response) {
        Utility.haxeOk(callback, apiName, response);
    }

    @Override
    public void onIOException(IOException e) {
        Utility.haxeError(callback, apiName, e);
    }

    @Override
    public void onError(HpException e) {
        Utility.haxeError(callback, apiName, e);
    }
    
}