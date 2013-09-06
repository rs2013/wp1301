package com.harryphoto.bind;

import com.harryphoto.api.HpListener;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

abstract public class Binding {
    
    public enum Type {
        HARRYPHOTO_WEIBO,
        SINA_WEIBO, 
        TENCENT_WEIBO, 
        RENREN_WEIBO,
        WEIXIN;
        
        public String toString() {
            switch (this) {
            case HARRYPHOTO_WEIBO: return "哈利波图";
            case SINA_WEIBO: return "新浪微博";
            case TENCENT_WEIBO: return "腾讯微博";
            case RENREN_WEIBO: return "人人网";
            case WEIXIN: return "微信";
            }
            return "";
        }
    }
    
    protected boolean isEnabled = true;

    public Binding() {
    }
    
    public boolean isEnabled() {
        return isEnabled;
    }
    
    public void setEnabled(boolean enabled) {
        this.isEnabled = enabled;
    }
    
    abstract public Type getType();
    
    abstract public String[] getBindInfo();
    
    abstract public boolean isSessionValid();
    
    abstract public void startAuth(Activity activity, HpListener listener);
    
    abstract public void logout();
    
    abstract public void postStatus(String text, String link, String imagePath, String lat, String lon, HpListener listener);
    
    abstract public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data);
     
}
