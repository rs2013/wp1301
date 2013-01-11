package com.weiplus.client;

import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.display.Sprite;
import nme.geom.Rectangle;

using com.roxstudio.haxe.ui.UiUtil;

class PostitScreen extends BaseScreen {

    override public function onCreate() {
        super.onCreate();
        var btnBack = new Sprite().rox_button("res/btnBack.png", "btnBack", onButton);
        addTitleButton(btnBack, 12, 12);
    }

    override public function createContent(designHeight: Float) : Sprite {
        var content = new Postit(null);
        var agent = new RoxGestureAgent(content, RoxGestureAgent.GESTURE);
        content.addEventListener(RoxGestureEvent.GESTURE_PAN, agent.getHandler(RoxGestureAgent.PAN_Y));
        content.addEventListener(RoxGestureEvent.GESTURE_SWIPE, agent.getHandler(RoxGestureAgent.PAN_Y));
        return content;
    }

    override public function onNewRequest(data: Dynamic) {
        trace("PostitScreen.onNewRequest:" + data);
        var content: Postit = cast(content);
        content.status = cast(data);
        content.update(screenWidth, true);
    }

    private function onButton(e) {
        finish(RoxScreen.OK);
    }
}
