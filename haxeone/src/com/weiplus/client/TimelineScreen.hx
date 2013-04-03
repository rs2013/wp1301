package com.weiplus.client;

#if cpp
import com.weiplus.client.model.Routine;
import com.roxstudio.haxe.ui.UiUtil;
import sys.FileSystem;
import sys.io.File;
#end
import StringTools;
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

    public static inline var SPACING_RATIO = 1 / 40;
    private static inline var REFRESH_HEIGHT = 150;
    private static inline var TRIGGER_HEIGHT = 100;
#if android
    public static inline var CACHE_DIR = "/sdcard/.harryphoto/cache";
#elseif windows
    public static inline var CACHE_DIR = "cache";
#end

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
    var screenTabIndex = 1;
    var storedStatuses: Array<Dynamic>;
    var page: PageModel;

    override public function onCreate() {
        title = UiUtil.bitmap("res/icon_logo.png");
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
        var btnpanel = buttonPanel();
        btnpanel.name = "buttonPanel";

        addChild(btnpanel.rox_move(0, screenHeight));
//        trace("btnpanel="+btnpanel.x+","+btnpanel.y+","+btnpanel.width+","+btnpanel.height);
        viewh = height - 95 * d2rScale;

    }

    override public function onNewRequest(data: Dynamic) {
        super.onNewRequest(data);
#if cpp
        restore();
#end
        if (storedStatuses == null || storedStatuses.length == 0) {
            addChild(MyUtils.getLoadingAnim("载入中").rox_move(screenWidth / 2, screenHeight / 2));
            refresh(false);
        } else {
            updateList(storedStatuses, false);
        }
    }

    override public function createContent(height: Float) : Sprite {
        var sp = super.createContent(height);

        main = new Sprite();
//        update(2);
        sp.addChild(main);
        return sp;
    }

    private function buttonPanel() : Sprite {
        var btnpanel = new Sprite();
        var btnbg = UiUtil.bitmap("res/bg_main_bottom.png", UiUtil.LEFT | UiUtil.BOTTOM);
        btnpanel.addChild(btnbg);
        var btnNames = [ "icon_home", "icon_selected", "icon_maker", "icon_message", "icon_account" ];
        var xoff = 0;
        for (i in 0...btnNames.length) {
            var b = btnNames[i];
            var w = i == 2 ? 128 : 126, h = 89;
            if (i != 2 && i == screenTabIndex) {
                var bg = UiUtil.bitmap("res/bg_main_bottom_selected.png", UiUtil.LEFT | UiUtil.BOTTOM);
                btnpanel.addChild(bg.rox_move(xoff, 0));
            }
            var button = new RoxFlowPane(w, h, UiUtil.LEFT | UiUtil.BOTTOM, [ UiUtil.bitmap("res/" + b + ".png") ], onButton);
            button.name = b;
            btnpanel.addChild(button.rox_move(xoff, 0));
            xoff += w + 2;
        }
        btnpanel.rox_scale(d2rScale);
        return btnpanel;
    }

    private function refresh(append: Bool) {
        var jsonStr = ResKeeper.getAssetText("res/home.json");
        var statuses: Array<Dynamic> = Json.parse(jsonStr).statuses.records;
        updateList(statuses, append);
    }

    private function getHeadPanel() : Sprite {
        return null;
    }

//    private function
    private function updateList(statuses: Array<Dynamic>, append: Bool) {
        UiUtil.rox_removeByName(this, MyUtils.LOADING_ANIM_NAME);

        if (postits == null || !append) postits = [];
        if (statuses != null) {
            if (storedStatuses == null || !append) storedStatuses = [];
            storedStatuses = storedStatuses.concat(statuses);
#if cpp
            store();
#end
        } else {
            statuses = storedStatuses;
        }
        var spacing = screenWidth * SPACING_RATIO;
        var postitw = (screenWidth - (numCol + 1) * spacing) / numCol;
        var oldest: Float = 999999999999.0;
        for (i in 0...statuses.length) {
            var ss = statuses[i];
            var status = new Status();
            status.id = ss.id;
            var lid = Std.parseFloat(ss.id);
            if (lid < oldest) oldest = lid;
            status.text = ss.status;
            status.createdAt = Date.fromTime(ss.ctime);
            status.commentCount = ss.commentCount;
            status.praiseCount = ss.praiseCount;
            status.repostCount = ss.repostCount;
            status.favoriteCount = ss.favoriteCount;

            status.user = new User();
            status.user.id = ss.uid;
            status.user.name = ss.userNickname;
            status.user.profileImage = ss.userAvatar;
            var attachments: Array<Dynamic> = ss.attachments;
            if (attachments != null &&attachments.length > 0) {
                var att = attachments[0];
                status.appData = new AppData();
                status.appData.image = att.thumbUrl;
                status.appData.type = ss.gameType == null ? "image" : ss.gameType;
                status.appData.width = att.thumbWidth;
                status.appData.height = att.thumbHeight;
                status.appData.id = att.id;
                status.appData.url = att.attachUrl;
                status.appData.label = att.attachName;
            }
            var postit = new Postit(status, postitw, numCol == 1);
            postit.addEventListener(Event.SELECT, onPlay);
            postits.push(postit);
        }
        if (page != null && statuses.length > 0) page.oldestId = oldest;
        update(numCol);
    }

#if cpp

    private function restore() {
        var filename = StringTools.replace(Type.getClassName(Type.getClass(this)), ".", "_") + ".json";
        var cache = ResKeeper.get("cache:" + filename);
        if (cache != null) {
            storedStatuses = Json.parse(cast cache);
        }
    }

    private function store() {
        var filename = StringTools.replace(Type.getClassName(Type.getClass(this)), ".", "_") + ".json";
        FileUtil.mkdirs(CACHE_DIR);
        var path = CACHE_DIR + "/" + filename;
        var jsonStr = Json.stringify(storedStatuses);
        File.saveContent(CACHE_DIR + "/" + filename, jsonStr);
        ResKeeper.add("cache:" + filename, jsonStr, ResKeeper.DEFAULT_BUNDLE);
    }

#end

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
        mainh = 0;

        var spacing = screenWidth * SPACING_RATIO;
        var yoffset = 0.0;
        var headPanel = getHeadPanel();
        if (headPanel != null) {
            yoffset += headPanel.height + spacing;
            main.addChild(headPanel);
            mainh += headPanel.height;
        }
        var colh: Array<Float> = [];
        for (i in 0...numCol) colh.push(0);
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
            postit.rox_move(spacing + colidx * (postitw + spacing), minh + spacing + yoffset);
            shadow.rox_move(postit.x - 2, postit.y);
            main.addChild(shadow);
            main.addChild(postit);
            colh[colidx] += postit.height + spacing;
            if (i == visibleIdx) {
                postity = postit.y;
            }
        }
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
                main.y = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh - REFRESH_HEIGHT, GameUtil.IMIN, 0), REFRESH_HEIGHT);
            case RoxGestureEvent.GESTURE_SWIPE:
                var pt = RoxGestureAgent.localOffset(main, cast(new Point(e.extra.x * 2.0, e.extra.y * 2.0)));
                var desty = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh, GameUtil.IMIN, 0), 0);
                var tm = main.y > 0 || main.y < viewh - mainh ? 1 : 2;
                if (main.y > TRIGGER_HEIGHT || main.y < viewh - mainh - TRIGGER_HEIGHT) refresh(main.y <= 0);
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
//                sys.io.File.saveBytes("test.png", GameUtil.encodePng(ResKeeper.getAssetImage("res/icon_maker.png")));
                if (screenTabIndex != 0) finish(SCREEN(Type.getClassName(HomeScreen)), RoxScreen.CANCELED);
//                startScreen(Type.getClassName(com.weiplus.client.TestGesture), new RoxAnimate(RoxAnimate.ZOOM_IN, new Rectangle(80, 80, 200, 300)));
            case "icon_selected":
                if (screenTabIndex != 1) startScreen(Type.getClassName(SelectedScreen), screenTabIndex != 0 ? PARENT : null);
            case "icon_maker":
                if (screenTabIndex != 2) {
                    var btnRect = new Rectangle(screenWidth * 0.4, screenHeight - 100, screenWidth * 0.2, 100);
                    startScreen(Type.getClassName(MakerList), new RoxAnimate(RoxAnimate.ZOOM_IN, btnRect), this.className);
                }
            case "icon_message":
                if (screenTabIndex != 3) startScreen(Type.getClassName(RoutineScreen), screenTabIndex != 0 ? PARENT : null);
            case "icon_account":
                if (screenTabIndex != 4) startScreen(Type.getClassName(UserScreen), screenTabIndex != 0 ? PARENT : null);
        }
    }

}
