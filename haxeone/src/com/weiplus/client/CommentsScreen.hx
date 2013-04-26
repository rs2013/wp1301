package com.weiplus.client;

import nme.geom.Point;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
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

class CommentsScreen extends BaseScreen {

    private static inline var REFRESH_HEIGHT = 100;
    private static inline var TRIGGER_HEIGHT = 60;
    private static inline var SPACING_RATIO = 1 / 40;

    private var append: Bool;
    private var refreshing: Bool = false;

    private var comments: Array<Comment>;
    private var page: PageModel;
    private var main: Sprite;
    private var mainh: Float;
    private var viewh: Float;
    private var statusId: String;

    public function new() {
        super();
    }

    override public function onNewRequest(data: Dynamic) {
        statusId = cast data; // status id
        addChild(MyUtils.getLoadingAnim("载入中").rox_move(screenWidth / 2, screenHeight / 2));
        refresh(false);
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        content.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, screenWidth, h);
        main = new Sprite();

        var bg = ResKeeper.getAssetImage("res/bg_input_comment.png");
        var spacing = 0.18 * bg.height;
        var input = new Sprite();
        input.graphics.rox_bitmapFill(bg, 0, 0, screenWidth, bg.height);
        input.graphics.rox_fillRoundRect(0xFFFFFFFF, spacing, spacing, screenWidth - 2 * spacing, bg.height - 2 * spacing);
        input.graphics.rox_drawRoundRect(1, 0xFF999999, spacing, spacing, screenWidth - 2 * spacing, bg.height - 2 * spacing);
        var text = UiUtil.staticText("添加评论...", 0xBBBBBB, 24, input.width - 8);
        input.addChild(text.rox_move(spacing + 4, (input.height - text.height) / 2));
        input.mouseEnabled = true;
        input.addEventListener(MouseEvent.CLICK, function(_) {
#if android
            HaxeStub.startInputDialog("发表评论", "", "添加", this);
#else
            UiUtil.delay(function() { onApiCallback(null, "ok", "测试评论"); });
#end
        });
        main = new Sprite();
        content.addChild(main);

        var agent = new RoxGestureAgent(content);
        agent.swipeTimeout = 0;
        content.addEventListener(RoxGestureEvent.GESTURE_PAN, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onGesture);

        content.addChild(input.rox_move(0, h - input.height));
        viewh = h - input.height;
        return content;
    }

    private function onApiCallback(apiName: String, result: String, str: String) {
        if (result == "ok" && str.length > 0) {
            HpApi.instance.get("/comments/create/" + statusId, { text: str }, function(code: Int, data: Dynamic) {
                if (code == 200) {
                    UiUtil.message("评论已经添加");
                    refresh(false);
                }
            });
        }
    }

    private function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;
        if (this.append && page.oldestId - 1 <= 0) {
            UiUtil.message("没有更多评论了");
            return;
        }

        var param = { sinceId: 0, rows: 20 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get("/comments/show/" + statusId, param, onComplete);
        refreshing = true;
    }

    private function onComplete(code: Int, data: Dynamic) {
        UiUtil.rox_removeByName(this, MyUtils.LOADING_ANIM_NAME);
        refreshing = false;
        if (code != 200) {
            UiUtil.message("网络错误. code=" + code + ",message=" + data);
            return;
        }

        var pageInfo = data.comments;
        if (page == null) page = new PageModel();
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;

        if (comments == null || !this.append) comments = [];

        var oldest: Float = 999999999999.0;
        for (c in cast(pageInfo.records, Array<Dynamic>)) {
            var comment = new Comment();
            comment.id = c.id;
            var lid = Std.parseFloat(c.id);
            if (lid < oldest) oldest = lid;
            comment.text = c.text;
            comment.createdAt = Date.fromTime(c.ctime);
            var user: User = comment.user = new User();
            user.id = c.uid;
            user.name = c.userNickname;
            user.profileImage = c.userAvatar;
            user = comment.commenter = new User();
            user.id = c.cid;
            user.name = c.commenterNickname;
            user.profileImage = c.commenterAvatar;
            comments.push(comment);
        }
        page.oldestId = oldest;
        if (this.append && cast(pageInfo.records, Array<Dynamic>).length == 0) {
            page.oldestId = 0;
            UiUtil.message("没有更多评论了");
        }

        var spacing = SPACING_RATIO * screenWidth;

        main.graphics.clear();
        main.rox_removeAll();

        if (comments.length == 0) {
            var label = UiUtil.staticText("暂时没有评论", 0, 24);
            main.addChild(label.rox_move((screenWidth - label.width) / 2, spacing * 2));
            return;
        }

        var yoff: Float = 0;
        for (c in comments) {
            var sp = new Sprite();
            var name = UiUtil.staticText(c.commenter.name, 0, 20);
            sp.addChild(name.rox_move(60 + 2 * spacing, spacing));
            var time = UiUtil.staticText(MyUtils.timeStr(c.createdAt), 0, 20);
            sp.addChild(time.rox_move(screenWidth - time.width - spacing, spacing));
            var text = UiUtil.staticText(c.text, 0, 20, true, screenWidth - 60 - 3 * spacing);
            sp.addChild(text.rox_move(60 + 2 * spacing, name.height + 2 * spacing));
            var h = GameUtil.max(60 + 2 * spacing, name.height + text.height + 3 * spacing);
            sp.graphics.rox_fillRect(0x01FFFFFF, 0, 0, screenWidth, h);
            sp.graphics.rox_line(2, 0xFFEEEEEE, 0, h, screenWidth, h);
            sp.graphics.rox_drawRoundRect(1, 0xFF000000, spacing, spacing, 60, 60);
            UiUtil.asyncImage(c.commenter.profileImage, function(bmd: BitmapData) {
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

}
