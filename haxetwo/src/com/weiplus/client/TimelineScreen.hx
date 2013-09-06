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

import com.weiplus.apps.jigsaw.Maker;
import com.weiplus.apps.slidepuzzle.Maker;
import com.weiplus.apps.swappuzzle.Maker;

using com.roxstudio.i18n.I18n;
using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class TimelineScreen extends BaseScreen {

    private static inline var ALBUM_DIR = "/sdcard/DCIM/Camera";

    public static inline var SPACING_RATIO = 1 / 40;
    private static inline var REFRESH_HEIGHT = 150;
    private static inline var TRIGGER_HEIGHT = 100;
    private static inline var FADE_TM = 0.2;
#if android
    public static inline var CACHE_DIR = "/sdcard/.harryphoto/cache";
#elseif windows
    public static inline var CACHE_DIR = "cache";
#end

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
    private var popupbg: Sprite;
    private var popup1: Sprite;
    private var popup2: Sprite;
//    private var starttm: Float;
    private var makerId: String;
    private var requestCode = -1;
    private var snapPath: String;

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

        this.addEventListener(Event.ACTIVATE, onActive);
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
            var postit = new Postit(status, postitw, compactMode ? Postit.COMPACT : numCol == 1 ? Postit.FULL : Postit.NORMAL);
            postit.addEventListener(Event.SELECT, onPlay);
            postits.push(postit);
        }
        if (page != null && statuses.length > 0) page.oldestId = oldest;
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
                    for (p in postits) p.update();
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
                UiUtil.delay(function() for (p in postits) p.update(), tm * 0.5);
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
//                sys.io.File.saveBytes("test.png", GameUtil.encodePng(ResKeeper.getAssetImage("res/icon_maker.png")));
                if (screenTabIndex != 0) finish(SCREEN(Type.getClassName(HomeScreen)), RoxScreen.CANCELED);
//                startScreen(Type.getClassName(com.weiplus.client.TestGesture), new RoxAnimate(RoxAnimate.ZOOM_IN, new Rectangle(80, 80, 200, 300)));
            case "icon_selected":
                if (screenTabIndex != 1) startScreen(Type.getClassName(SelectedScreen), screenTabIndex != 0 ? PARENT : null);
            case "icon_maker":
                createPopups();
                if (!contains(popupbg)) {
                    addChild(popupbg);
                    doPop(1);
                }
//                    var btnRect = new Rectangle(screenWidth * 0.4, screenHeight - 100, screenWidth * 0.2, 100);
//                    startScreen(Type.getClassName(MakerList), new RoxAnimate(RoxAnimate.ZOOM_IN, btnRect), this.className);
            case "icon_message":
                if (screenTabIndex != 3) checkStartScreen(Type.getClassName(RoutineScreen));
            case "icon_account":
                if (screenTabIndex != 4) checkStartScreen(Type.getClassName(UserScreen));
        }
    }

    private function checkStartScreen(screenName: String) {
        if (HpApi.instance.isDefault()) {
            startScreen(Type.getClassName(LoginScreen), 12346);
        } else {
            startScreen(screenName, screenTabIndex != 0 ? PARENT : null);
        }
    }

    private function doPop(action: Int) {
        if (animating) return;
        animating = true;
        var pin: Sprite = switch (action) { case 1: popup1; case 2: popup2; case 3: popup1; case 4: null; case _: null; }
        var pout: Sprite = switch (action) { case 1: null; case 2: popup1; case 3: popup2; case 4: popupbg.contains(popup1) ? popup1 : popup2; case _: null; }
//        trace("pin=" + pin+",pout=" + pout);
        if (pin != null) {
            popupbg.addChild(pin);
            pin.alpha = 0.01;
            Actuate.tween(pin, FADE_TM, { alpha: 1 } ).ease(Linear.easeNone);
        }
        if (pout != null) {
            pout.alpha = 1;
            Actuate.tween(pout, FADE_TM, { alpha: 0.01 } ).ease(Linear.easeNone);
        }
        UiUtil.delay(function() { popupbg.rox_remove(pout); animating = false; }, FADE_TM);
    }

    private function createPopups() {
        if (popupbg != null) return;
        popupbg = new Sprite();
        popupbg.graphics.rox_fillRect(0x77000000, 0, 0, screenWidth, screenHeight);
        var fadeout = function(_) {
            doPop(4);
            UiUtil.delay(function() { this.rox_remove(popupbg); }, FADE_TM);
        }
        var items: Array<ListItem> = [];
        items.push({ id: "", icon: null, name: "用照片创建小游戏".i18n(), type: 1, data: null });
        items.push({ id: "jigsaw", icon: "res/icon_jigsaw_maker.png", name: "奇幻拼图".i18n(), type: 3, data: null });
        items.push({ id: "swappuzzle", icon: "res/icon_swap_maker.png", name: "方块挑战".i18n(), type: 3, data: null });
        items.push({ id: "slidepuzzle", icon: "res/icon_slide_maker.png", name: "移形换位".i18n(), type: 3, data: null });
        items.push({ id: "", icon: null, name: "拍摄神奇魔法照片".i18n(), type: 1, data: null });
        items.push({ id: "camera", icon: "res/icon_camera.png", name: "魔法相机".i18n(), type: 2, data: null });
        popup1 = MyUtils.bubbleList(items, function(i: ListItem) {
//            trace(i);
            switch (i.id) {
                case "camera":
                    startScreen(Type.getClassName(MagicCamera), {});
                    MyUtils.makerParentScreen = this.className;
                    fadeout(null);
                default:
                    makerId = i.id;
                    doPop(2);
            }
            return true;
        });

        items = [];
        items.push({ id: "", icon: null, name: "用照片创建小游戏".i18n(), type: 1, data: null });
        items.push({ id: "local_album", icon: "res/icon_local_album.png", name: "从相册选择".i18n(), type: 2, data: null });
        items.push({ id: "sys_camera", icon: "res/icon_sys_camera.png", name: "系统相机拍摄".i18n(), type: 2, data: null });
        items.push({ id: "harry_camera", icon: "res/icon_harry_camera.png", name: "魔法相机拍摄".i18n(), type: 2, data: null });
        items.push({ id: "back", icon: "res/icon_back.png", name: "", type: 4, data: null });
        popup2 = MyUtils.bubbleList(items, function(i: ListItem) {
            switch (i.id) {
                case "local_album":
                    onLocal(null);
                    fadeout(null);
                case "sys_camera":
                    onCamera(null);
                    fadeout(null);
                case "harry_camera":
                    onHarry(null);
                    fadeout(null);
                case "back":
                    makerId = null;
                    doPop(3);
            }
            return true;
        });
        var btnPanel = getChildByName("buttonPanel");
        popup1.rox_move((screenWidth - popup1.width) / 2, screenHeight - popup1.height - btnPanel.height - 5);
        popup2.rox_move((screenWidth - popup2.width) / 2, screenHeight - popup2.height - btnPanel.height - 5);
        popupbg.mouseEnabled = true;
        popupbg.addEventListener(MouseEvent.CLICK, fadeout);
    }

    private function onActive(_) {
        if (requestCode < 0) return;
#if android
        var s = HaxeStub.getResult(requestCode);
        var json: Dynamic = haxe.Json.parse(s);
        if (untyped json.resultCode != "ok") return;
        var path = requestCode == 1 ? snapPath : untyped json.intentDataPath;
        var bmd = ResKeeper.loadLocalImage(path);
#else
        var bmd = ResKeeper.loadAssetImage("res/8.jpg");
#end
        requestCode = -1;
        startScreen("com.weiplus.apps." + makerId + ".Maker", bmd);
        MyUtils.makerParentScreen = this.className;
    }

    private function onHarry(_) {
        trace("onHarry, makerId=" + makerId);
        requestCode = 3;
        startScreen(Type.getClassName(MagicCamera), 223);
//#if android
//        HaxeStub.startHarryCamera(requestCode);
//#else
//        onActive(null);
//#end
    }

    override public function onScreenResult(requestCode: Int, resultCode: Int, resultData: Dynamic) {
        trace("onScreenResult,resultCode=" + resultCode+",data="+resultData+",makerId="+makerId);
        if (requestCode == 223 && resultCode == RoxScreen.OK) {
            var bmd: BitmapData = cast resultData;
            startScreen("com.weiplus.apps." + makerId + ".Maker", bmd);
            MyUtils.makerParentScreen = this.className;
        } else if (requestCode == 12346 && resultCode == RoxScreen.OK) {
            UiUtil.delay(finish.bind(SCREEN(Type.getClassName(HomeScreen)), null, RoxScreen.CANCELED, null));
        }
    }

    private function onCamera(_) {
//        trace("oncamera");
        requestCode = 1;
#if android
        if (!sys.FileSystem.exists(ALBUM_DIR)) com.roxstudio.haxe.io.FileUtil.mkdirs(ALBUM_DIR);
        var name = "harryphoto_" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
        snapPath = ALBUM_DIR + "/" + name;
        HaxeStub.startImageCapture(requestCode, snapPath);
#else
        onActive(null);
#end
    }

    private function onLocal(_) {
//        trace("onlocal");
//        if (!FileSystem.exists(ALBUM_DIR)) FileUtil.mkdirs(ALBUM_DIR);
//        var name = "" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
        requestCode = 2;
#if android
        HaxeStub.startGetContent(requestCode, "image/*");
#else
        onActive(null);
#end
    }

}
