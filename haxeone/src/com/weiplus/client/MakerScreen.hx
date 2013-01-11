package com.weiplus.client;

import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.UiUtil;
class MakerScreen extends BaseScreen {

    override public function onCreate() {
        super.onCreate();
        addTitleButton(UiUtil.button(UiUtil.TOP_LEFT, null, "下一步", 0, 36, "res/btn_common.9.png", onNext), UiUtil.RIGHT);
    }

    public function onNextStep() {
        // should be overrided by sub-classes
    }

    private inline function onNext(e: Dynamic) {
        onNextStep();
    }

}
