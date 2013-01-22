package com.weiplus.client;

import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.RoxPreloader;
import com.roxstudio.haxe.ui.RoxScreen;
import com.weiplus.client.model.Status;
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Matrix;
import nme.geom.Rectangle;
import nme.net.SharedObject;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class PlayScreen extends BaseScreen {

    public var viewWidth: Float;
    public var viewHeight: Float;

#if android
    private static inline var CACHE_DIR = "/sdcard/.harryphoto/savedgames/";
#elseif windows
    private static inline var CACHE_DIR = "D:/tmp/.harryphoto/savedgames/";
#end

    private static inline var SAVED_DATA_NAME = "harryphoto.savedData";

    private static inline var DESIGN_WIDTH = 640;
    private static inline var TOP_HEIGHT = 86;
    private static inline var BTN_SPACING = 12;
    private static var globalSo: SharedObject;

    private var status: Status;

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
        contentBg(screenWidth, viewHeight);
        addChild(content);
        addChild(titleBar);
        var btnBack = UiUtil.button(UiUtil.TOP_LEFT, null, "返回", 0xFFFFFF, 36, "res/btn_dark.9.png", function(_) { finish(RoxScreen.OK); } );
        addTitleButton(btnBack, UiUtil.LEFT);

        addEventListener(Event.DEACTIVATE, onDeactive);

    }

    override public function onNewRequest(data: Dynamic) {
        this.status = cast(data);
        var appData = status.appData;
        var appId = appData.type + "_" + appData.id;
        if (checkCache(appId)) {
            loadFromCache(appId);
        } else { // load remotely
            loadUrl(appData.url);
            saveToCache(appId);
        }
        var mask = new Sprite();
        mask.graphics.rox_fillRect(0x77000000, 0, 0, viewWidth, viewHeight);
        var loading = UiUtil.staticText("载入中...", 0xFFFFFF, 36);
        loading.rox_move((viewWidth - loading.width) / 2, (viewHeight - loading.height) / 2);
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

/******************************** to be overrided *******************************/

    public function onStart(saved: Dynamic) {
    }

    public function onSave() : Dynamic {
        return null;
    }

    public function onPause() {}

    public function onResume() {}

/******************************** private methods ******************************/

    private function onDeactive(_) {
        var saved = onSave();
        if (saved == null) saved = {};
        Reflect.setField(saved, "lastUsage", Std.int(Date.now().getTime() / 1000.0));
        var appData = status.appData;
        var appId = appData.type + "_" + appData.id;
        Reflect.setField(globalSo.data, appId, saved);
        globalSo.flush();
    }

    private function loadUrl(url: String) {
        var preloader = new RoxPreloader([ url ], [ "data" ], true);
        preloader.addEventListener(Event.COMPLETE, function(_) {
            content.removeChildAt(content.numChildren - 1); // remove mask
            onStart(getSavedData());
        } );
    }

    private inline function checkCache(dirName: String) : Bool {
#if (flash || html5)
        return false;
#else
        var filedir = CACHE_DIR + dirName;
        return sys.FileSystem.exists(filedir);
#end
    }

    private function loadFromCache(dirName: String) {
#if cpp

#end
    }

    private function saveToCache(dirName: String) {
#if cpp

#end
    }

    private function getSavedData() : Dynamic {
        if (globalSo == null) {
            globalSo = SharedObject.getLocal(SAVED_DATA_NAME);
        }
        var appId = status.appData.type + "_" + status.appData.id;
        return Reflect.field(globalSo.data, appId);
    }

}
