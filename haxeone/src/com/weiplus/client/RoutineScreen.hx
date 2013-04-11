package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.ui.RoxAnimate;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import nme.geom.Point;
import com.weiplus.client.model.Routine;
import com.roxstudio.haxe.ui.UiUtil;
import nme.events.MouseEvent;
import com.roxstudio.haxe.net.RoxURLLoader;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.BitmapData;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import com.roxstudio.haxe.game.GameUtil;
import com.weiplus.client.model.User;
import com.weiplus.client.model.PageModel;
import com.weiplus.client.model.Comment;
import com.roxstudio.haxe.ui.UiUtil;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class RoutineScreen extends BaseScreen {

    private static inline var REFRESH_HEIGHT = 100;
    private static inline var TRIGGER_HEIGHT = 60;
    private static inline var SPACING_RATIO = 1 / 40;

    private var append: Bool;
    private var refreshing: Bool = false;

    private var routines: Array<Routine>;
    private var page: PageModel;
    private var main: Sprite;
    private var mainh: Float;
    private var viewh: Float;
//    private var uid: String;

    public function new() {
        super();
    }

    override public function onNewRequest(data: Dynamic) {
//        uid = data != null ? cast data : HpApi.instance.uid; // user id
        addChild(MyUtils.getLoadingAnim("载入中").rox_move(screenWidth / 2, screenHeight / 2));
        refresh(false);
    }

    override public function onCreate() {
        super.onCreate();
        var btnpanel = buttonPanel();
        addChild(btnpanel.rox_move(0, screenHeight));
        viewh = screenHeight - btnpanel.height - titleBar.height;
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        content.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, screenWidth, h);
        main = new Sprite();
        content.addChild(main);

        var agent = new RoxGestureAgent(content);
        agent.swipeTimeout = 0;
        content.addEventListener(RoxGestureEvent.GESTURE_PAN, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onGesture);
        return content;
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
            UiUtil.asyncImage(c.follower.profileImage, function(bmd: BitmapData) {
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
                }, 1000);
        }
    }

    private function onButton(e: Event) {
        switch (e.target.name) {
            case "icon_home":
                finish(SCREEN(Type.getClassName(HomeScreen)), RoxScreen.CANCELED);
            case "icon_selected":
                startScreen(Type.getClassName(SelectedScreen), PARENT);
            case "icon_maker":
                var btnRect = new Rectangle(screenWidth * 0.4, screenHeight - 100, screenWidth * 0.2, 100);
                startScreen(Type.getClassName(MakerList), new RoxAnimate(RoxAnimate.ZOOM_IN, btnRect), this.className);
            case "icon_message":
                // do nothing
            case "icon_account":
                startScreen(Type.getClassName(UserScreen), PARENT);
        }
    }

}
