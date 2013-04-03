package com.weiplus.client;

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

    private static inline var SPACING_RATIO = 1 / 40;

    private var append: Bool;
    private var refreshing: Bool = false;

    private var routines: Array<Routine>;
    private var page: PageModel;
    private var main: Sprite;
//    private var uid: String;

    public function new() {
        super();
    }

    override public function onNewRequest(data: Dynamic) {
//        uid = data != null ? cast data : HpApi.instance.uid; // user id
        addChild(MyUtils.getLoadingAnim("载入中").rox_move(screenWidth / 2, screenHeight / 2));
        refresh(false);
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        content.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, screenWidth, h);
        main = new Sprite();

        content.addChild(main);

        return content;
    }

    private function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;

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
        for (c in cast(pageInfo.records, Array<Dynamic>)) {
            var routine = new Routine();
            routine.id = c.id;
            routine.type = c.type;
            routine.oid = c.oid;
            routine.digest = c.digest;
            routine.createAt = Date.fromTime(c.ctime);
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

        var spacing = SPACING_RATIO * screenWidth;
        if (routines.length == 0) {
            var label = UiUtil.staticText("暂时没有动态", 0, 24);
            main.addChild(label.rox_move((screenWidth - label.width) / 2, spacing * 2));
            return;
        }

        main.graphics.clear();
        main.rox_removeAll();
        var yoff: Float = 0;
        for (c in routines) {
            var sp = new Sprite();
            var text = UiUtil.staticText(c.getMessage(), 0, 20, true, screenWidth - 60 - 3 * spacing);
            sp.addChild(text.rox_move(60 + 2 * spacing, spacing));
            var time = UiUtil.staticText(MyUtils.timeStr(c.createAt), 0, 20);
            sp.addChild(time.rox_move(60 + 2 * spacing, text.height + 2 * spacing));
            var h = GameUtil.max(60 + 2 * spacing, time.height + text.height + 3 * spacing);
            sp.graphics.rox_line(1, 0xFFEEEEEE, 0, h, screenWidth, h);
            sp.graphics.rox_drawRoundRect(1, 0xFF000000, spacing, spacing, 60, 60);
            main.addChild(sp.rox_move(0, yoff));
            yoff += sp.height;

            var ldr = new RoxURLLoader(c.follower.profileImage, RoxURLLoader.IMAGE);
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
