package com.weiplus.client;

import nme.geom.Rectangle;
import com.roxstudio.haxe.game.ResKeeper;

using com.roxstudio.haxe.game.GfxUtil;

class LoginScreen extends BaseScreen {

    override public function onCreate() {
        hasTitleBar = false;
        hasBack = false;
        super.onCreate();
    }

    override public function drawBackground(w: Float, h: Float) {
        var bg = ResKeeper.getAssetImage("res/bg_splash.jpg");
        var r = new Rectangle(0, bg.height - h / d2rScale, bg.width, h / d2rScale);
        graphics.rox_drawRegion(bg, r, 0, 0);
    }

}
