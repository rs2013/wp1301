package com.weiplus.client;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;

public class MainActivity extends Activity {
    static Activity instance;
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        instance = this;
        setContentView(R.layout.dummy_main_layout);
        Button btnBack = (Button) findViewById(R.id.btnBack);
        btnBack.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                HaxeHelper.finishHaxeActivity(RESULT_CANCELED, null);
            }
        });
        Button btnPicture = (Button) findViewById(R.id.btnPicture);
        btnPicture.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                String filename = "/data/media/lockscreen/lockscreen_00" + new java.util.Random().nextInt(8) + ".jpg";
                HaxeHelper.finishHaxeActivity(RESULT_OK, filename);
            }
        });
        Button btnMagic = (Button) findViewById(R.id.btnMagic);
        btnMagic.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                String filename = "/data/media/lockscreen/lockscreen_00" + new java.util.Random().nextInt(8) + ".jpg";
                HaxeHelper.finishHaxeActivity(RESULT_OK, filename);
            }
        });
        Button btnPlay = (Button) findViewById(R.id.btnPlay);
        btnPlay.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                HaxeHelper.finishHaxeActivity(RESULT_OK, null);
            }
        });
        Intent it = getIntent();
        String haxeAppId = it.getStringExtra("appId");
        String param = it.getStringExtra("param");
        if (haxeAppId != null) {
            TextView txtMessage = (TextView) findViewById(R.id.txtMessage);
            txtMessage.setText(haxeAppId + " : " + param);
        }
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        HaxeHelper.onActivityResult(requestCode, resultCode, data);
    }
    
    public static Activity getInstance() {
        return instance;
    }
    
}