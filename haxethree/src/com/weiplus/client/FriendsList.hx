package com.weiplus.client;

using com.roxstudio.i18n.I18n;
import nme.text.TextField;
import com.weiplus.client.model.Friendship;
import com.weiplus.client.model.User;
import com.weiplus.client.model.PageModel;
import com.weiplus.client.model.Comment;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.game.GameUtil;
import nme.display.Sprite;
import nme.display.BitmapData;
import nme.geom.Point;
import nme.geom.Rectangle;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class FriendsList extends BaseScreen {

    private static inline var REFRESH_HEIGHT = 100;
    private static inline var TRIGGER_HEIGHT = 60;
    private static inline var SPACING_RATIO = 1 / 40;

    private var append: Bool;
    private var refreshing: Bool = false;

    private var list: Array<Friendship>;
    private var page: PageModel;
    private var main: Sprite;
    private var mainh: Float;
    private var viewh: Float;
    private var user: User;
    private var type: String;
    private var isOwner: Bool;
    var agent: RoxGestureAgent;

    public function new() {
        super();
    }

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("好友列表".i18n(), 0xFFFFFF, titleFontSize * 1.2));
        super.onCreate();
    }

    override public function onNewRequest(data: Dynamic) {
        user = data.user;
        type = data.type;
        cast(title.getChildAt(0), TextField).text = type == "friends" ? "关注列表".i18n() : "粉丝列表".i18n();
        isOwner = !MyUtils.isEn() && !HpApi.instance.isDefault() && HpApi.instance.uid == user.id;
        addChild(MyUtils.getLoadingAnim("载入中".i18n()).rox_move(screenWidth / 2, screenHeight / 2));
        refresh(false);
    }

    override public function onTitleClicked() {
        super.onTitleClicked();
        agent.startTween(main, 1, { y: 0 });
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        content.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, screenWidth, h);
        main = new Sprite();
        content.addChild(main);

        viewh = h;

        agent = new RoxGestureAgent(content);
        agent.swipeTimeout = 0;
        content.addEventListener(RoxGestureEvent.GESTURE_PAN, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onGesture);
        return content;
    }

    private function refresh(append: Bool) {
        if (refreshing) return;

        this.append = append && page != null;
        if (this.append && page.oldestId - 1 <= 0) {
            return;
        }

        refreshing = true;
        var param = { sinceId: 0, rows: 20 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get("/friendships/" + type + "/" + user.id, param, onComplete);
    }

    private function onComplete(code: Int, data: Dynamic) {
        UiUtil.rox_removeByName(this, MyUtils.LOADING_ANIM_NAME);
        if (code != 200) {
            UiUtil.message("网络错误. code=".i18n() + code + ",message=" + data);

            refreshing = false;
            return;
        }

        var pageInfo = data.friendships;
        if (page == null) page = new PageModel();
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;

        if (list == null || !this.append) list = [];

        var oldest: Float = 999999999999.0;
        for (c in cast(pageInfo.records, Array<Dynamic>)) {
            var fs = new Friendship();
            fs.id = c.id;
            var lid = Std.parseFloat(c.id);
            if (lid < oldest) oldest = lid;
            fs.uid = c.uid;
            fs.name = c.userNickname;
            fs.avatar = c.userAvatar;
            fs.fid = c.fid;
            fs.friendName = c.friendNickname;
            fs.friendAvatar = c.friendAvatar;
            fs.status = c.status;
            fs.bilateral = c.bilateral == 1;
            fs.createdAt = Date.fromTime(c.ctime);
            list.push(fs);
        }
        page.oldestId = oldest;
        if (this.append && cast(pageInfo.records, Array<Dynamic>).length == 0) {
            page.oldestId = 0;
        }

        var spacing = SPACING_RATIO * screenWidth;

        main.graphics.clear();
        main.rox_removeAll();

        if (list.length == 0) {
            var name = isOwner ? "您".i18n() : user.name;
            var label = UiUtil.staticText(name +
                (type == "friends" ? "尚未关注任何人".i18n() : "目前还没有粉丝".i18n()), 0, buttonFontSize);
            main.addChild(label.rox_move((screenWidth - label.width) / 2, spacing * 2));

            refreshing = false;
            return;
        }

        var yoff: Float = 0;
        for (c in list) {
            var sp = new Sprite();
            var h = 60 + 2 * spacing;
            var fid = c.fid, avatar = c.friendAvatar, name = c.friendName;
            if (type == "followers") {
                fid = c.uid;
                avatar = c.avatar;
                name = c.name;
            }
            var text = UiUtil.staticText(name, 0, buttonFontSize * 0.9);
            sp.addChild(text.rox_move(60 + 2 * spacing, (h - text.height) / 2));
            if (isOwner) {
                var label = (type == "friends" || c.bilateral) ? "取消关注".i18n() : "添加关注".i18n();
                var btn = UiUtil.button(UiUtil.TOP_LEFT, null, label, 0, buttonFontSize * 0.8, "res/btn_grey.9.png", function(_) {
                    var cmd = type == "friends" || c.bilateral ? "delete" : "create";
//                    trace("update friendship: cmd=" + cmd + ",fid=" + fid + ",fname=" + (type == "friends" ? c.friendName : c.name));
                    HpApi.instance.get("/friendships/" + cmd + "/" + fid, {}, function(code: Int, data: Dynamic) {
                        var msg = if (code == 200) {
                            refresh(false);
                            "关系更新成功".i18n();
                        } else {
                            "网络错误，code=".i18n() + code;
                        }
                        UiUtil.message(msg);
                    });
                });
                sp.addChild(btn.rox_move(screenWidth - btn.width - spacing, (h - btn.height) / 2));
            }
            sp.graphics.rox_fillRect(0x01FFFFFF, 0, 0, screenWidth, h);
            sp.graphics.rox_line(2, 0xFFEEEEEE, 0, h, screenWidth, h);

            var head = new Sprite();
            head.graphics.rox_drawRoundRect(2, 0xFF000000, 0, 0, 60, 60);
            MyUtils.asyncImage(avatar, function(bmd: BitmapData) {
                if (bmd == null || bmd.width == 0) bmd = ResKeeper.getAssetImage("res/no_avatar.png");
                head.graphics.rox_drawRegionRound(bmd, 0, 0, 60, 60);
                head.graphics.rox_drawRoundRect(2, 0xFF000000, 0, 0, 60, 60);
            });
            head.rox_onClick(function(_) {
                startScreen(Type.getClassName(UserScreen), "UserScreen_" + fid, null, null, 1, fid);
            });
            sp.addChild(head.rox_move(spacing, spacing));

            main.addChild(sp.rox_move(0, yoff));
            yoff += sp.height;

        }
        mainh = yoff;
        main.graphics.rox_fillRect(0x01FFFFFF, 0, 0, main.width, mainh); // for gesture

        refreshing = false;
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
