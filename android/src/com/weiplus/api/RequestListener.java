package com.weiplus.api;

import java.io.IOException;

/**
 * 发起访问接口的请求时所需的回调接口
 */
public interface RequestListener {
    /**
     * 用于获取服务器返回的响应内容
     * @param response
     */
	public void onComplete(String response);

	public void onIOException(IOException e);

	public void onError(WeiplusException e);

}
