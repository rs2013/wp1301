package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import nme.display.Shape;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class SettingScreen extends BaseScreen {
    private var starttm: Float;

    public function new() {
        super();
        starttm = haxe.Timer.stamp();
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        var spacing = 20 * d2rScale;
        var yoff = spacing;
        var arr: Array<ListItem> = [];
        arr.push({ id: "share", icon: null, name: "分享设置", type: 1, data: null });
        var list = UiUtil.list(arr, screenWidth - 2 * spacing, function(i: ListItem) : Bool {
            startScreen(Type.getClassName(ShareSetting));
            return true;
        });
        content.addChild(list.rox_move(spacing, yoff));
        yoff += list.height + spacing;

        arr = [];
        arr.push({ id: "umeng_xp", icon: null, name: "推荐应用", type: 1, data: null });
        arr.push({ id: "umeng_fb", icon: null, name: "意见反馈", type: 1, data: null });
        list = UiUtil.list(arr, screenWidth - 2 * spacing, function(i: ListItem) : Bool {
#if android
            switch (i.id) {
                case "umeng_xp": HaxeStub.startUmengXp();
                case "umeng_fb": HaxeStub.startUmengFb();
            }
#end
            return true;
        });
        content.addChild(list.rox_move(spacing, yoff));
        yoff += list.height + spacing;

        arr = [];
        arr.push({ id: "logoff", icon: null, name: "注销登录", type: 2, data: null });
        var list = UiUtil.list(arr, screenWidth - 2 * spacing, function(i: ListItem) : Bool {
            MyUtils.logout();
            startScreen(Type.getClassName(PublicScreen), CLEAR);
            UiUtil.message("你已经登出");
            return true;
        });
        content.addChild(list.rox_move(spacing, yoff));
        return content;
    }

    override public function onNewRequest(_) {
        trace("SettingScreen started, time=" + (haxe.Timer.stamp() - starttm));
    }

}
