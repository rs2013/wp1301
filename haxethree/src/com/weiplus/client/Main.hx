package com.weiplus.client;

//import com.weiplus.client.TestMakerScreen;
import com.roxstudio.haxe.game.GameUtil;
import sys.io.File;
import com.roxstudio.haxe.game.ResKeeper;
import sys.FileSystem;
import com.roxstudio.haxe.ui.SxAdapter;
import com.roxstudio.haxe.ui.DipUtil;
import flash.system.Capabilities;
import com.roxstudio.i18n.I18n;
import ru.stablex.ui.UIBuilder;
import Lambda;
using com.roxstudio.i18n.I18n;
import nme.events.Event;
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

using com.roxstudio.haxe.ui.DipUtil;

class Main {

    public function new() {
    }

    static public function main() {
//        trace("before init");
        I18n.init();
//        UIBuilder.regClass("com.weiplus.client.HaxeCamera");
        UIBuilder.saveCodeTo("ui_gencode");
        UIBuilder.regClass("com.weiplus.client.Main");
        UIBuilder.regClass("com.weiplus.client.ArBox");
        UIBuilder.regClass("com.weiplus.client.LazyBmp");
        UIBuilder.init("ui/defaults.xml");
        SxAdapter.setupAssets();
        DipUtil.init(640);
        var loc = Capabilities.language;
        trace("lang=" + loc);
        if (StringTools.startsWith(loc, "zh")) {
            loc = "default";
        } else if (!Lambda.has(I18n.getSupportedLocales(), loc)) {
            loc = "en";
        }
        I18n.setCurrentLocale(loc);
        MyUtils.LOCALE = loc;
        RoxApp.init();
//        trace("init ok");
        var m = new RoxScreenManager();
//        m.startScreen(Type.getClassName(com.weiplus.client.HomeScreen));
//        m.startScreen(Type.getClassName(CameraScreen));
//        m.startScreen(Type.getClassName(TestGesture));
//        m.startScreen(Type.getClassName(TestScreen));
//        m.startScreen(Type.getClassName(TestMakerScreen));
//        m.startScreen(Type.getClassName(SimpleMaker));
//        m.startScreen(Type.getClassName(SelectedScreen));
//        m.startRootScreen(Type.getClassName(SettingScreen));
//        m.startRootScreen(Type.getClassName(TestCurve));
//        m.startRootScreen(Type.getClassName(com.roxstudio.haxe.hxquery.Test));
        m.startRootScreen(Type.getClassName(Splash));
//        m.startRootScreen(Type.getClassName(MagicEditor), null);

//        trace("screen started");
//        var st = new Status();
//        var data = st.appData = new AppData();
//        data.type = "test";
//        data.id = "1111";
//        data.url = "http://rox.local/res/data/data.zip";
//        data.url = "assets://res/data/data.zip";
//        m.startScreen(Type.getClassName(TestPlayScreen), st);
        RoxApp.stage.addChild(m);
//        RoxApp.stage.addEventListener(Event.ADDED_TO_STAGE, function(e: Dynamic) {
//            trace(">>>>(" + e.target + ",name=" + e.target.name + ") added to stage.");
//        });
//        RoxApp.stage.addEventListener(Event.ADDED, function(e: Dynamic) {
//            trace("----(" + e.target + ",name=" + e.target.name + ") added.");
//        });

//        var fps = new FPS();
//        fps.x = 400;
//        fps.y = 10;
//        fps.mouseEnabled = false;
//        RoxApp.stage.addChild(fps);
        flash.Lib.current.stage.opaqueBackground = 0xFF000000;
//        png2jpg();
    }

    private static function png2jpg() {
        var all = FileSystem.readDirectory("using");
        for (f in all) {
            var bmd = ResKeeper.loadLocalImage("using/" + f);
            bmd = MyUtils.pngToJpg(bmd);
            File.saveBytes("optimized/" + f, GameUtil.encodeJpeg(bmd));
        }
    }

    public static inline function getFont() : String {
#if android
        return "/system/fonts/DroidSansFallback.ttf";
#else
        return "Microsoft YaHei";
#end
    }

//    public static inline function fontName() {
//        return #if android '/system/fonts/DroidSansFallback.ttf' #else 'Microsoft YaHei' #end;
//    }
//
}
