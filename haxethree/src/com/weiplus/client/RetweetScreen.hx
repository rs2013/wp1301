package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.i18n.I18n;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class RetweetScreen extends MakerScreen {

    public function new() {
        super();
        hasTitleBar = false;
        hasBack = false;
    }

    override public function onNewRequest(data: Dynamic) {
        this.image = data.image;
        this.data = data.data;
        this.status = data.status;
        UiUtil.delay(function() {
            onNextStep();
        });
    }

    override public function onScreenResult(requestCode: Int, resultCode: Int, resultData: Dynamic) {
        UiUtil.delay(function() {
            finish(RoxScreen.CANCELED);
        });
    }

}
