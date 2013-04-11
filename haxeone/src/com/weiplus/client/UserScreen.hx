package com.weiplus.client;

import nme.events.MouseEvent;
import com.weiplus.client.MyUtils;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.UiUtil;
import com.weiplus.client.MyUtils;
import com.weiplus.client.model.User;
import com.weiplus.client.TimelineScreen;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxNinePatch;
import nme.display.BitmapData;
import nme.display.Shape;
import nme.display.Sprite;
import com.weiplus.client.model.PageModel;
import nme.events.Event;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class UserScreen extends TimelineScreen {

    private var append: Bool;
    private var refreshing: Bool = false;

    private var user: User;
    private var headPanel: Sprite;
    private var btnSetting: RoxFlowPane;
//    private var lastStatuses: Array<Dynamic>;

    public function new() {
        super();
        this.screenTabIndex = 4;
        user = new User();
        compactMode = true;
    }

    override public function onCreate() {
        super.onCreate();
        btnSetting = UiUtil.button("res/icon_settings.png", null, "res/btn_common.9.png", function(_) {
            MyUtils.logout();
            startScreen(Type.getClassName(PublicScreen), CLEAR);
            UiUtil.message("你已经登出");
        });
        removeTitleButton(btnCol);
    }

#if cpp
    override private function store() {
        if (user.id == HpApi.instance.uid) {
            super.store();
        }
    }
#end

    override public function onNewRequest(data: Dynamic) {
        var uid: String = data != null ? cast data : HpApi.instance.uid;
        user.id = uid;
        if (uid == HpApi.instance.uid) {
#if cpp
            restore();
#end
            if (storedStatuses != null && storedStatuses.length > 0) {
                updateList(storedStatuses, false);
            } else {
                addChild(MyUtils.getLoadingAnim("载入中").rox_move(screenWidth / 2, screenHeight / 2));
                refresh(false);
            }
            addTitleButton(btnSetting, UiUtil.RIGHT);
        } else {
            addChild(MyUtils.getLoadingAnim("载入中").rox_move(screenWidth / 2, screenHeight / 2));
            refresh(false);
            removeTitleButton(btnSetting);
        }
        if (data != null || MyUtils.isEmpty(HpApi.instance.uid)) {
            UiUtil.rox_removeByName(this, "buttonPanel");
            viewh = screenHeight - titleBar.height;
        }

        HpApi.instance.get("/users/show/" + user.id, { }, function(code: Int, json: Dynamic) {
            if (code == 200) {
                var u = json.users[0];
                user.id = u.id;
                user.name = u.nickname;
                user.profileImage = u.avatar;
                user.createdAt = Date.fromTime(u.ctime);
                user.lastVisitAt = Date.fromTime(u.vtime);
                user.postCount = 0;
                user.friendCount = 0;
                user.followerCount = 0;
                var stats: Array<Dynamic> = u.stats;
                if (stats != null && stats.length > 0) {
                    for (stat in stats) {
                        var cnt = stat.count;
                        switch (stat.type) {
                            case "FRIENDS": user.friendCount = cnt;
                            case "FOLLOWERS": user.followerCount = cnt;
                            case "STATUSES": user.postCount = cnt;
                        }
                    }
                }

                titleBar.rox_remove(title);
                var txt = UiUtil.staticText(user.name, 0xFFFFFF, 36);
                title = new Sprite();
                title.addChild(txt);
                titleBar.addChild(title.rox_move((titleBar.width / d2rScale - title.width) / 2, (titleBar.height / d2rScale - title.height) / 2));

                main.removeChild(headPanel);
                main.addChild(getHeadPanel());

            }
        });
    }

//    override private function updateList(statuses: Array<Dynamic>, append: Bool) {
//        if (lastStatuses == null || !append) lastStatuses = [];
//        lastStatuses = lastStatuses.concat(statuses);
//        super.updateList(statuses, append);
//    }
//
    override private function getHeadPanel() : Sprite {
        var sp = new Sprite();
        var spacing = 20.0;
        sp.graphics.rox_fillRect(0xFF2F2F2F, 0, 0, designWidth, 100);
        sp.graphics.rox_line(2, 0xFF3c3c3c, 310, 0, 310, 100);
        sp.graphics.rox_line(2, 0xFF000000, 312, 0, 312, 100);
        sp.graphics.rox_line(2, 0xFF3c3c3c, 420, 0, 420, 100);
        sp.graphics.rox_line(2, 0xFF000000, 422, 0, 422, 100);
        sp.graphics.rox_line(2, 0xFF3c3c3c, 530, 0, 530, 100);
        sp.graphics.rox_line(2, 0xFF000000, 532, 0, 532, 100);
        sp.graphics.rox_line(2, 0xFFe2e2e2, 0, 100, designWidth, 100);
        if (!MyUtils.isEmpty(user.profileImage)) {
            UiUtil.asyncImage(user.profileImage, function(img: BitmapData) {
                if (img == null || img.width == 0) img = ResKeeper.getAssetImage("res/no_avatar.png");
                sp.graphics.rox_drawRegionRound(img, spacing, spacing, 60, 60);
                sp.graphics.rox_drawRoundRect(3, 0xFFFFFFFF, spacing - 1, spacing - 1, 62, 62);
            });
//            var img: BitmapData = ResKeeper.get(user.profileImage);
//            if (img != null && img.width > 0) {
//                sp.graphics.rox_drawRegionRound(img, spacing, spacing, 60, 60);
//                sp.graphics.rox_drawRoundRect(3, 0xFFFFFFFF, spacing - 1, spacing - 1, 62, 62);
//            } else {
//                sp.graphics.rox_fillRoundRect(0xFFFFFFFF, spacing - 1, spacing - 1, 62, 62);
//                var ldr = new RoxURLLoader(user.profileImage, RoxURLLoader.IMAGE);
//                ldr.addEventListener(Event.COMPLETE, function(_) {
//                    var img: BitmapData = if (ldr.status == RoxURLLoader.OK && (cast(ldr.data, BitmapData).width > 0)) {
//                        ResKeeper.add(user.profileImage, ldr.data);
//                        cast ldr.data;
//                    } else {
//                        ResKeeper.getAssetImage("res/no_avatar.png");
//                    }
//                    sp.graphics.rox_drawRegionRound(img, spacing, spacing, 60, 60);
//                    sp.graphics.rox_drawRoundRect(3, 0xFFFFFFFF, spacing - 1, spacing - 1, 62, 62);
//                });
//            }
//
//        } else {
//            sp.graphics.rox_fillRoundRect(0xFFFFFFFF, spacing - 1, spacing - 1, 62, 62);
        }
        sp.graphics.rox_drawRegionRound(ResKeeper.getAssetImage("res/no_avatar.png"), spacing, spacing, 60, 60);
        sp.graphics.rox_drawRoundRect(3, 0xFFFFFFFF, spacing - 1, spacing - 1, 62, 62);
        if (HpApi.instance.uid != user.id) {
            var btn: RoxFlowPane = UiUtil.button(UiUtil.TOP_LEFT, null, "关注", 0xFFFFFF, 24, "res/btn_common.9.png", function(_) {
                HpApi.instance.get("/friendships/create/" + user.id, {}, function(code: Int, _) {
                    if (code == 200) {
                        UiUtil.message("关注成功");
                    } else {
                        UiUtil.message("错误,code=" + code);
                    }
                });
            });
            sp.addChild(btn.rox_move(60 + 2 * spacing, (100 - btn.height) / 2));
        }
        var arr = [
            [ "作品", user.postCount, 310, null ],
            [ "关注", user.friendCount, 420, "friends" ],
            [ "粉丝", user.followerCount, 530, "followers" ]
        ];
        for (info in arr) {
            var label = UiUtil.staticText(info[0], 0xFFFFFF, 24);
            var num = UiUtil.staticText("" + info[1], 0xFFFFFF, 24);
            var panel = new Sprite();
            var gap = (100 - num.height - label.height) / 3;
            panel.graphics.rox_fillRect(0x01FFFFFF, 0, 0, 110, 100);
            panel.addChild(label.rox_move(55 - label.width / 2, gap));
            panel.addChild(num.rox_move(55 - num.width / 2, 2 * gap + label.height));
            if (info[3] != null) {
                panel.mouseEnabled = true;
                panel.addEventListener(MouseEvent.CLICK, function(_) {
                    trace("FriendScreen, uid=" + user.id + ",type=" + info[3]);
                    startScreen(Type.getClassName(FriendsList), { user: user, type: info[3] });
                });
            }
            sp.addChild(panel.rox_move(info[2], 0));
        }
        sp.rox_scale(screenWidth / designWidth);
        headPanel = sp;
        return sp;
    }

//    override private function getHeadPanel() : Sprite {
//        var shape = new Shape();
//        shape.graphics.rox_fillRoundRect(0xFFEEEEEE, 0, 0, 32, 32);
//        var bgbmd = new BitmapData(32, 32, true, 0);
//        bgbmd.draw(shape);
//        var spacing = screenWidth * TimelineScreen.SPACING_RATIO;
//        var bg = new RoxNinePatch(new RoxNinePatchData(new Rectangle(6, 6, 20, 20), new Rectangle(12, 12, 8, 8), bgbmd));
//        var panel = new RoxFlowPane(screenWidth - 2 * spacing, 100,
//                [ UiUtil.bitmap("res/no_avatar.png"), UiUtil.staticText("Leody", 0, 30) ], bg, [ 100 ]);
//        var sp = new Sprite();
//        sp.graphics.rox_fillRect(0x01FFFFFF, 0, 0, screenWidth, panel.height + spacing);
//        var pshadow = UiUtil.ninePatch("res/shadow6.9.png");
//        pshadow.setDimension(panel.width + 3, panel.height + 6);
//        panel.rox_move(spacing, spacing);
//        pshadow.rox_move(panel.x - 2, panel.y);
//        sp.addChild(pshadow);
//        sp.addChild(panel);
//        return sp;
//    }
//
    override private function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;

//#if android
//        HpManager.getUserTimeline("", nextPage, 20, 0, this);
//#else
        var param = { sinceId: 0, rows: 20 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get("/statuses/user_timeline/" + user.id, param, onComplete);
//        var ldr = new RoxURLLoader("http://s-56378.gotocdn.com/harryphoto/statuses/user_timeline/" + uid + ".json?" +
//            "sinceId=0&rows=20&refreshToken=&format=json&" +
//            (this.append ? "maxId=" + Std.int(page.oldestId - 1) + "&" : "")  +
//            "accessToken=" + accessToken, RoxURLLoader.TEXT);
//        trace("refreshUrl="+ldr.url);
//        ldr.addEventListener(Event.COMPLETE, onComplete);
        refreshing = true;
//#end
    }

    private function onComplete(code: Int, data: Dynamic) {
        refreshing = false;
        if (code != 200) return;
        var pageInfo = data.statuses;
        if (page == null) page = new PageModel();
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;
        updateList(pageInfo.records, append);
    }

}
