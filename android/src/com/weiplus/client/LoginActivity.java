package com.weiplus.client;

import java.io.IOException;

import org.json.*;

import com.harryphoto.api.AuthAPI;
import com.harryphoto.api.HpAccessToken;
import com.harryphoto.api.HpException;
import com.harryphoto.api.HpListener;
import com.harryphoto.api.Utility;
import com.harryphoto.bind.Binding;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Toast;

public class LoginActivity extends Activity {

    private Button btnWeibo, btnQQ, btnRenren;
    public static final String TAG = "LoginActivity";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.login_layout);
        
        final HpListener listener = new HpListener() {
            @Override
            public void onComplete(String response) {
                Log.i(TAG, "WeiboBind - onComplete: " + response);
                try {
                    JSONObject json = new JSONObject(response);
                    if (json.getInt("code") == 200) {
                        HpAccessToken tok = new HpAccessToken();
                        tok.setToken(json.getString("accessToken"));
                        tok.setRefreshToken(json.getString("refreshToken"));
                        tok.setExpiresTime(Long.MAX_VALUE);
                        tok.setUid("" + json.getJSONArray("users").getJSONObject(0).getLong("id"));
                        HpManager.setAccessToken(tok);
                        Utility.safeToast(LoginActivity.this, "连接成功", Toast.LENGTH_SHORT);
                        LoginActivity.this.finish();
                    } else {
                        throw new Exception("error code=" + json.getInt("code"));
                    }
                } catch (Exception e) {
                    onError(new HpException(e));
                }
            }

            @Override
            public void onIOException(IOException e) {
                Log.i(TAG, "WeiboBind - onIOException: " + e);
                onError(new HpException(e));
            }

            @Override
            public void onError(HpException e) {
                Log.i(TAG, "WeiboBind - onError: " + e);
                Utility.safeToast(LoginActivity.this, "连接失败, ex=" + e.getMessage(), Toast.LENGTH_SHORT);
                LoginActivity.this.finish();
            }
            
        };

        btnWeibo = (Button) findViewById(R.id.btnWeibo);
        btnWeibo.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                HpManager.getBinding(Binding.Type.SINA_WEIBO).startAuth(LoginActivity.this, new HpListener() {
                    @Override
                    public void onComplete(String response) {
                        Log.i(TAG, "SinaWeibo - onComplete: " + response);
                        if ("ok".equals(response)) {
                            Binding b = HpManager.getBinding(Binding.Type.SINA_WEIBO);
                            new AuthAPI(HpManager.getAccessToken()).bind(Binding.Type.SINA_WEIBO, b.getToken(), listener);
                        }
                    }

                    @Override
                    public void onIOException(IOException e) {
                        onError(new HpException(e));
                    }

                    @Override
                    public void onError(HpException e) {
                        Log.i(TAG, "SinaWeibo - onError: " + e);
                        Toast.makeText(LoginActivity.this, "新浪微博连接失败，请重试", Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });

        btnQQ = (Button) findViewById(R.id.btnQq);
        btnQQ.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                HpManager.getBinding(Binding.Type.TENCENT_WEIBO).startAuth(LoginActivity.this, new HpListener() {
                    @Override
                    public void onComplete(String response) {
                        Log.i(TAG, "TencentWeibo - onComplete: " + response);
                        if ("ok".equals(response)) {
                            Binding b = HpManager.getBinding(Binding.Type.TENCENT_WEIBO);
                            new AuthAPI(HpManager.getAccessToken()).bind(Binding.Type.TENCENT_WEIBO, b.getToken(), listener);
                        }
                    }

                    @Override
                    public void onIOException(IOException e) {
                        onError(new HpException(e));
                    }

                    @Override
                    public void onError(HpException e) {
                        Log.i(TAG, "TencentWeibo - onError: " + e);
                        Toast.makeText(LoginActivity.this, "腾讯微博连接失败，请重试", Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });

        btnRenren = (Button) findViewById(R.id.btnRenren);
        btnRenren.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                HpManager.getBinding(Binding.Type.RENREN_WEIBO).startAuth(LoginActivity.this, new HpListener() {
                    @Override
                    public void onComplete(String response) {
                        Log.i(TAG, "RenrenWeibo - onComplete: " + response);
                        if ("ok".equals(response)) {
                            Binding b = HpManager.getBinding(Binding.Type.RENREN_WEIBO);
                            new AuthAPI(HpManager.getAccessToken()).bind(Binding.Type.RENREN_WEIBO, b.getToken(), listener);
                        }
                    }

                    @Override
                    public void onIOException(IOException e) {
                        onError(new HpException(e));
                    }

                    @Override
                    public void onError(HpException e) {
                        Log.i(TAG, "RenrenWeibo - onError: " + e);
                        Utility.safeToast(LoginActivity.this, "人人网连接失败，请重试", Toast.LENGTH_SHORT);
                    }
                });
            }
        });

    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        btnWeibo.setEnabled(false);
        btnQQ.setEnabled(false);
        btnRenren.setEnabled(false);
        HpManager.onActivityResult(this, requestCode, resultCode, data);
    }
}
