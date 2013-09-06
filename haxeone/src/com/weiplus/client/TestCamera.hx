package com.weiplus.client;

import motion.easing.Linear;
import flash.Lib;
import motion.Actuate;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.game.GfxUtil;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Sprite;
import com.roxstudio.haxe.ui.RoxScreen;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class TestCamera extends RoxScreen {

    public function new() {
        super();
    }

    override public function onCreate() {
        super.onCreate();
        var root = new Sprite();
        root.graphics.rox_fillRect(0x01009900, 0, 0, screenWidth, screenHeight);
        addChild(root);
        var sp = new Sprite();
//        flash.Lib.current.stage.opaqueBackground = 0x00005500;
//        flash.Lib.current.stage.
        sp.graphics.rox_fillRect(0x880000FF, 100, 100, 300, 300);
        Actuate.tween(sp, 5, { y: 500 }).ease(motion.easing.Linear.easeNone).repeat().reflect();
        root.addChild(sp);
    }

}
