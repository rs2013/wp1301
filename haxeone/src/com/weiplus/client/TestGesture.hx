package com.weiplus.client;

import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.UiUtil;
import nme.display.BlendMode;
import com.roxstudio.haxe.game.GameUtil;
import nme.display.BlendMode;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxScreenManager;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.geom.Point;
import com.eclecticdesignstudio.motion.easing.Elastic;
import com.eclecticdesignstudio.motion.Actuate;
import nme.geom.Matrix;
import nme.display.DisplayObject;
import nme.display.Bitmap;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class TestGesture extends BaseScreen {

    override public function createContent(height: Float) : Sprite {
        var sp = new Sprite();

        var big = new Sprite();

        var bmp = new Bitmap(ResKeeper.getAssetImage("res/data/8.jpg"));
        bmp.smoothing = true;
        bmp.x = -bmp.width / 2;
        bmp.y = -bmp.height / 2;
        big.addChild(bmp);
//        big.graphics.rox_fillRect(0xFFFFFFFF, -screenWidth / 2, -screenHeight / 2, screenWidth, screenHeight);
        big.name = "big";
        big.x = screenWidth / 2;
        big.y = screenHeight / 2;
        var agent = new RoxGestureAgent(big, RoxGestureAgent.GESTURE);
//        big.addEventListener(RoxGestureEvent.TOUCH_BEGIN, onTouch);
        big.addEventListener(RoxGestureEvent.GESTURE_TAP, function(e) { trace(e); });
        big.rotation = 15;
        big.addEventListener(RoxGestureEvent.GESTURE_PAN, agent.getHandler(RoxGestureAgent.PAN_XY));
        big.addEventListener(RoxGestureEvent.GESTURE_SWIPE, agent.getHandler());
        big.addEventListener(RoxGestureEvent.GESTURE_PINCH, agent.getHandler());
        big.addEventListener(RoxGestureEvent.GESTURE_ROTATION, agent.getHandler());
//        big.blendMode = BlendMode.OVERLAY;
        sp.addChild(big);
        //big.scaleX = big.scaleY = 1.5;

        var small = new Sprite();
        small.name = "small";
        var bmp = new Bitmap(ResKeeper.getAssetImage("res/data/14.jpg"));
        bmp.smoothing = true;
        bmp.x = -bmp.width / 2;
        bmp.y = -bmp.height / 2;
        small.addChild(bmp);
        small.x = 0;
        small.y = 0;
        agent = new RoxGestureAgent(small, RoxGestureAgent.GESTURE_CAPTURE);
        small.addEventListener(RoxGestureEvent.GESTURE_TAP, onTouch);
        small.addEventListener(RoxGestureEvent.GESTURE_PAN, agent.getHandler(RoxGestureAgent.PAN_X));
        small.addEventListener(RoxGestureEvent.GESTURE_PINCH, agent.getHandler());
        small.addEventListener(RoxGestureEvent.GESTURE_LONG_PRESS, onTouch);
        big.addChild(small);

        return sp;
    }

    private function onClick(e) {
        finish(RoxScreen.OK);
    }

    private function onTouch(e: RoxGestureEvent) {
        var sp = cast(e.target, DisplayObject);
        switch (e.type) {
            case RoxGestureEvent.GESTURE_TAP:
                trace(">>tap: e=" + e);
                var oldscale = sp.scaleX;
                Actuate.tween(sp, 0.05, { scaleX: oldscale * 1.3, scaleY: oldscale * 1.3});
                Actuate.tween(sp, 0.35, { scaleX: oldscale, scaleY: oldscale }, false).ease(Elastic.easeOut).delay(0.05);
            case RoxGestureEvent.GESTURE_LONG_PRESS:
                var oldscale = sp.scaleX;
                Actuate.tween(sp, 0.05, { scaleX: oldscale * 1.3, scaleY: oldscale * 1.3});
                Actuate.tween(sp, 0.25, { scaleX: oldscale, scaleY: oldscale }, false).ease(Elastic.easeOut).delay(0.05);
                Actuate.tween(sp, 0.05, { scaleX: oldscale * 1.3, scaleY: oldscale * 1.3}, false).delay(0.3);
                Actuate.tween(sp, 0.25, { scaleX: oldscale, scaleY: oldscale }, false).ease(Elastic.easeOut).delay(0.35);
        }
    }

}
