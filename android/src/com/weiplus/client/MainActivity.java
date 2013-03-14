package com.weiplus.client;


import com.harryphoto.bind.*;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
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
    boolean checked = false;
    
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
                if (MainActivity.this.checked) {
                    HpManager.login();
//                    HpManager.bind("RENREN_WEIBO");
                } else {
                    HpManager.check();
                    MainActivity.this.checked = true;
                }
            }
        });
        Button btnSecond = (Button) findViewById(R.id.btnLogout);
        btnSecond.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                HpManager.logout();
                new SinaWeibo("").logout();
                new TencentWeibo("", "").logout();
                new RenrenWeibo("").logout();
            }
        });
        Button btnPublic = (Button) findViewById(R.id.btnPublicTimeline);
        btnPublic.setOnClickListener(new OnClickListener() {
            @Override public void onClick(View v) {
                HpManager.getPublicTimeline(1, 20, 0, null);
            }
        });
        Button btnHome = (Button) findViewById(R.id.btnUserTimeline);
        btnHome.setOnClickListener(new OnClickListener() {
            @Override public void onClick(View v) {
                HpManager.getHomeTimeline(1, 20, 0, null);
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
        Button btnCamera = (Button) findViewById(R.id.btnCamera);
        btnCamera.setOnClickListener(new OnClickListener() {
            @Override public void onClick(View v) {
                Intent it = new Intent(MainActivity.this, com.vbo.harry_camera.activity.CameraActivity.class);
                it.setData(Uri.fromParts("catelog", "", ""));
                MainActivity.this.startActivityForResult(it, 33875);
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 33875) {
            if (data != null) {
                Uri uri = data.getData();
                Log.i("MainActivity", "CameraCallback: uri=" + uri);
            }
        } else {
            HaxeStub.onActivityResult(requestCode, resultCode, data);
        }
    }
    
    public static Activity getInstance() {
        return instance;
    }
    
}