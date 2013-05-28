package com.harryphoto.api;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.text.TextUtils;
import android.util.Log;

public abstract class HpAPI {
    /**
     */
//  public static final String API_SERVER = "http://api.harryphoto.com";
//    public static final String API_SERVER = "http://www.appmagics.com/api";
    public static final String API_SERVER = "http://www.appmagics.cn/api";
	public static final String POST = "POST";
	public static final String GET = "GET";

	public HpAccessToken accessToken;

	/**
	 * @param accesssToken HpAccessToken can be null
	 */
	public HpAPI(HpAccessToken accessToken){
	    setAccessToken(accessToken);
	}
	
	public void setAccessToken(HpAccessToken accessToken) {
	    this.accessToken = accessToken;
	}
	
    protected void request(final String uri, final HpParameters params,
            final String httpMethod, final HpListener listener) {
        int idx = 0;
        if (accessToken != null && accessToken.getToken() != "") {
            params.add("accessToken", false, accessToken.getToken(), idx++);
        }
        String refTok = accessToken != null ? accessToken.getRefreshToken() : null;
        params.add("refreshToken", false, TextUtils.isEmpty(refTok) ? "0" : refTok, idx++);
        new Thread() {
            @Override
            public void run() {
                try {
                    String url = API_SERVER + "/" + uri + ".json";
                    Log.i("HpAPI", httpMethod + ": url=" + url + ",params=" + Utility.encodeParameters(params));
                    String resp = HttpManager.openUrl(url, httpMethod, params);
                    listener.onComplete(resp);
                } catch (HpException e) {
                    listener.onError(e);
                }
            }
        }.start();
    }
    
    protected void get(String uri, HpParameters params, HpListener listener) {
        request(uri, params, GET, listener);
    }
    
}
