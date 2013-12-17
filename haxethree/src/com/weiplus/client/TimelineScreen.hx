package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.i18n.I18n;
import nme.events.MouseEvent;
import com.roxstudio.haxe.ui.UiUtil;
import com.weiplus.client.model.Routine;
#if cpp
import sys.FileSystem;
import sys.io.File;
#end
import motion.easing.Linear;
import motion.Actuate;
import com.weiplus.client.MyUtils;
import com.roxstudio.haxe.ui.UiUtil;
import StringTools;
import com.weiplus.client.model.PageModel;
import com.roxstudio.haxe.ui.RoxScreen;
import haxe.Json;
import com.roxstudio.haxe.io.FileUtil;
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

using com.roxstudio.i18n.I18n;
using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class TimelineScreen extends BaseScreen {

    private static inline var ALBUM_DIR = MyUtils.ALBUM_DIR;
    private static inline var MAX_POSTITS = 25;

    public static inline var SPACING_RATIO = 1 / 40;
    private static inline var REFRESH_HEIGHT = 150;
    private static inline var TRIGGER_HEIGHT = 100;
    private static inline var CACHE_DIR = MyUtils.CACHE_DIR;

    var btnSingleCol: RoxFlowPane;
    var btnDoubleCol: RoxFlowPane;
    var btnCol: RoxFlowPane;
    public var main: Sprite;
    var mainh: Float;
    public var viewh: Float;
    var agent: RoxGestureAgent;
    var numCol: Int = 2;
    var postits: Array<Postit>;
    var animating: Bool = false;
    var screenTabIndex = 1;
    var storedStatuses: Array<Dynamic>;
    var page: PageModel;
    var compactMode = false;

    override public function onCreate() {
//        starttm = haxe.Timer.stamp();
        if (title == null) title = UiUtil.bitmap("res/icon_logo.png");
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
        var btnpanel = buttonPanel();
        btnpanel.name = "buttonPanel";

        addChild(btnpanel.rox_move(0, screenHeight));
//        trace("btnpanel="+btnpanel.x+","+btnpanel.y+","+btnpanel.width+","+btnpanel.height);
        viewh = screenHeight - titleBar.height - btnpanel.height;
    }

    override public function onNewRequest(data: Dynamic) {
        super.onNewRequest(data);
        UiUtil.delay(function() {
#if cpp
            restore();
#end
            if (storedStatuses == null || storedStatuses.length == 0) {
                addChild(MyUtils.getLoadingAnim("载入中".i18n()).rox_move(screenWidth / 2, screenHeight / 2));
                refresh(false);
            } else {
                updateList(storedStatuses, false);
            }
        }, 0.4);
//        trace("TimelineScreen started: time=" + (haxe.Timer.stamp() - starttm));
    }

    override public function createContent(height: Float) : Sprite {
        var sp = super.createContent(height);

        main = new Sprite();
//        update(2);
        sp.addChild(main);
        return sp;
    }

//    override public function onShown() {
//        trace("Screen(" + name + ").onShown");
//        super.onShown();
//    }
//
//    override public function onHidden() {
//        trace("Screen(" + name + ").onHidden");
//        super.onHidden();
//    }

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

    public function refresh(append: Bool) {
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
            status.praised = ss.praise == 1;
            status.mark = ss.mark;

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
            var postit = new Postit(this, status, postitw, compactMode ? Postit.COMPACT : numCol == 1 ? Postit.FULL : Postit.NORMAL);
//            postit.addEventListener(Event.SELECT, onPlay);
            postits.push(postit);
        }
        if (page != null && statuses.length > 0) page.oldestId = oldest;
        if (postits.length > MAX_POSTITS) postits.splice(0, postits.length - MAX_POSTITS);
        update(numCol);
//        DisplayListQuery.query.print(this.parent);
//        trace("Postit.Sprite".find(this.parent));
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
            if (updateCol) postit.setWidth(postitw, compactMode ? Postit.COMPACT : numCol == 1 ? Postit.FULL : Postit.NORMAL);
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

        for (p in postits) p.update();
    }

    private function onPlay(postit: Postit) {
//        trace("HomeScreen.onPlay: e.target=" + e.target);
//        var postit: Postit = cast(e.target);
        var status = postit.status;
        if (status.isGame()) {
            var classname = "com.weiplus.apps." + status.appData.type + ".App";
            startScreen(classname, null, null, null, 1, status);
        } else {
            startScreen(Type.getClassName(PictureScreen), { status: status, image: null });
        }
    }

    private inline function animDone(sp: DisplayObject) {
        content.removeChild(sp);
        animating = false;
    }

    private function onGesture(e: RoxGestureEvent) {
        if (animating) return;
//        trace(">>>type=" + e.type + ",target=" + e.target+",current="+e.currentTarget);
        switch (e.type) {
            case RoxGestureEvent.GESTURE_TAP:
//                trace("timeline.onTap,target=" + e.target + ",currentTarget=" + e.currentTarget);
                for (i in 0...main.numChildren) {
                    var sp = main.getChildAt(i);
                    if (Std.is(sp, Postit)) {
//                        trace("e=" + e + ",sp=("+sp.x+","+sp.y+","+sp.width+","+sp.height+")");
// TODO: in gestureagent, handle bubbled mouse/touch event, use currentTarget as owner?
                        var pt = main.localToGlobal(new Point(sp.x, sp.y));
                        var bounds = cast(sp, Postit).imageBounds;
                        if (GameUtil.pointInRect(e.stageX, e.stageY, pt.x, pt.y, bounds.x, bounds.y)) {
                            var postit: Postit = cast(sp);
//                            var r = new Rectangle(pt.x, pt.y, sp.width, sp.height);
                            onPlay(postit);
                            return;
                        }
                    }
                }
            case RoxGestureEvent.GESTURE_PAN:
                var pt = RoxGestureAgent.localOffset(main, cast(e.extra));
                main.y = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh - REFRESH_HEIGHT, GameUtil.IMIN, 0), REFRESH_HEIGHT);

                if (main.y > 0) {
                    if (main.getChildByName("topRefresher") == null) {
                        var refresher = new Refresher("topRefresher", true);
                        main.addChild(refresher.rox_move(0, -refresher.height));
                    } else if (main.y > TRIGGER_HEIGHT) {
                        cast(main.getChildByName("topRefresher"), Refresher).updateText();
                    }
                } else if (main.y < viewh - mainh) {
                    if (main.getChildByName("bottomRefresher") == null) {
                        var refresher = new Refresher("bottomRefresher", false);
                        main.addChild(refresher.rox_move(0, main.height));
                    } else if (main.y < viewh - mainh - TRIGGER_HEIGHT) {
                        cast(main.getChildByName("bottomRefresher"), Refresher).updateText();
                    }
                } else {
//                    for (p in postits) p.update();
                }
            case RoxGestureEvent.GESTURE_SWIPE:
                var pt = RoxGestureAgent.localOffset(main, cast(new Point(e.extra.x * 2.0, e.extra.y * 2.0)));
                var desty = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh, GameUtil.IMIN, 0), 0);
                var tm = main.y > 0 || main.y < viewh - mainh ? 1 : 2;
                if (main.y > TRIGGER_HEIGHT || main.y < viewh - mainh - TRIGGER_HEIGHT) refresh(main.y <= 0);
                agent.startTween(main, tm, { y: desty });
                UiUtil.delay(function() {
                    main.rox_removeByName("topRefresher");
                    main.rox_removeByName("bottomRefresher");
                }, tm);
                UiUtil.delay(function() { for (p in postits) p.update(); }, tm * 0.5);
            case RoxGestureEvent.GESTURE_PINCH:
                if (compactMode) return;
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

    override public function onTitleClicked() {
        super.onTitleClicked();
        agent.startTween(main, 1, { y: 0 });
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
                if (screenTabIndex != 0) startScreen(Type.getClassName(HomeScreen), null, FinishToScreen.CLEAR);
            case "icon_selected":
                if (screenTabIndex != 1) startScreen(Type.getClassName(SelectedScreen), null, FinishToScreen.CLEAR);
            case "icon_maker":
                startScreen(Type.getClassName(AndroidCamera), null, RoxAnimate.NO_ANIMATE);
            case "icon_message":
                if (screenTabIndex != 3) checkStartScreen(Type.getClassName(RoutineScreen));
            case "icon_account":
                if (screenTabIndex != 4) checkStartScreen(Type.getClassName(UserScreen));
        }
    }

    private function checkStartScreen(screenName: String) {
        var action = function() { startScreen(screenName, FinishToScreen.CLEAR); };
        if (HpApi.instance.isDefault()) {
            startScreen(Type.getClassName(LoginScreen), null, action);
        } else {
            action();
        }
    }
}
