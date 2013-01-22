package com.weiplus.client;

import nme.display.Bitmap;
import com.roxstudio.haxe.game.ResKeeper;

using com.roxstudio.haxe.ui.UiUtil;

class TestPlayScreen extends PlayScreen {

    override public function onStart(saved: Dynamic) {
        trace("onstart: saved = " + saved);
        var img = ResKeeper.get("data/14.jpg");
        var bmp = new Bitmap(img);
        content.addChild(bmp.rox_move(100, 100));
    }

    override public function onSave() : Dynamic {
        var saved: Dynamic = {};
        saved.descr = "This is a test";
        saved.number = 12345;
        trace("onsave: saved = " + saved);
        return saved;
    }
}
