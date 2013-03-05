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
                            new AuthAPI(HpManager.getAccessToken()).bind(Binding.Type.SINA_WEIBO, b.getToken(), new HpListener() {

                                @Override
                                public void onComplete(String response) {
                                    Log.i(TAG, "SinaWeiboBind - onComplete: " + response);
                                    try {
                                        JSONObject json = new JSONObject(response);
                                        if (json.getInt("code") == 200) {
                                            HpAccessToken tok = new HpAccessToken();
                                            tok.setToken(json.getString("accessToken"));
                                            tok.setRefreshToken(json.getString("refreshToken"));
                                            tok.setExpiresTime(Long.MAX_VALUE);
                                            tok.setUid("" + json.getJSONArray("users").getJSONObject(0).getLong("id"));
                                            HpManager.setAccessToken(tok);
                                        }
                                    } catch (JSONException e) {
                                        onError(new HpException(e));
                                    }
                                    Utility.safeToast(LoginActivity.this, "新浪微博连接成功", Toast.LENGTH_SHORT);
                                    LoginActivity.this.finish();
                                }

                                @Override
                                public void onIOException(IOException e) {
                                    Log.i(TAG, "SinaWeiboBind - onIOException: " + e);
                                }

                                @Override
                                public void onError(HpException e) {
                                    Log.i(TAG, "SinaWeiboBind - onError: " + e);
                                }
                                
                            });
                        }
                    }

                    @Override
                    public void onIOException(IOException e) {
                        Log.i(TAG, "SinaWeibo - onIOException: " + e);
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
        btnRenren = (Button) findViewById(R.id.btnRenren);
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
