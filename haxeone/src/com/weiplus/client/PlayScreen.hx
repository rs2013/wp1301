package com.weiplus.client;

import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.io.Unzipper;
import com.roxstudio.haxe.game.Preloader;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.RoxScreen;
import com.weiplus.client.model.Status;
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Matrix;
import nme.geom.Rectangle;
import nme.net.SharedObject;
#if cpp
import nme.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;
#end

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.io.IOUtil;
using com.roxstudio.haxe.ui.UiUtil;

class PlayScreen extends BaseScreen {

    public static inline var ZIPDATA_NAME = "playscreen_zipdata";
    public var viewWidth: Float;
    public var viewHeight: Float;

#if android
    private static inline var CACHE_DIR = "/sdcard/.harryphoto/savedgames";
#elseif windows
    private static inline var CACHE_DIR = "savedgames";
//    private static inline var CACHE_DIR = "D:/tmp/savedgames";
#end

    private static inline var SAVED_DATA_NAME = "harryphoto.savedData";
    private static inline var CACHE_EXPIRE = 2592000; // one month = 3600 * 24 * 30

    private static inline var DESIGN_WIDTH = 640;
    private static inline var TOP_HEIGHT = 86;
    private static inline var BTN_SPACING = 12;
    private static var globalSo: SharedObject;

    public var status: Status;

    override public function onCreate() {
        designWidth = DESIGN_WIDTH;
        d2rScale = screenWidth / designWidth;
        designHeight = screenHeight / d2rScale;
        titleBar = UiUtil.bitmap("res/bg_play_top.png");
        titleBtnOffsetL = BTN_SPACING;
        titleBtnOffsetR = titleBar.width - BTN_SPACING;
        if (title != null) {
            titleBar.addChild(title.rox_anchor(UiUtil.CENTER).rox_move(titleBar.width / 2, titleBar.height / 2));
        }
        titleBar.rox_scale(d2rScale);
        viewWidth = screenWidth;
        viewHeight = (designHeight - TOP_HEIGHT) * d2rScale;
        content = createContent(viewHeight);
        content.rox_move(0, TOP_HEIGHT * d2rScale);
        contentBg(viewWidth, viewHeight);
        addChild(content);
        addChild(titleBar);
        var btnBack = UiUtil.button(UiUtil.TOP_LEFT, null, "返回", 0xFFFFFF, 36, "res/btn_dark.9.png", function(_) { finish(RoxScreen.OK); } );
        addTitleButton(btnBack, UiUtil.LEFT);

        addEventListener(Event.DEACTIVATE, onDeactive);

    }

    override public function onNewRequest(data: Dynamic) {
        this.status = cast(data);
        trace("playscreen: status=" + status);
        if (status.makerData != null) { // from maker
            onStart(null);
            return;
        }
        var appData = status.appData;
        var appId = appData.type + "_" + appData.id;
        if (checkCache(appId)) {
            loadFromCache(appId);
        } else { // load remotely
            loadUrl(appData.url);
        }
        var mask = new Sprite();
        mask.graphics.rox_fillRect(0x77000000, 0, 0, viewWidth, viewHeight);
        var loading = MyUtils.getLoadingAnim("载入中");
        loading.rox_move(viewWidth / 2, viewHeight / 2);
        mask.addChild(loading);
        content.addChild(mask);
    }

    override public function onShown() {
        onResume();
    }

    override public function onHidden() {
        onPause();
        onDeactive(null);
    }

    public function contentBg(w: Float, h: Float) {
        var bmd = ResKeeper.getAssetImage("res/bg_play.jpg");
        var scalex = w / bmd.width, scaley = h / bmd.height;
        content.graphics.rox_drawImage(bmd, new Matrix(scalex, 0, 0, scaley, 0, 0), false, true, 0, 0, w, h);
    }

    public inline function getFileData(filename: String) {
        return ResKeeper.get(ZIPDATA_NAME + "/" + filename);
    }

/******************************** to be overrided *******************************/

    public function onStart(saved: Dynamic) {}

    public function onSave(saved: Dynamic) {}

    public function onPause() {}

    public function onResume() {}

/******************************** private methods ******************************/

    private function onDeactive(_) {
        if (status.makerData != null) return;
        var saved = {};
        onSave(saved);
        Reflect.setField(saved, "lastUsage", Std.int(Date.now().getTime() / 1000.0));
        saveAndScan(saved);
    }

    private function loadUrl(url: String) {
#if (flash || html5)
        var preloader = new Preloader([ url ], [ ZIPDATA_NAME ], true);
#else
        var preloader = new Preloader([ url ], [ ZIPDATA_NAME ], "playscreen_temp_bundle", false);
#end
        preloader.addEventListener(Event.COMPLETE, function(_) {
#if !(flash || html5)
            var zipdata = cast(ResKeeper.get(ZIPDATA_NAME), ByteArray);
            var files = Unzipper.decompress(zipdata, ZIPDATA_NAME + "/");
            for (id in files.keys()) ResKeeper.add(id, files.get(id));
            var dir = CACHE_DIR + "/" + status.appData.type + "_" + status.appData.id;
//            trace("dir="+dir+",exists="+FileSystem.exists(dir));
            if (!FileSystem.exists(dir)) FileUtil.mkdirs(dir);
            var filepath = dir + "/" + ZIPDATA_NAME + ".zip";
            File.saveBytes(filepath, zipdata.rox_toBytes());
            ResKeeper.disposeBundle("playscreen_temp_bundle");
#end
            content.removeChildAt(content.numChildren - 1); // remove mask
            onStart(getSavedData());
        } );
    }

    private inline function checkCache(dirName: String) : Bool {
#if (flash || html5)
        return false;
#else
        var filedir = CACHE_DIR + "/" + dirName;
        return FileSystem.exists(filedir);
#end
    }

    private function loadFromCache(dirName: String) {
#if cpp
        var fileurl = FileUtil.fileUrl(CACHE_DIR + "/" + dirName + "/" + ZIPDATA_NAME + ".zip");
        var preloader = new Preloader([ fileurl ], [ ZIPDATA_NAME ], true);
        preloader.addEventListener(Event.COMPLETE, function(_) {
            content.removeChildAt(content.numChildren - 1); // remove mask
            onStart(getSavedData());
        } );
#end
    }

    private function removeCache(dirName: String) {
#if cpp
        var filedir = CACHE_DIR + "/" + dirName;
        if (FileSystem.exists(filedir)) FileUtil.rmdir(filedir, true);
#end
    }

    private function getSavedData() : Dynamic {
        if (globalSo == null) {
            globalSo = SharedObject.getLocal(SAVED_DATA_NAME);
        }
        var appId = status.appData.type + "_" + status.appData.id;
        return Reflect.field(globalSo.data, appId);
    }

    private function saveAndScan(saved: Dynamic) {
//        trace(">>saveAndScan: saved="+saved);
        var appId = status.appData.type + "_" + status.appData.id;
        var data = globalSo.data;
        Reflect.setField(data, appId, saved);
        var now = Date.now().getTime() / 1000;
        for (id in Reflect.fields(data)) {
            var val = Reflect.field(data, id);
            if (!Reflect.hasField(val, "lastUsage")) continue;
            var lastUsage: Float = Reflect.field(val, "lastUsage");
            if (now - lastUsage <= CACHE_EXPIRE) continue; // not expired
            removeCache(id);
            Reflect.deleteField(data, id);
        }
        globalSo.flush();
//        trace(">>>flush ok, globalSo.data="+globalSo.data);
    }

}
