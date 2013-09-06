package com.harryphoto.api;

import java.util.*;

import org.json.*;

import android.text.TextUtils;
import android.util.Log;

/**
 * 此类封装了“access_token”，“expires_in”，"refresh_token"，
 *并提供了他们的管理功能
 */
public class HpAccessToken {
	private String mAccessToken = "";
	private String mRefreshToken = "";
	private String mUid = "";
	private long mExpiresTime = 0;
	private Set<String> disabledBindings = new HashSet<String>();

//	private String mOauth_verifier = "";
//	protected String[] responseStr = null;
//	protected SecretKeySpec mSecretKeySpec;
	/**
	 * WeiplusAccessToken 的构造函数
	 */
	public HpAccessToken() {
	}
	/**
	 *  AccessToken是否有效,如果accessToken为空或者expiresTime过期，返回false，否则返回true
	 *  @return 如果accessToken为空或者expiresTime过期，返回false，否则返回true
	 */
	public boolean isSessionValid() {
		return !TextUtils.isEmpty(mAccessToken);
	}
	/**
	 * 获取accessToken
	 */
	public String getToken() {
		return this.mAccessToken;
	}
	/**
     * 获取refreshToken
     */
	public String getRefreshToken() {
		return mRefreshToken;
	}
	
	public String getUid() {
	    return mUid;
	}
	/**
	 * 设置refreshToken
	 * @param mRefreshToken
	 */
	public void setRefreshToken(String mRefreshToken) {
		this.mRefreshToken = mRefreshToken;
	}
	/**
	 * 获取超时时间，单位: 毫秒，表示从格林威治时间1970年01月01日00时00分00秒起至现在的总 毫秒数
	 */
	public long getExpiresTime() {
		return mExpiresTime;
	}

	/**
	 * 设置过期时间长度值，仅当从服务器获取到数据时使用此方法
	 *            
	 */
	public void setExpiresIn(String expiresIn) {
		if (expiresIn != null && !expiresIn.equals("0")) {
			setExpiresTime(System.currentTimeMillis() + Long.parseLong(expiresIn) * 1000);
		}
	}

	/**
	 * 设置过期时刻点 时间值
	 * @param mExpiresTime 单位：毫秒，表示从格林威治时间1970年01月01日00时00分00秒起至现在的总 毫秒数
	 *            
	 */
	public void setExpiresTime(long mExpiresTime) {
		this.mExpiresTime = mExpiresTime;
	}
	/**
	 * 设置accessToken
	 * @param mToken
	 */
	public void setToken(String mToken) {
		this.mAccessToken = mToken;
	}
	
	public void setUid(String uid) {
	    this.mUid = uid;
	}
	
	public Set<String> getDisabledBindings() {
	    return this.disabledBindings;
	}
	
	public void setDisabledBindings(Set<String> disabledBindings) {
	    this.disabledBindings = disabledBindings;
	}
	
    public String getDisabledBindingsAsString() {
        StringBuilder buf = new StringBuilder();
        int i = 0;
        for (String s: this.disabledBindings) {
            if (i++ > 0) buf.append(',');
            buf.append(s);
        }
        Log.d("HpAccessToken", "getDisabledBindingAsString: '" + buf + "'");
        return buf.toString();
    }
    
    public void setDisabledBindingsFromString(String disabledBindings) {
        Set<String> set = new HashSet<String>();
        if (disabledBindings.length() > 0) {
            String[] ss = TextUtils.split(disabledBindings, ",");
            for (String s: ss) set.add(s);
        }
        Log.d("HpAccessToken", "setDisabledBindingsFromString: '" + disabledBindings + "';set=" + set);
        this.disabledBindings = set;
    }
    
//	/**
//	 * 设置检验者
//	 * @param verifier
//	 */
//	public void setVerifier(String verifier) {
//		mOauth_verifier = verifier;
//	}
//	/**
//	 * 获取检验者
//	 * @return
//	 */
//	public String getVerifier() {
//		return mOauth_verifier;
//	}
//	
//	public String getParameter(String parameter) {
//		String value = null;
//		for (String str : responseStr) {
//			if (str.startsWith(parameter + '=')) {
//				value = str.split("=")[1].trim();
//				break;
//			}
//		}
//		return value;
//	}

//	protected void setSecretKeySpec(SecretKeySpec secretKeySpec) {
//		this.mSecretKeySpec = secretKeySpec;
//	}
//
//	protected SecretKeySpec getSecretKeySpec() {
//		return mSecretKeySpec;
//	}
}