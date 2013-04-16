package com.roxstudio.haxe.ui;

import com.eclecticdesignstudio.motion.Actuate;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.events.KeyboardEvent;
import nme.geom.Rectangle;
import nme.Lib;

class RoxScreenManager extends Sprite {

    private var screenPool: Hash<RoxScreen>;
    private var stack: List<StackItem>;

    public function new() {
        super();
        screenPool = new Hash<RoxScreen>();
        stack = new List<StackItem>();
        RoxApp.stage.addEventListener(KeyboardEvent.KEY_UP, function(e: KeyboardEvent) {
            if (e.keyCode == 27 && stack.length > 1) {
                var topscreen: RoxScreen = stack.first().screen;
                if (topscreen.onBackKey()) {
                    finishScreen(topscreen, null, RoxScreen.CANCELED, null, null);
                    e.stopPropagation();
                }
            }
        });
    }

    public inline function findScreen(screenClassName: String) : RoxScreen {
        var screen: RoxScreen = null;
        for (si in stack) {
            if (si.className == screenClassName) {
                screen = si.screen;
                break;
            }
        }
        return screen;
    }

    public function startRootScreen(screenClassName: String, ?requestData: Dynamic) {
        this.startScreen(null, screenClassName, null, 1, requestData, RoxAnimate.NO_ANIMATE);
    }

    public function startScreen(source: RoxScreen, screenClassName: String,
                                finishToScreen: FinishToScreen,
                                requestCode: Int, requestData: Dynamic,
                                animate: RoxAnimate) {

//        trace(">>startScreen(" + source + "," + screenClassName + "," + finishToScreen + ")<<");
//        trace(">>>>stack=" + stack);
        if (source != null && stack.first().className != source.className)
            throw "startScreen: Illegal stack state or bad source screen '" + source + "'";
        var srcbmp: Bitmap = source != null ? snap(source) : null;
        if (finishToScreen != null) {
            finishScreen(source, finishToScreen, RoxScreen.CANCELED, null, RoxAnimate.NO_ANIMATE);
            source = null;
        } else {
            hide(source, false);
        }

        ResKeeper.currentBundle = screenClassName;
        var dest = screenPool.get(screenClassName); // check for reusable screen
        if (dest == null) {
            dest = Type.createInstance(Type.resolveClass(screenClassName), [ ]);
            if (dest == null) throw "Invalid screenClassName: " + screenClassName;
            dest.init(this, RoxApp.screenWidth, RoxApp.screenHeight);
            dest.onCreate();
        }
        if (animate == null) animate = RoxAnimate.SLIDE_LEFT;
        stack.push({ className: screenClassName, screen: dest, requestCode: requestCode, animate: animate });
        dest.onNewRequest(requestData);

        show(dest);
        if (srcbmp != null && animate.type != RoxAnimate.NONE) startAnimate(srcbmp, snap(dest), animate);
//        trace(">>End startScreen: stack=" + stack);
    }

    public function finishScreen(screen: RoxScreen,
                                 finishToScreen: FinishToScreen,
                                 resultCode: Int, resultData: Dynamic,
                                 animate: RoxAnimate) {

//        trace("<<finishScreen(" + screen + "," + finishToScreen + ")>>");
//        trace("<<stack=" + stack);
        var top: StackItem = stack.pop();
        if (top == null || top.className != screen.className)
            throw "finishScreen: Illegal stack state or bad source screen '" + top + "'";
        hide(screen, true);
        if (stack.isEmpty()) return;

        if (animate == null) animate = top.animate.getReverse();
        var srcbmp: Bitmap = animate.type != RoxAnimate.NONE ? snap(screen) : null;
        var requestCode = top.requestCode;

        if (finishToScreen == null) finishToScreen = PARENT;
        var toScreen: String = switch (finishToScreen) {
            case PARENT:
                stack.first().className;
            case ROOT:
                stack.last().className;
            case CLEAR:
                null;
            case SCREEN(name):
                var found = false;
                for (si in stack) { if (si.className == name) { found = true; break; } }
                if (!found) throw "Destination screen '" + name + "' is not on stack";
                name;
        }

        while ((top = stack.first()) != null && top.className != toScreen) {
            hide(top.screen, true);
            stack.pop();
        }

        if (top != null) {
            var topscreen: RoxScreen = top.screen;
            show(topscreen);
            if (animate.type != RoxAnimate.NONE) startAnimate(srcbmp, snap(topscreen), animate);
            topscreen.onScreenResult(requestCode, resultCode, resultData);
        }
//        trace("<<End FinishScreen: stack=" + stack);
    }

    private inline function snap(s: RoxScreen) : Bitmap {
        var bmd = new BitmapData(Std.int(s.screenWidth), Std.int(s.screenHeight));
        bmd.draw(s);
        return new Bitmap(bmd);
    }

    private function startAnimate(srcbmp: Bitmap, dest: Bitmap, anim: RoxAnimate) {
        var sw = RoxApp.screenWidth, sh = RoxApp.screenHeight;
        addChild(srcbmp);
        addChild(dest);
        switch (anim.type) {
            case RoxAnimate.SLIDE:
                switch (cast(anim.arg, String)) {
                    case "up":
                        dest.y = sh;
                    case "right":
                        dest.x = -sw;
                    case "down":
                        dest.y = -sh;
                    case "left":
                        dest.x = sw;
                }
                Actuate.tween(srcbmp, anim.interval, { x: -dest.x, y: -dest.y });
                Actuate.tween(dest, anim.interval, { x: 0, y: 0 }).onComplete(animDone, [ srcbmp, dest ]);
            case RoxAnimate.ZOOM_IN: // popup
                var r: Rectangle = cast(anim.arg);
                dest.scaleX = dest.scaleY = r.width / sw;
                dest.x = r.x;
                dest.y = r.y;
                dest.alpha = 0;
                Actuate.tween(dest, anim.interval, { x: 0, y: 0, scaleX: 1, scaleY: 1, alpha: 1 })
                        .onComplete(animDone, [ srcbmp, dest ]);
            case RoxAnimate.ZOOM_OUT: // shrink
                var num = this.numChildren;
                this.swapChildrenAt(num - 2, num - 1); // make sure srcbmp is on top
                var r: Rectangle = cast(anim.arg);
                var scale = r.width / sw;
                Actuate.tween(srcbmp, anim.interval, { x: r.x, y: r.y, scaleX: scale, scaleY: scale, alpha: 0.01 })
                        .onComplete(animDone, [ srcbmp, dest ]);

        }
    }

    private inline function animDone(srcbmp: Bitmap, dest: Bitmap) {
        removeChild(srcbmp);
        removeChild(dest);
    }

    private function hide(screen: RoxScreen, finish: Bool) {
        if (screen == null) return;
        if (contains(screen)) {
            removeChild(screen);
            screen.onHidden();
        }
        if (!finish) return;
        if (screen.disposeAtFinish) {
            ResKeeper.disposeBundle(screen.className);
            screen.onDestroy();
        } else { // add to pool for recycling
            screenPool.set(screen.className, screen);
        }
    }

    private function show(dest: RoxScreen) {
        if (dest == null || contains(dest)) return;
        dest.x = dest.y = 0;
        dest.alpha = dest.scaleX = dest.scaleY = 1;
        addChild(dest);
        dest.onShown();
    }

}

private typedef StackItem = {
    var className: String;
    var screen: RoxScreen;
    var requestCode: Int;
    var animate: RoxAnimate;
}
