package com.weiplus.client;

import com.roxstudio.haxe.ui.AutoplaySprite;
import com.eclecticdesignstudio.spritesheet.AnimatedSprite;
import com.eclecticdesignstudio.spritesheet.data.BehaviorData;
import com.eclecticdesignstudio.spritesheet.data.SpritesheetFrame;
import com.eclecticdesignstudio.spritesheet.Spritesheet;
import haxe.Timer;
import nme.geom.Rectangle;
import com.roxstudio.haxe.game.ResKeeper;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class Splash extends BaseScreen {

    private var loginOk = false;

    override public function onCreate() {
        hasTitleBar = false;
        hasBack = false;
        super.onCreate();
        Timer.delay(doLoad, 1000);
#if android
//        HpManager.logout();
        loginOk = HpManager.login();
        trace("loginOk=" + loginOk + ",token=" + HpManager.getTokenAsJson());
#end
    }

    override public function drawBackground() {
        var bg = ResKeeper.getAssetImage("res/bg_splash.jpg");
        var r = new Rectangle(0, bg.height - screenHeight / d2rScale, bg.width, screenHeight / d2rScale);
        graphics.rox_drawRegion(bg, r, 0, 0, screenWidth, screenHeight);
        var logo = ResKeeper.getAssetImage("res/icon_logo_big.png");
        var ratio = logo.width / 640;
        graphics.rox_drawRegion(logo, null, (screenWidth - logo.width * ratio) / 2, 0.15 * screenHeight,
                logo.width * ratio, logo.height * ratio);
//        trace("x=" + ((w - logo.width) / 2) + ",y=" + (0.33 * h));
    }

    private function doLoad() {
//        HarryCamera.processImg(ResKeeper.getAssetImage("res/shafa.jpg"));
//        HarryCamera.processImg(ResKeeper.getAssetImage("res/huaping.jpg"));

        MyUtils.getLoadingAnim("");
#if cpp
        var cacheNames = [
                "com_weiplus_client_PublicScreen.json",
                "com_weiplus_client_SelectedScreen.json",
                "com_weiplus_client_HomeScreen.json",
                "com_weiplus_client_UserScreen.json" ];
        for (n in cacheNames) {
            var s = ResKeeper.loadLocalText(TimelineScreen.CACHE_DIR + "/" + n);
            if (s != null) ResKeeper.add("cache:" + n, s, ResKeeper.DEFAULT_BUNDLE);
        }
#end

        var toScreen = loginOk ? Type.getClassName(HomeScreen) : Type.getClassName(PublicScreen);
        startScreen(toScreen, PARENT);
    }

}
