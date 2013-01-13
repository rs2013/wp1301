package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxPreloader;
import com.weiplus.client.model.Status;
import nme.events.Event;
import nme.geom.Matrix;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.geom.Rectangle;
import nme.display.Sprite;

using com.roxstudio.haxe.ui.UiUtil;

class PlayScreen extends BaseScreen {

#if android
    public static inline var CACHE_DIR = "/sdcard/.harryphoto/savedgames/";
#elseif windows
    public static inline var CACHE_DIR = "D:/tmp/.harryphoto/savedgames/";
#end

    private static inline var DESIGN_WIDTH = 640;
    private static inline var TOP_HEIGHT = 86;
    private static inline var BTN_SPACING = 12;

    private var preloader: RoxPreloader;

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
        var viewh = (designHeight - TOP_HEIGHT) * d2rScale;
        content = createContent(viewh);
        content.rox_move(0, TOP_HEIGHT * d2rScale);
        contentBg(screenWidth, viewh);
        addChild(content);
        addChild(titleBar);
        var btnBack = UiUtil.button(UiUtil.TOP_LEFT, null, "返回", 0xFFFFFF, 36, "res/btn_dark.9.png", function(_) { finish(RoxScreen.OK); } );
        addTitleButton(btnBack, UiUtil.LEFT);

        addEventListener(Event.DEACTIVATE, onDeactive);
    }

    override public function onNewRequest(data: Dynamic) {
        var st: Status = cast(data);
        var appdata = st.appData;
        var dir = appdata.type + "_" + appdata.id;
        if (checkCache(dir)) {
            loadFromCache(dir);
        } else { // load remotely
            loadUrl(appdata.url);
            saveToCache(dir);
        }
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
        content.graphics.beginBitmapFill(bmd, new Matrix(scalex, 0, 0, scaley, 0, 0), false, false);
        content.graphics.drawRect(0, 0, w, h);
        content.graphics.endFill();
    }

/******************************** to be overrided *******************************/

    public function onStart(data: Dynamic) {}

    public function onSave(saved: Dynamic) {}

    public function onPause() {}

    public function onResume() {}

/******************************** private methods ******************************/

    private function onDeactive(_) {
        var saved: Dynamic = { };
        onSave(saved);
        saved.lastUsage = Std.int(Date.now().getTime() / 1000.0);
    }

    private function loadUrl(url: String) {
        preloader = new RoxPreloader([ url ], true);
    }

    private inline function checkCache(dirName: String) : Bool {
#if (flash || html5)
        return false;
#else
        var filedir = CACHE_DIR + dirName;
        return false;
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

}
