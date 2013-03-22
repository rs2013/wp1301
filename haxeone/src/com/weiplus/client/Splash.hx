package com.weiplus.client;

import haxe.Timer;
import nme.geom.Rectangle;
import com.roxstudio.haxe.game.ResKeeper;

using com.roxstudio.haxe.game.GfxUtil;

class Splash extends BaseScreen {

    private var timer: Timer;

    override public function onCreate() {
        hasTitleBar = false;
        hasBack = false;
        super.onCreate();
        timer = new Timer(3000);
        timer.run = doLoad;
    }

    override public function drawBackground(w: Float, h: Float) {
        var bg = ResKeeper.getAssetImage("res/bg_splash.jpg");
        var r = new Rectangle(0, bg.height - h / d2rScale, bg.width, h / d2rScale);
        graphics.rox_drawRegion(bg, r, 0, 0);
        var logo = ResKeeper.getAssetImage("res/icon_logo.png");
        graphics.rox_drawRegion(logo, null, (w - logo.width * 2) / 2, 0.33 * h, logo.width * 2, logo.height * 2);
//        trace("x=" + ((w - logo.width) / 2) + ",y=" + (0.33 * h));
    }

    private function doLoad() {
//        HarryCamera.processImg(ResKeeper.getAssetImage("res/shafa.jpg"));
//        HarryCamera.processImg(ResKeeper.getAssetImage("res/huaping.jpg"));

        startScreen(Type.getClassName(SelectedScreen), true);
        timer.stop();
    }

}
