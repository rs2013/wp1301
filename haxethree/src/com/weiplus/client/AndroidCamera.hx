package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.ui.UiUtil;
import com.weiplus.client.BaseScreen;

import flash.display.Sprite;
import flash.events.Event;

import haxe.Json;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.i18n.I18n;

class AndroidCamera extends BaseScreen {

    private var drawingData: String;

    public function new() {
        super();
        this.hasTitleBar = false;
    }

    override public function createContent(height: Float) : Sprite {
        this.addEventListener(Event.ACTIVATE, onActive);
        content = super.createContent(height);
#if android
        MyUtils.showWaiting("启动相机中".i18n());
#elseif windows
        var testData = {
            bg: { path: "bg.jpg" },
            ars: [
                { path: "ar.jpg", compact: true, description: "url:http://baidu.com", matrix: [ 0.5, 0, 10, 0, 0.5, 10 ] }
            ]
        };
        drawingData = Json.stringify(testData);

        var btn = UiUtil.button(null, null, "next", 0, 32, "res/btn_common.9.png", function(_) {
            var json = Json.parse(drawingData);
            if (json.bg == null) {
                json.bg = { path: "bg.jpg" };
                drawingData = Json.stringify(json);
            }
            startScreen(Type.getClassName(MagicEditor), null, drawingData);
        });
        content.addChild(btn.rox_move(100, 100));
#end
        return content;
    }

    override public function onNewRequest(data: Dynamic) {
#if android
        HaxeStub.startHarryCamera(112, null);
#end
    }

    override public function onScreenResult(requestCode: Int, resultCode: Int, resultData: Dynamic) {
        drawingData = resultData;
        trace("onScreenResult, drawingData=" + drawingData);
#if android
        HaxeStub.startHarryCamera(112, drawingData);
#end
    }

    private function onActive(_) {
#if android
        MyUtils.hideWaiting();
        var s = HaxeStub.getResult(112);
        var json: Dynamic = haxe.Json.parse(s);
        trace(">>HarryCamera active, result=" + s + ",parsed=" + json);
        if (json.resultCode != "ok") { // canceled
            finish(RoxScreen.CANCELED);
            return;
        }
        var drawingData: String = json.drawingData;

        startScreen(Type.getClassName(MagicEditor), null, RoxAnimate.NO_ANIMATE, drawingData);
#end
    }

}
