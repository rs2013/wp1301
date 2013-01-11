package com.weiplus.client;

import flash.geom.Rectangle;
import nme.display.Shape;
import com.roxstudio.haxe.ui.RoxScreen;
import com.eclecticdesignstudio.motion.Actuate;
import nme.display.Bitmap;
import nme.display.BitmapData;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.ui.UiUtil;
import com.weiplus.client.model.User;
import com.weiplus.client.model.AppData;
import com.weiplus.client.model.Status;
import nme.display.DisplayObject;
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
#if !html5
import com.weiplus.apps.jigsaw.App;
#end
import com.weiplus.apps.slidepuzzle.App;
import com.weiplus.apps.swappuzzle.App;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class UserScreen extends BaseScreen {

    private static inline var SPACING_RATIO = 1 / 40;

    var main: Sprite;
    var mainh: Float;
    var viewh: Float;
    var agent: RoxGestureAgent;
    var numCol: Int = 2;
    var postits: Array<Postit>;

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("用户资料", 0xFF0000, 36));
        super.onCreate();
        agent = new RoxGestureAgent(content, RoxGestureAgent.GESTURE);
        content.addEventListener(RoxGestureEvent.GESTURE_PAN, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onGesture);
    }

    override public function createContent(height: Float) : Sprite {
        var sp = new Sprite();

        main = new Sprite();
        update(2);
        sp.addChild(main);

        var btnNames = [ "icon_home", "icon_selected", "icon_maker", "icon_message", "icon_account" ];
        var btns: Array<DisplayObject> = [];
        for (b in btnNames) {
            var w = 126, h = 89;
            if (b == "icon_maker") w = 128;
            var button = new RoxFlowPane(w, h, [ UiUtil.bitmap("res/" + b + ".png") ], onButton);
            button.name = b;
            btns.push(button);
        }
        var bmd = ResKeeper.getAssetImage("res/bg_main_bottom.png");
        var npdata = new RoxNinePatchData(new Rectangle(0, 0, bmd.width, bmd.height), bmd);
        var btnpanel = new RoxFlowPane(null, null, UiUtil.LEFT | UiUtil.BOTTOM, btns,
        new RoxNinePatch(npdata), UiUtil.BOTTOM, [ 2 ]);
        sp.addChild(btnpanel.rox_scale(d2rScale).rox_move(0, height));
//        trace("btnpanel="+btnpanel.x+","+btnpanel.y+","+btnpanel.width+","+btnpanel.height);
        viewh = height - 95 * d2rScale;
        return sp;
    }

    private function update(numCol: Int) {
        if (agent != null) agent.stopTween();
        var bmd1: BitmapData = null, sp1: Sprite = null;
        if (postits != null) {
            bmd1 = new BitmapData(Std.int(screenWidth), Std.int(viewh), true, 0);
            bmd1.draw(main, new Matrix(1, 0, 0, 1, 0, main.y));
            sp1 = new Sprite();
            sp1.addChild(new Bitmap(bmd1).rox_move(-bmd1.width / 2, -bmd1.height / 2));
        }
        this.numCol = numCol;
        var idx = 0;
        if (postits != null) {
            for (i in 0...postits.length) {
                var p = postits[i];
                if (p.y + main.y > 0) {
                    idx = i;
                    break;
                }
            }
        }
        main.rox_removeAll();
        main.graphics.clear();

        var spacing = screenWidth * SPACING_RATIO;

        var shape = new Shape();
        shape.graphics.rox_fillRoundRect(0xFFEEEEEE, 0, 0, 32, 32);
        var bgbmd = new BitmapData(32, 32, true, 0);
        bgbmd.draw(shape);
        var bg = new RoxNinePatch(new RoxNinePatchData(new Rectangle(6, 6, 20, 20), new Rectangle(12, 12, 8, 8), bgbmd));
        var panel = new RoxFlowPane(screenWidth - 2 * spacing, 100,
                                    [ UiUtil.bitmap("res/data/head11.png"), UiUtil.staticText("Leody", 0, 30) ], bg, [ 100 ]);
        var pshadow = UiUtil.ninePatch("res/shadow6.9.png");
        pshadow.setDimension(panel.width + 3, panel.height + 6);
        panel.rox_move(spacing, spacing);
        pshadow.rox_move(panel.x - 2, panel.y);
        main.addChild(pshadow);
        main.addChild(panel);
//        var panel = new Bitmap(bgbmd);
//        main.addChild(panel.rox_move(spacing, spacing));

        var colh: Array<Float> = [];
        for (i in 0...numCol) colh.push(spacing + panel.height);
        var postitw = (screenWidth - (numCol + 1) * spacing) / numCol;
        var resetwidth = postits != null;
        if (postits == null) {
            postits = [];
            for (ss in statuses) {
                var status = new Status();
                status.user = new User();
                status.appData = new AppData();
                status.user.name = ss[0];
                status.user.profileImage = ss[1];
                status.appData.image = ss[3];
                status.appData.type = ss[4];
                status.appData.label = ss[5];
                status.appData.width = Std.parseInt(ss[6]);
                status.appData.height = Std.parseInt(ss[7]);
                status.text = ss[2];
                status.createdAt = Date.fromTime(Date.now().getTime() - Std.random(3600));
                var postit = new Postit(status, postitw, numCol == 1);
                postit.addEventListener(Event.SELECT, onPlay);
                postits.push(postit);
            }
        }
        var postity = 0.0;
        for (i in 0...postits.length) {
            var postit = postits[i];
            if (resetwidth) postit.setWidth(postitw, numCol == 1);
            var shadow = UiUtil.ninePatch("res/shadow6.9.png");
            shadow.setDimension(postitw + 3, postit.height + 6);

            var minh: Float = GameUtil.IMAX, colidx = 0;
            for (i in 0...colh.length) {
                if (colh[i] < minh) { minh = colh[i]; colidx = i; }
            }
            postit.rox_move(spacing + colidx * (postitw + spacing), minh + spacing);
            shadow.rox_move(postit.x - 2, postit.y);
            main.addChild(shadow);
            main.addChild(postit);
            colh[colidx] += postit.height + spacing;
            if (i == idx) {
                postity = postit.y;
            }
        }
        mainh = 0;
        for (i in 0...colh.length) {
            if (colh[i] > mainh) { mainh = colh[i]; }
        }
        mainh += spacing;
        main.graphics.rox_fillRect(0x01FFFFFF, 0, 0, main.width, main.height);
        main.y = 0;
//        main.y = spacing - postity;
//        main.y = UiUtil.rangeValue(main.y, viewh - mainh, 0);

        if (sp1 != null) {
//            animating = true;
            content.addChild(sp1.rox_move(bmd1.width / 2, bmd1.height / 2));
            if (numCol == 1) { // zoom in
                Actuate.tween(sp1, 0.4, { scaleX: 4, scaleY: 4, alpha: 0 }).onComplete(animDone, [ sp1 ]);
            } else {
                sp1.rox_scale(4);
                Actuate.tween(sp1, 0.4, { scaleX: 1, scaleY: 1, alpha: 0 }).onComplete(animDone, [ sp1 ]);
            }
        }
    }

    private function onPlay(e: Dynamic) {
//        trace("HomeScreen.onPlay: e.target=" + e.target);
        var postit: Postit = cast(e.target);
        var status = postit.status;
        var classname = "com.weiplus.apps." + status.appData.type + ".App";
        startScreen(classname, { image: postit.image.data, sideLen: Std.parseInt(status.appData.label) });
    }

    private inline function animDone(sp: DisplayObject) {
        content.removeChild(sp);
//        animating = false;
    }

    private function onGesture(e: RoxGestureEvent) {
//        if (animating) return;
        switch (e.type) {
            case RoxGestureEvent.GESTURE_TAP:
                for (i in 0...main.numChildren) {
                    var sp = main.getChildAt(i);
                    if (Std.is(sp, Postit)) {
//                        trace("e=" + e + ",sp=("+sp.x+","+sp.y+","+sp.width+","+sp.height+")");
// TODO: in gestureagent, handle bubbled mouse/touch event, use currentTarget as owner?
                        var pt = main.localToGlobal(new Point(sp.x, sp.y));
                        if (GameUtil.pointInRect(e.stageX, e.stageY, pt.x, pt.y, sp.width, sp.height)) {
                            var postit: Postit = cast(sp);
                            var r = new Rectangle(pt.x, pt.y, sp.width, sp.height);
//                            startScreen(Type.getClassName(PostitScreen), new RoxAnimate(RoxAnimate.ZOOM_IN, r), postit.status);
                            return;
                        }
                    }
                }
            case RoxGestureEvent.GESTURE_PAN:
                var pt = RoxGestureAgent.localOffset(main, cast(e.extra));
                main.y = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh, GameUtil.IMIN, 0), 0);
            case RoxGestureEvent.GESTURE_SWIPE:
                var pt = RoxGestureAgent.localOffset(main, cast(new Point(e.extra.x * 2.0, e.extra.y * 2.0)));
                var desty = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh, GameUtil.IMIN, 0), 0);
                agent.startTween(main, 2.0, { y: desty });
        }
    }

    private function onButton(e: Event) {
//        if (animating) return;
//        trace("button " + e.target.name + " clicked");
        switch (e.target.name) {
            case "icon_settings":

            case "icon_home":
                finish(Type.getClassName(HomeScreen), RoxScreen.CANCELED);
            case "icon_selected":
                startScreen(Type.getClassName(SelectedScreen), true);
            case "icon_maker":
                startScreen(Type.getClassName(MakerList), true);
            case "icon_account":

        }
    }

    private static var statuses = [
    [ "Leody", "http://rox.local/res/data/head1.png", "I like the sunshine, do you?", "http://rox.local/res/data/9.jpg", "jigsaw", "120", "640", "480" ],
    [ "Leody", "http://rox.local/res/data/head1.png", "Very funny piggy!", "http://rox.local/res/data/7.jpg", "image", "", "338", "720" ],
    [ "Leody", "http://rox.local/res/data/head1.png", "This's my friend, is she beautiful?", "http://rox.local/res/data/8.jpg", "jigsaw", "110", "580", "580" ]
    ];

}
