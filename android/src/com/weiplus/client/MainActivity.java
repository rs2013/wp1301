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
//  @Override
//  public void onCreate(Bundle savedInstanceState) {
//      super.onCreate(savedInstanceState);
//      instance = this;
//      setContentView(R.layout.dummy_main_layout);
//      Button btnBack = (Button) findViewById(R.id.btnBack);
//      btnBack.setOnClickListener(new OnClickListener() {
//          @Override
//          public void onClick(View v) {
//              HaxeStub.finishHaxeActivity(RESULT_CANCELED, null);
//          }
//      });
//      Button btnPicture = (Button) findViewById(R.id.btnPicture);
//      btnPicture.setOnClickListener(new OnClickListener() {
//          @Override
//          public void onClick(View v) {
//              String filename = "/data/media/lockscreen/lockscreen_00" + new java.util.Random().nextInt(8) + ".jpg";
//              HaxeStub.finishHaxeActivity(RESULT_OK, filename);
//          }
//      });
//      Button btnMagic = (Button) findViewById(R.id.btnMagic);
//      btnMagic.setOnClickListener(new OnClickListener() {
//          @Override
//          public void onClick(View v) {
//              String filename = "/data/media/lockscreen/lockscreen_00" + new java.util.Random().nextInt(8) + ".jpg";
//              HaxeStub.finishHaxeActivity(RESULT_OK, filename);
//          }
//      });
//      Button btnPlay = (Button) findViewById(R.id.btnPlay);
//      btnPlay.setOnClickListener(new OnClickListener() {
//          @Override
//          public void onClick(View v) {
//              HaxeStub.finishHaxeActivity(RESULT_OK, null);
//          }
//      });
//      Intent it = getIntent();
//      String haxeAppId = it.getStringExtra("appId");
//      String param = it.getStringExtra("param");
//      if (haxeAppId != null) {
//          TextView txtMessage = (TextView) findViewById(R.id.txtMessage);
//          txtMessage.setText(haxeAppId + " : " + param);
//      }
//  }
//  
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        instance = this;
        setContentView(R.layout.dummy_main_layout);
        Button btnFirst = (Button) findViewById(R.id.btnLogin);
        btnFirst.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
//                String filename = "/data/media/lockscreen/lockscreen_00"
//                        + new java.util.Random().nextInt(8) + ".jpg";
//                HaxeStub.startImageCapture(1, null);
                HpManager.login();
            }
        });
        Button btnSecond = (Button) findViewById(R.id.btnLogout);
        btnSecond.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                HpManager.logout();
            }
        });
        Button btnPublic = (Button) findViewById(R.id.btnPublicTimeline);
        btnPublic.setOnClickListener(new OnClickListener() {
            @Override public void onClick(View v) {
                HpManager.getPublicTimeline(null);
            }
        });
        Button btnHome = (Button) findViewById(R.id.btnUserTimeline);
        btnHome.setOnClickListener(new OnClickListener() {
            @Override public void onClick(View v) {
                HpManager.getHomeTimeline(null);
            }
        });
        Button btnPost = (Button) findViewById(R.id.btnPost);
        btnPost.setOnClickListener(new OnClickListener() {
            @Override public void onClick(View v) {
                HpManager.postStatus("This a test from rocks " + System.currentTimeMillis(), null, null, null, "", "", null);
            }
        });
        Button btnImage = (Button) findViewById(R.id.btnPostImage);
        btnImage.setOnClickListener(new OnClickListener() {
            @Override public void onClick(View v) {
                HpManager.postStatus("This a test from rocks" + System.currentTimeMillis(), "/sdcard/a.jpg", null, null, "", "", null);
            }
        });
        Button btnFile = (Button) findViewById(R.id.btnPostFile);
        btnFile.setOnClickListener(new OnClickListener() {
            @Override public void onClick(View v) {
                HpManager.postStatus("This a test from rocks" + System.currentTimeMillis(), "/sdcard/a.jpg", "json", "/sdcard/aaaa.json", "", "", null);
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        HaxeStub.onActivityResult(requestCode, resultCode, data);
    }
    
    public static Activity getInstance() {
        return instance;
    }
    
}