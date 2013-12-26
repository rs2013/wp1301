package com.weiplus.client;

//import com.weiplus.client.TestMakerScreen;
import com.roxstudio.haxe.game.GameUtil;
#if cpp
import sys.FileSystem;
import sys.io.File;
#end
import com.roxstudio.haxe.game.ResKeeper;
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
        I18n.init();
//        UIBuilder.regClass("com.weiplus.client.HaxeCamera");
//        UIBuilder.saveCodeTo("ui_gencode");
//        UIBuilder.regClass("com.weiplus.client.Main");
//        UIBuilder.regClass("com.weiplus.client.ArBox");
//        UIBuilder.regClass("com.weiplus.client.LazyBmp");
//        UIBuilder.init("ui/defaults.xml");
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
        var m = new RoxScreenManager();
        m.startRootScreen(Type.getClassName(Splash));

        RoxApp.stage.addChild(m);
//        trace("中文");
//        trace(Json.stringify({a: "中文"}));
//        var hanzi: EReg = ~/[\x{4e00}-\x{9fa5}]+/;
//        var t = hanzi.match("123阿中文abc");
//        trace(">>>" + t + ",matched=" + hanzi.matched(0) + ",split=" + (~/[a-z]+/).split("he你llo好 wor世ld界"));


//        var fps = new FPS();
//        fps.x = 400;
//        fps.y = 10;
//        fps.mouseEnabled = false;
//        RoxApp.stage.addChild(fps);
    }

    public static inline function getFont() : String {
#if android
        return "/system/fonts/DroidSansFallback.ttf";
#else
        return "Microsoft YaHei";
#end
    }

}
