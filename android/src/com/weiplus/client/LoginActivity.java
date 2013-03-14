package com.weiplus.client;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

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

    public static final String TAG = "LoginActivity";
    private Button btnWeibo, btnQQ, btnRenren;
    String[] bindTypes;
    Binding currBinding;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.login_layout);
        Intent it = this.getIntent();
        if (it.hasExtra("bindTypes")) {
            bindTypes = it.getStringArrayExtra("bindTypes");
        } else {
            bindTypes = null;
        }
        
        btnWeibo = (Button) findViewById(R.id.btnWeibo);
        btnQQ = (Button) findViewById(R.id.btnQq);
        btnRenren = (Button) findViewById(R.id.btnRenren);
        btnWeibo.setOnClickListener(getOnClickListener(Binding.Type.SINA_WEIBO));
        btnQQ.setOnClickListener(getOnClickListener(Binding.Type.TENCENT_WEIBO)); 
        btnRenren.setOnClickListener(getOnClickListener(Binding.Type.RENREN_WEIBO)); 
        
        enableButtons(null, false);
        enableButtons(bindTypes, true);
        
        if (bindTypes != null && bindTypes.length == 1) {
            final String type = bindTypes[0];
            this.runOnUiThread(new Runnable() {

                @Override
                public void run() {
                    LoginActivity.this.getOnClickListener(Binding.Type.valueOf(type)).onClick(null);
                }
                
            });
        }
    }
    
    private OnClickListener getOnClickListener(final Binding.Type type) {
        return new OnClickListener() {
            @Override
            public void onClick(View v) {
                final Binding binding = LoginActivity.this.currBinding = HpManager.createBinding(type);
                final HpListener listener = new BindListener(LoginActivity.this, binding);
                LoginActivity.this.enableButtons(LoginActivity.this.bindTypes, false);
                binding.startAuth(LoginActivity.this, new HpListener() {
                    @Override
                    public void onComplete(String response) {
                        Log.i(TAG, binding.getType().name() + " - onComplete: " + response);
                        if ("ok".equals(response)) {
                            new AuthAPI(HpManager.getAccessToken())
                                    .bind(binding.getType(), binding.getBindInfo(), listener);
                        }
                    }

                    @Override
                    public void onIOException(IOException e) {
                        onError(new HpException(e));
                    }

                    @Override
                    public void onError(HpException e) {
                        Log.i(TAG, binding.getType().name() + " - onError: " + e);
                        LoginActivity.this.enableButtons(LoginActivity.this.bindTypes, true);
                        Utility.safeToast(LoginActivity.this, binding.getType() + "连接失败，请重试", Toast.LENGTH_SHORT);
                    }
                });
            }
        };
    }
    
    void enableButtons(final String[] types, final boolean enable) {
        this.runOnUiThread(new Runnable() {

            @Override
            public void run() {
                List<String> l = types != null ? Arrays.asList(types) : null;
                if (l == null || l.contains(Binding.Type.SINA_WEIBO.name())) {
                    btnWeibo.setEnabled(enable);
                }
                if (l == null || l.contains(Binding.Type.TENCENT_WEIBO.name())) {
                    btnQQ.setEnabled(enable);
                }
                if (l == null || l.contains(Binding.Type.RENREN_WEIBO.name())) {
                    btnRenren.setEnabled(enable);
                }
            }
            
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (currBinding != null) {
            currBinding.onActivityResult(this, requestCode, resultCode, data);
        }
    }
}

class BindListener implements HpListener {
    
    private Binding binding;
    private LoginActivity activity;
    private static final String TAG = "BindListener";
    
    public BindListener(LoginActivity activity, Binding binding) {
        this.activity = activity;
        this.binding = binding;
    }
    
    @Override
    public void onComplete(String response) {
        Log.i(TAG, "onComplete: " + response);
        try {
            JSONObject json = new JSONObject(response);
            if (json.getInt("code") != 200) {
                throw new Exception("error code=" + json.getInt("code"));
            }
            if (!HpManager.getAccessToken().isSessionValid()) {
                HpAccessToken tok = new HpAccessToken();
                tok.setToken(json.getString("accessToken"));
                tok.setRefreshToken(json.getString("refreshToken"));
                tok.setExpiresTime(Long.MAX_VALUE);
                tok.setUid("" + json.getJSONArray("users").getJSONObject(0).getLong("id"));
                HpManager.setAccessToken(tok);
            }
            HpManager.addBinding(binding);
            JSONArray users = json.getJSONArray("users");
            if (users.length() > 1) { // needing merge
                
                Utility.safeToast(activity, binding.getType() + "账号合并成功", Toast.LENGTH_SHORT);
                activity.finish();
            } else {
                Utility.safeToast(activity, binding.getType() + "账号登录成功", Toast.LENGTH_SHORT);
                activity.finish();
            }
        } catch (Exception e) {
            onError(new HpException(e));
        }
    }

    @Override
    public void onIOException(IOException e) {
        Log.i(TAG, "onIOException: " + e);
        onError(new HpException(e));
    }

    @Override
    public void onError(HpException e) {
        Log.i(TAG, "onError: " + e);
        activity.enableButtons(activity.bindTypes, true);
        Utility.safeToast(activity, binding.getType() + "账号绑定失败, ex=" + e.getMessage(), Toast.LENGTH_SHORT);
        activity.finish();
    }
    
}
