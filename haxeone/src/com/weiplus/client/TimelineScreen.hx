package com.weiplus.client;

import com.weiplus.client.model.PageModel;
import com.roxstudio.haxe.ui.RoxScreen;
import haxe.Json;
import com.roxstudio.haxe.io.FileUtil;
import com.eclecticdesignstudio.motion.Actuate;
import nme.display.Bitmap;
import nme.display.BitmapData;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
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

class TimelineScreen extends BaseScreen {

    private static inline var SPACING_RATIO = 1 / 40;

    var btnSingleCol: RoxFlowPane;
    var btnDoubleCol: RoxFlowPane;
    var btnCol: RoxFlowPane;
    var main: Sprite;
    var mainh: Float;
    var viewh: Float;
    var agent: RoxGestureAgent;
    var numCol: Int = 2;
    var postits: Array<Postit>;
    var animating: Bool = false;
    var buttonIndex = 0;
    var page: Dynamic;

    override public function onCreate() {
        title = UiUtil.bitmap("res/icon_logo.png");
        hasBack = false;
        super.onCreate();
        btnCol = btnSingleCol = UiUtil.button("res/icon_single_column.png", null, "res/btn_common.9.png", onButton);
        addTitleButton(btnCol, UiUtil.RIGHT);
        btnDoubleCol = UiUtil.button("res/icon_double_column.png", null, "res/btn_common.9.png", onButton);
        agent = new RoxGestureAgent(content, RoxGestureAgent.GESTURE);
        agent.swipeTimeout = 0;
        content.addEventListener(RoxGestureEvent.GESTURE_PAN, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_TAP, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_PINCH, onGesture);
    }

    override public function createContent(height: Float) : Sprite {
        var sp = super.createContent(height);

        main = new Sprite();
//        update(2);
        sp.addChild(main);

        var btnpanel = new Sprite();
        var btnbg = UiUtil.bitmap("res/bg_main_bottom.png", UiUtil.LEFT | UiUtil.BOTTOM);
        btnpanel.addChild(btnbg);
        var btnNames = [ "icon_home", "icon_selected", "icon_maker", "icon_message", "icon_account" ];
        var xoff = 0;
        for (i in 0...btnNames.length) {
            var b = btnNames[i];
            var w = i == 2 ? 128 : 126, h = 89;
            if (i != 2 && i == buttonIndex) {
                var bg = UiUtil.bitmap("res/bg_main_bottom_selected.png", UiUtil.LEFT | UiUtil.BOTTOM);
                btnpanel.addChild(bg.rox_move(xoff, 0));
            }
            var button = new RoxFlowPane(w, h, UiUtil.LEFT | UiUtil.BOTTOM, [ UiUtil.bitmap("res/" + b + ".png") ], onButton);
            button.name = b;
            btnpanel.addChild(button.rox_move(xoff, 0));
            xoff += w + 2;
        }
        sp.addChild(btnpanel.rox_scale(d2rScale).rox_move(0, height));
//        trace("btnpanel="+btnpanel.x+","+btnpanel.y+","+btnpanel.width+","+btnpanel.height);
        viewh = height - 95 * d2rScale;

        refresh(true);

        return sp;
    }

    private function refresh(top: Bool) {
        trace("refresh: top=" + top);
        var txt = ResKeeper.getAssetText("res/home.json");
        updateList(txt, !top);
        update(numCol);
    }

//    private function
    private function updateList(jsonStr: String, append: Bool) {
        page = Json.parse(jsonStr).statuses;
        var statuses: Array<Dynamic> = page.records;
        trace("page=" + page);
        if (postits == null || !append) postits = [];
        var spacing = screenWidth * SPACING_RATIO;
        var postitw = (screenWidth - (numCol + 1) * spacing) / numCol;
        for (ss in statuses) {
            var status = new Status();
            status.id = ss.id;
            status.user = new User();
            status.appData = new AppData();
            status.user.id = ss.uid;
            status.user.name = ss.userNickname;
            status.user.profileImage = ss.userAvatar;
            var att = ss.attachments[0];
            status.appData.image = att.thumbUrl;
            status.appData.type = ss.gameType;
//                status.appData.label = ss[5];
            status.appData.width = att.thumbWidth;
            status.appData.height = att.thumbHeight;
            status.appData.id = att.id;
            status.appData.url = att.attachUrl;
            status.text = ss.status;
            status.createdAt = Date.fromTime(ss.ctime);
            var postit = new Postit(status, postitw, numCol == 1);
            postit.addEventListener(Event.SELECT, onPlay);
            postits.push(postit);
        }

    }

    private function update(numCol: Int) {
        if (agent != null) agent.stopTween();
        var updateCol = this.numCol != numCol;
        var bmd1: BitmapData = null, sp1: Sprite = null;
        if (updateCol) { // prepare snap for animating column changes
            bmd1 = new BitmapData(Std.int(screenWidth), Std.int(viewh), true, 0);
            bmd1.draw(main, new Matrix(1, 0, 0, 1, 0, main.y));
            sp1 = new Sprite();
            sp1.addChild(new Bitmap(bmd1).rox_move(-bmd1.width / 2, -bmd1.height / 2));
        }
        this.numCol = numCol;
        var visibleIdx = 0;
        for (i in 0...postits.length) {
            var p = postits[i];
            if (p.y + main.y > 0) {
                visibleIdx = i;
                break;
            }
        }
        main.rox_removeAll();
        main.graphics.clear();
        var colh: Array<Float> = [];
        for (i in 0...numCol) colh.push(0);
        var spacing = screenWidth * SPACING_RATIO;
        var postitw = (screenWidth - (numCol + 1) * spacing) / numCol;
        var postity = 0.0;
        for (i in 0...postits.length) {
            var postit = postits[i];
            if (updateCol) postit.setWidth(postitw, numCol == 1);
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
            if (i == visibleIdx) {
                postity = postit.y;
            }
        }
        mainh = 0;
        for (i in 0...colh.length) {
            if (colh[i] > mainh) { mainh = colh[i]; }
        }
        mainh += spacing;
        main.graphics.rox_fillRect(0x01FFFFFF, 0, 0, main.width, main.height);

        if (updateCol) {
            main.y = spacing - postity;
            main.y = UiUtil.rangeValue(main.y, viewh - mainh, 0);
        }

        if (sp1 != null) {
            animating = true;
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
//        startScreen(classname, { image: postit.image.data, sideLen: Std.parseInt(status.appData.label) });
        startScreen(classname, status);
    }

    private inline function animDone(sp: DisplayObject) {
        content.removeChild(sp);
        animating = false;
    }

    private function onGesture(e: RoxGestureEvent) {
        if (animating) return;
//        trace(">>>t=" + e.target+",e="+e);
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
                main.y = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh - 100, GameUtil.IMIN, 0), 100);
            case RoxGestureEvent.GESTURE_SWIPE:
                var pt = RoxGestureAgent.localOffset(main, cast(new Point(e.extra.x * 2.0, e.extra.y * 2.0)));
                var desty = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh, GameUtil.IMIN, 0), 0);
                var tm = main.y > 0 || main.y < viewh - mainh ? 1 : 2;
                if (main.y > 60 || main.y < viewh - mainh - 60) refresh(main.y > 0);
                agent.startTween(main, tm, { y: desty });
            case RoxGestureEvent.GESTURE_PINCH:
//                trace("pinch:numCol=" + numCol + ",extra=" + e.extra);
                if (numCol > 1 && e.extra > 1) {
                    removeTitleButton(btnCol);
                    addTitleButton(btnCol = btnDoubleCol, UiUtil.RIGHT);
                    update(1);
                } else if (numCol == 1 && e.extra < 1) {
                    removeTitleButton(btnCol);
                    addTitleButton(btnCol = btnSingleCol, UiUtil.RIGHT);
                    update(2);
                }
        }
    }

    private function onButton(e: Event) {
        if (animating) return;
//        trace("button " + e.target.name + " clicked");
        switch (e.target.name) {
            case "icon_single_column":
                removeTitleButton(btnCol);
                addTitleButton(btnCol = btnDoubleCol, UiUtil.RIGHT);
                update(1);
            case "icon_double_column":
                removeTitleButton(btnCol);
                addTitleButton(btnCol = btnSingleCol, UiUtil.RIGHT);
                update(2);
            case "icon_home":
                if (buttonIndex != 0) finish(Type.getClassName(HomeScreen), RoxScreen.CANCELED);
//                startScreen(Type.getClassName(com.weiplus.client.TestGesture), new RoxAnimate(RoxAnimate.ZOOM_IN, new Rectangle(80, 80, 200, 300)));
            case "icon_selected":
                if (buttonIndex != 1) startScreen(Type.getClassName(SelectedScreen), buttonIndex != 0);
            case "icon_maker":
                if (buttonIndex != 2) startScreen(Type.getClassName(MakerList), buttonIndex != 0);
            case "icon_message":
//                if (tabIndex != 3) startScreen(Type.getClassName(MessageScreen), tabIndex != 0);
            case "icon_account":
                if (buttonIndex != 4) startScreen(Type.getClassName(UserScreen), buttonIndex != 0);
        }
    }

}
