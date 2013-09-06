package com.weiplus.client;

using com.roxstudio.i18n.I18n;
import nme.text.TextField;
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
            startScreen(Type.getClassName(SettingScreen));
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
            addTitleButton(btnSetting, UiUtil.RIGHT);
            removeTitleButton(btnBack);
        } else {
            addTitleButton(btnBack, UiUtil.LEFT);
            removeTitleButton(btnSetting);
        }
//#if cpp
//            restore();
//#end
//            if (storedStatuses != null && storedStatuses.length > 0) {
//                updateList(storedStatuses, false);
//            } else {
//                addChild(MyUtils.getLoadingAnim("载入中").rox_move(screenWidth / 2, screenHeight / 2));
//                refresh(false);
//            }
//            addTitleButton(btnSetting, UiUtil.RIGHT);
//        } else {
            addChild(MyUtils.getLoadingAnim("载入中".i18n()).rox_move(screenWidth / 2, screenHeight / 2));
            refresh(false);
//        }
        if (data != null || MyUtils.isEmpty(HpApi.instance.uid)) {
            UiUtil.rox_removeByName(this, "buttonPanel");
            viewh = screenHeight - titleBar.height;
        }

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
            MyUtils.asyncImage(user.profileImage, function(img: BitmapData) {
                if (img == null || img.width == 0) img = ResKeeper.getAssetImage("res/no_avatar.png");
                sp.graphics.rox_drawRegionRound(img, spacing, spacing, 60, 60);
                sp.graphics.rox_drawRoundRect(3, 0xFFFFFFFF, spacing - 1, spacing - 1, 62, 62);
            });
        }
        sp.graphics.rox_drawRegionRound(ResKeeper.getAssetImage("res/no_avatar.png"), spacing, spacing, 60, 60);
        sp.graphics.rox_drawRoundRect(3, 0xFFFFFFFF, spacing - 1, spacing - 1, 62, 62);
        if (HpApi.instance.uid != user.id) {
            var cmd = (user.friendship & 1) != 0 ? "delete" : "create";
            var txt = cmd == "create" ? "添加关注".i18n() : "取消关注".i18n();
            var btn: RoxFlowPane = UiUtil.button(UiUtil.TOP_LEFT, null, txt, 0xFFFFFF, titleFontSize * 0.7, "res/btn_common.9.png", function(e: Dynamic) {
                HpApi.instance.get("/friendships/" + cmd + "/" + user.id, {}, function(code: Int, _) {
                    var txt = cmd == "create" ? "添加关注".i18n() : "取消关注".i18n();
                    if (code == 200) {
                        UiUtil.message(StringTools.replace("已成功".i18n(), "$1", txt));
                        cmd = cmd == "create" ? "delete" : "create";
                        cast(e.target.childAt(0), TextField).text = cmd == "create" ? "添加关注".i18n() : "取消关注".i18n();
                        refresh(false);
                    } else {
                        UiUtil.message("错误,code=".i18n() + code);
                    }
                });
            });
            sp.addChild(btn.rox_move(60 + 2 * spacing, (100 - btn.height) / 2));
        }
        var arr: Array<Dynamic> = [
            [ "作品".i18n(), user.postCount, 310, null ],
            [ "关注".i18n(), user.friendCount, 420, "friends" ],
            [ "粉丝".i18n(), user.followerCount, 530, "followers" ]
        ];
        for (info in arr) {
            var label = UiUtil.staticText(info[0], 0xFFFFFF, titleFontSize * 0.8);
            var num = UiUtil.staticText("" + info[1], 0xFFFFFF, titleFontSize * 0.8);
            var panel = new Sprite();
            var gap = (100 - num.height - label.height) / 3;
            panel.graphics.rox_fillRect(0x01FFFFFF, 0, 0, 110, 100);
            panel.addChild(label.rox_move(55 - label.width / 2, gap));
            panel.addChild(num.rox_move(55 - num.width / 2, 2 * gap + label.height));
            if (info[3] != null) {
                panel.mouseEnabled = true;
                panel.addEventListener(MouseEvent.CLICK, function(_) {
//                    trace("FriendScreen, uid=" + user.id + ",type=" + info[3]);
                    startScreen(Type.getClassName(FriendsList), { user: user, type: info[3] });
                });
            }
            sp.addChild(panel.rox_move(info[2], 0));
        }
        sp.rox_scale(d2rScale);
        headPanel = sp;
        return sp;
    }

    override public function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;

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
                user.friendship = u.friendship;
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
                var txt = UiUtil.staticText(user.name, 0xFFFFFF, titleFontSize * 1.1);
                title = new Sprite();
                title.addChild(txt);
                titleBar.addChild(title.rox_move((titleBar.width / d2rScale - title.width) / 2, (titleBar.height / d2rScale - title.height) / 2));

                var param = { sinceId: 0, rows: 10 };
                if (this.append) Reflect.setField(param, "maxId", Std.int(page.oldestId - 1));
                HpApi.instance.get("/statuses/user_timeline/" + user.id, param, onComplete);
            }
        });
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
