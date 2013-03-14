package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxScreen;
import com.weiplus.client.model.AppData;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxFlowPane;
import nme.display.Shape;
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Matrix;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class HarryCamera extends MakerScreen {

    override public function createContent(height: Float) : Sprite {
        content = super.createContent(height);
        this.addEventListener(Event.ACTIVATE, onActive);
#if android
        HaxeStub.startHarryCamera(112);
#end
        return content;
    }

//    override public function onShown() {
//        if (image != null) finish(RoxScreen.CANCELED);
//    }

    private function onActive(_) {
#if android
        var s = HaxeStub.getResult(112);
        var json: Dynamic = haxe.Json.parse(s);
        trace(">>HarryCamera active, result=" + s + ",parsed=" + json);
        if (untyped json.resultCode != "ok") return;
        var path = untyped json.intentDataPath;
        image = ResKeeper.loadLocalImage(path);
        var appdata: AppData = status.appData;
        appdata.width = image.width;
        appdata.height = image.height;
        appdata.type = "image";
        onNextStep();
#end
    }

}
