package com.weiplus.client;

import com.weiplus.client.model.AppData;
import com.weiplus.client.model.Status;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxScreenManager;
import nme.display.FPS;
import nme.Lib;

#if cpp
//import com.weiplus.client.ImageChooser;
#end
//import com.weiplus.client.ImageEditor;
//import com.weiplus.client.HomeScreen;
//import com.weiplus.client.RichEditor;
//import com.weiplus.client.TestGesture;
//import com.weiplus.client.Postit;
//import com.weiplus.client.PostitScreen;

//import com.roxstudio.haxe.net.RoxURLLoader;

class Main {

    public function new() {
    }

    static public function main() {
        RoxApp.init();
        var m = new RoxScreenManager();
//        m.startScreen(Type.getClassName(com.weiplus.client.HomeScreen));
//        m.startScreen(Type.getClassName(CameraScreen));
//        m.startScreen(Type.getClassName(TestGesture));
//        m.startScreen(Type.getClassName(TestScreen));

        var st = new Status();
        var data = st.appData = new AppData();
        data.type = "test";
        data.id = "1111";
        data.url = "http://rox.local/res/data/data.zip";
        m.startScreen(Type.getClassName(TestPlayScreen), st);
        RoxApp.stage.addChild(m);

        var fps = new FPS();
        fps.x = 400;
        fps.y = 10;
        fps.mouseEnabled = false;
        RoxApp.stage.addChild(fps);
    }

}
