package com.weiplus.client;

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

    private static inline var SPACING_RATIO = 1 / 40;

    private var append: Bool;
    private var refreshing: Bool = false;

    private var comments: Array<Comment>;
    private var page: PageModel;
    private var main: Sprite;
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
            HaxeStub.startInputDialog("发表评论", "添加", this);
#else
            UiUtil.delay(function() { onApiCallback(null, "ok", "测试评论"); });
#end
        });
        content.addChild(main);
        content.addChild(input.rox_move(0, h - input.height));
//        Reflect.
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
        for (c in cast(pageInfo.records, Array<Dynamic>)) {
            var comment = new Comment();
            comment.id = c.id;
            comment.text = c.text;
            comment.createAt = Date.fromTime(c.ctime);
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

        var spacing = SPACING_RATIO * screenWidth;
        if (comments.length == 0) {
            var label = UiUtil.staticText("暂时没有评论", 0, 24);
            main.addChild(label.rox_move((screenWidth - label.width) / 2, spacing * 2));
            return;
        }

        main.graphics.clear();
        main.rox_removeAll();
        var yoff: Float = 0;
        for (c in comments) {
            var sp = new Sprite();
            var name = UiUtil.staticText(c.commenter.name, 0, 20);
            sp.addChild(name.rox_move(60 + 2 * spacing, spacing));
            var time = UiUtil.staticText(MyUtils.timeStr(c.createAt), 0, 20);
            sp.addChild(time.rox_move(screenWidth - time.width - spacing, spacing));
            var text = UiUtil.staticText(c.text, 0, 20, true, screenWidth - 60 - 3 * spacing);
            sp.addChild(text.rox_move(60 + 2 * spacing, name.height + 2 * spacing));
            var h = GameUtil.max(60 + 2 * spacing, name.height + text.height + 3 * spacing);
            sp.graphics.rox_line(1, 0xFFEEEEEE, 0, h, screenWidth, h);
            sp.graphics.rox_drawRoundRect(1, 0xFF000000, spacing, spacing, 60, 60);
            main.addChild(sp.rox_move(0, yoff));
            yoff += sp.height;

            var ldr = new RoxURLLoader(c.commenter.profileImage, RoxURLLoader.IMAGE);
            ldr.addEventListener(Event.COMPLETE, function(_) {
                var img: BitmapData = if (ldr.status == RoxURLLoader.OK && (cast(ldr.data, BitmapData).width > 0)) {
                    cast ldr.data;
                } else {
                    ResKeeper.getAssetImage("res/no_avatar.png");
                }
                sp.graphics.rox_drawRegionRound(img, spacing, spacing, 60, 60);
                sp.graphics.rox_drawRoundRect(1, 0xFF000000, spacing, spacing, 60, 60);
            });
        }
    }

}
