package com.weiplus.client;

import com.weibo.sdk.android.Oauth2AccessToken;
import com.weibo.sdk.android.Weibo;
import com.weibo.sdk.android.WeiboAuthListener;
import com.weibo.sdk.android.WeiboDialogError;
import com.weibo.sdk.android.WeiboException;
import com.weibo.sdk.android.sso.SsoHandler;
import com.weibo.sdk.android.util.Utility;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Toast;

public class LoginActivity extends Activity {

    private Weibo mWeibo;
    private static final String CONSUMER_KEY = "2392272878";
    private static final String REDIRECT_URL = "http://hi.baidu.com/new/rockswang";
    private Intent it = null;
    private Button btnWeibo, btnQQ, btnRenren;
    public static Oauth2AccessToken accessToken;
    public static final String TAG = "mydemo";
    /**
     * SsoHandler 仅当sdk支持sso时有效，
     */
    SsoHandler mSsoHandler;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.login_layout);
        mWeibo = Weibo.getInstance(CONSUMER_KEY, REDIRECT_URL);

        btnWeibo = (Button) findViewById(R.id.btnWeibo);
        try {
            Class sso = Class.forName("com.weibo.sdk.android.sso.SsoHandler");
        } catch (ClassNotFoundException e) {
            // e.printStackTrace();
            Log.i(TAG, "com.weibo.sdk.android.sso.SsoHandler not found");

        }
        btnWeibo.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                /**
                 * 下面两个注释掉的代码，仅当sdk支持sso时有效，
                 */

                mSsoHandler = new SsoHandler(LoginActivity.this, mWeibo);
                mSsoHandler.authorize(new AuthDialogListener());
            }
        });
        btnQQ = (Button) findViewById(R.id.btnQq);
        btnRenren = (Button) findViewById(R.id.btnRenren);
    }

    class AuthDialogListener implements WeiboAuthListener {

        @Override
        public void onComplete(Bundle values) {
            String token = values.getString("access_token");
            String expires_in = values.getString("expires_in");
            LoginActivity.accessToken = new Oauth2AccessToken(token, expires_in);
            if (LoginActivity.accessToken.isSessionValid()) {
                AccessTokenKeeper.keepAccessToken(LoginActivity.this,
                        accessToken);
                Toast.makeText(LoginActivity.this, "认证成功", Toast.LENGTH_SHORT)
                        .show();
            }
            LoginActivity.this.finish();
        }

        @Override
        public void onError(WeiboDialogError e) {
            Toast.makeText(getApplicationContext(),
                    "Auth error : " + e.getMessage(), Toast.LENGTH_LONG).show();
        }

        @Override
        public void onCancel() {
            Toast.makeText(getApplicationContext(), "Auth cancel",
                    Toast.LENGTH_LONG).show();
        }

        @Override
        public void onWeiboException(WeiboException e) {
            Toast.makeText(getApplicationContext(),
                    "Auth exception : " + e.getMessage(), Toast.LENGTH_LONG)
                    .show();
        }

    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        /**
         * 下面两个注释掉的代码，仅当sdk支持sso时有效，
         */
        if (mSsoHandler != null) {
            mSsoHandler.authorizeCallBack(requestCode, resultCode, data);
        }
    }
}
