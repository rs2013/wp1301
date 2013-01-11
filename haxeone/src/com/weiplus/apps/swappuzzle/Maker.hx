package com.weiplus.apps.swappuzzle;

import nme.display.Sprite;
import com.roxstudio.haxe.ui.RoxScreen;

using com.roxstudio.haxe.ui.UiUtil;

class Maker extends RoxScreen {

    override public function onCreate() {
        var btnJigsaw = new Sprite().rox_button("res/btnWrite.png", "btnJigsaw", onClick).rox_move(100, 400);
        addChild(btnJigsaw);
    }

    private function onClick(e: Dynamic) {
        switch (e.target.name) {
            case "btnJigsaw":
                finish(RoxScreen.OK);

        }
    }

}
