package com.weiplus.client;

import com.eclecticdesignstudio.motion.easing.Linear;
import com.eclecticdesignstudio.motion.Actuate;
import com.weiplus.client.MyUtils;
import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.ui.RoxAnimate;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import nme.geom.Point;
import nme.events.MouseEvent;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.BitmapData;
import nme.events.Event;
import com.roxstudio.haxe.game.GameUtil;
import com.weiplus.client.model.Routine;
import com.weiplus.client.model.User;
import com.weiplus.client.model.PageModel;
import com.weiplus.client.model.Comment;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class RoutineScreen extends BaseScreen {

    private static inline var ALBUM_DIR = "/sdcard/DCIM/Camera";

    private static inline var REFRESH_HEIGHT = 100;
    private static inline var TRIGGER_HEIGHT = 60;
    private static inline var SPACING_RATIO = 1 / 40;
    private static inline var FADE_TM = 0.2;

    private var append: Bool;
    private var refreshing: Bool = false;

    private var routines: Array<Routine>;
    private var page: PageModel;
    private var main: Sprite;
    private var mainh: Float;
    private var viewh: Float;

    var animating: Bool = false;
    private var popupbg: Sprite;
    private var popup1: Sprite;
    private var popup2: Sprite;
    private var makerId: String;
    private var requestCode = -1;
    private var snapPath: String;
    var agent: RoxGestureAgent;

    public function new() {
        super();
    }

    override public function onNewRequest(data: Dynamic) {
//        uid = data != null ? cast data : HpApi.instance.uid; // user id
        addChild(MyUtils.getLoadingAnim("载入中").rox_move(screenWidth / 2, screenHeight / 2));
        refresh(false);
    }

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("消息", 0xFFFFFF, buttonFontSize * 1.2));
        super.onCreate();
        var btnpanel = buttonPanel();
        btnpanel.name = "buttonPanel";
        addChild(btnpanel.rox_move(0, screenHeight));
        viewh = screenHeight - btnpanel.height - titleBar.height;
        this.addEventListener(Event.ACTIVATE, onActive);
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        content.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, screenWidth, h);
        main = new Sprite();
        content.addChild(main);

        agent = new RoxGestureAgent(content);
        agent.swipeTimeout = 0;
        content.addEventListener(RoxGestureEvent.GESTURE_PAN, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onGesture);
        return content;
    }

    override public function onTitleClicked() {
        super.onTitleClicked();
        agent.startTween(main, 1, { y: 0 });
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
            if (i == 3) {
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
        if (refreshing) return;
        this.append = append && page != null;
        if (this.append && page.oldestId - 1 <= 0) {
            UiUtil.message("没有更多动态了");
            return;
        }

        var param = { sinceId: 0, rows: 20 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get("/routines/home_timeline/" + HpApi.instance.uid, param, onComplete);
        refreshing = true;
    }

    private function onComplete(code: Int, data: Dynamic) {
        UiUtil.rox_removeByName(this, MyUtils.LOADING_ANIM_NAME);
        refreshing = false;
        if (code != 200) {
            UiUtil.message("网络错误. code=" + code + ",message=" + data);
            return;
        }

        var pageInfo = data.routines;
        if (page == null) page = new PageModel();
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;

        if (routines == null || !this.append) routines = [];

        var oldest: Float = 999999999999.0;
        for (c in cast(pageInfo.records, Array<Dynamic>)) {
            var routine = new Routine();
            routine.id = c.id;
            var lid = Std.parseFloat(c.id);
            if (lid < oldest) oldest = lid;
            routine.type = c.type;
            routine.oid = c.oid;
            routine.digest = c.digest;
            routine.createdAt = Date.fromTime(c.ctime);
            var user: User = routine.user = new User();
            user.id = c.uid;
            user.name = c.userNickname;
            user.profileImage = c.userAvatar;
            user = routine.follower = new User();
            user.id = c.fid;
            user.name = c.followerNickname;
            user.profileImage = c.followerAvatar;
            routines.push(routine);
        }
        page.oldestId = oldest;
        if (this.append && cast(pageInfo.records, Array<Dynamic>).length == 0) {
            page.oldestId = 0;
            UiUtil.message("没有更多动态了");
        }

        var spacing = SPACING_RATIO * screenWidth;

        main.graphics.clear();
        main.rox_removeAll();

        if (routines.length == 0) {
            var label = UiUtil.staticText("暂时没有动态", 0, 24);
            main.addChild(label.rox_move((screenWidth - label.width) / 2, spacing * 2));
            return;
        }

        var yoff: Float = 0;
        for (c in routines) {
            var sp = new Sprite();
            var text = UiUtil.staticText(c.getMessage(), 0, 20, true, screenWidth - 60 - 3 * spacing);
            sp.addChild(text.rox_move(60 + 2 * spacing, spacing));
            var time = UiUtil.staticText(MyUtils.timeStr(c.createdAt), 0, 20);
            sp.addChild(time.rox_move(60 + 2 * spacing, text.height + 2 * spacing));
            var h = GameUtil.max(60 + 2 * spacing, time.height + text.height + 3 * spacing);
            sp.graphics.rox_fillRect(0x01FFFFFF, 0, 0, screenWidth, h);
            sp.graphics.rox_line(2, 0xFFEEEEEE, 0, h, screenWidth, h);
            sp.graphics.rox_drawRoundRect(1, 0xFF000000, spacing, spacing, 60, 60);
            MyUtils.asyncImage(c.follower.profileImage, function(bmd: BitmapData) {
                if (bmd == null || bmd.width == 0) bmd = ResKeeper.getAssetImage("res/no_avatar.png");
                sp.graphics.rox_drawRegionRound(bmd, spacing, spacing, 60, 60);
                sp.graphics.rox_drawRoundRect(1, 0xFF000000, spacing, spacing, 60, 60);
            });

            main.addChild(sp.rox_move(0, yoff));
            yoff += sp.height;

        }
        mainh = yoff;
    }

    private function onGesture(e: RoxGestureEvent) {
//        trace(">>>t=" + e.target+",e="+e);
        switch (e.type) {
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
                } else if (mainh > viewh && main.y < viewh - mainh) {
                    if (main.getChildByName("bottomRefresher") == null) {
                        var refresher = new Refresher("bottomRefresher", false);
                        main.addChild(refresher.rox_move(0, main.height));
                    } else if (main.y < viewh - mainh - TRIGGER_HEIGHT) {
                        cast(main.getChildByName("bottomRefresher"), Refresher).updateText();
                    }
                }
            case RoxGestureEvent.GESTURE_SWIPE:
                var pt = RoxGestureAgent.localOffset(main, cast(new Point(e.extra.x * 2.0, e.extra.y * 2.0)));
                var desty = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh, GameUtil.IMIN, 0), 0);
                if (main.y > TRIGGER_HEIGHT || main.y < viewh - mainh - TRIGGER_HEIGHT) refresh(main.y <= 0);
                e.agent.startTween(main, 1, { y: desty });
                UiUtil.delay(function() {
                    main.rox_removeByName("topRefresher");
                    main.rox_removeByName("bottomRefresher");
                }, 1);
        }
    }

    private function onButton(e: Event) {
        if (animating) return;
        switch (e.target.name) {
            case "icon_home":
                finish(SCREEN(Type.getClassName(HomeScreen)), RoxScreen.CANCELED);
            case "icon_selected":
                startScreen(Type.getClassName(SelectedScreen), PARENT);
            case "icon_maker":
                createPopups();
                if (!contains(popupbg)) {
                    addChild(popupbg);
                    doPop(1);
                }
            case "icon_message":
            case "icon_account":
                startScreen(Type.getClassName(UserScreen), PARENT);
        }
    }

    private function doPop(action: Int) {
        if (animating) return;
        animating = true;
        var pin: Sprite = switch (action) { case 1: popup1; case 2: popup2; case 3: popup1; case 4: null; }
        var pout: Sprite = switch (action) { case 1: null; case 2: popup1; case 3: popup2; case 4: popupbg.contains(popup1) ? popup1 : popup2; }
        trace("pin=" + pin+",pout=" + pout);
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
        items.push({ id: "", icon: null, name: "用照片创建小游戏", type: 1, data: null });
        items.push({ id: "jigsaw", icon: "res/icon_jigsaw_maker.png", name: "奇幻拼图", type: 3, data: null });
        items.push({ id: "swappuzzle", icon: "res/icon_swap_maker.png", name: "方块挑战", type: 3, data: null });
        items.push({ id: "slidepuzzle", icon: "res/icon_slide_maker.png", name: "移形换位", type: 3, data: null });
        items.push({ id: "", icon: null, name: "拍摄神奇魔法照片", type: 1, data: null });
        items.push({ id: "camera", icon: "res/icon_camera.png", name: "魔法相机", type: 2, data: null });
        popup1 = MyUtils.bubbleList(items, function(i: ListItem) {
            trace(i);
            switch (i.id) {
                case "camera":
                    startScreen(Type.getClassName(com.weiplus.client.HarryCamera), RoxAnimate.NO_ANIMATE);
                    fadeout(null);
                default:
                    makerId = i.id;
                    doPop(2);
            }
            return true;
        });

        items = [];
        items.push({ id: "", icon: null, name: "用照片创建小游戏", type: 1, data: null });
        items.push({ id: "local_album", icon: "res/icon_local_album.png", name: "从相册选择", type: 2, data: null });
        items.push({ id: "sys_camera", icon: "res/icon_sys_camera.png", name: "系统相机拍摄", type: 2, data: null });
        items.push({ id: "harry_camera", icon: "res/icon_harry_camera.png", name: "魔法相机拍摄", type: 2, data: null });
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
    }

    private function onHarry(_) {
        trace("onHarryCamera");
        requestCode = 3;
#if android
        HaxeStub.startHarryCamera(requestCode);
#else
        onActive(null);
#end
    }

    private function onCamera(_) {
        trace("oncamera");
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
        trace("onlocal");
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
