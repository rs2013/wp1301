package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.display.Sprite;
import nme.geom.Rectangle;
import com.roxstudio.haxe.game.ResKeeper;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;
using com.weiplus.client.model.Binding;

class LoginScreen extends BaseScreen {

    override public function onCreate() {
        hasTitleBar = false;
        hasBack = false;
        super.onCreate();
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        var bg = ResKeeper.getAssetImage("res/bg_login.png");
        var h = bg.height * screenWidth / bg.width;
        content.graphics.rox_drawRegion(bg, null, 0, 0, screenWidth, h);
        var btnClose = UiUtil.button(UiUtil.TOP | UiUtil.RIGHT, "res/icon_login_close.png", function(_) {
            finish(RoxScreen.CANCELED);
        });
        content.addChild(btnClose.rox_move(screenWidth - 10, 10));

        var binds = [
        { icon: "res/icon_sina.png", id: "SINA_WEIBO", name: "新浪微博账号登陆", type: 1, data: null },
        { icon: "res/icon_tencent.png", id: "TENCENT_WEIBO", name: "腾讯微博账号登陆", type: 1, data: null },
        { icon: "res/icon_renren.png", id: "RENREN_WEIBO", name: "人人网账号登陆", type: 1, data: null },
        ];
        var spacing = 18 * d2rScale;
        var list = UiUtil.list(binds, screenWidth - 2 * spacing, onLogin);
        content.addChild(list.rox_move(spacing, h + spacing));

        return content;
    }

    private function onLogin(item: ListItem) : Bool {
#if android
        var name = item.id;
        trace("onLogin, name=" + name);
        var type = Binding.valueOf(name);
        addChild(waitingAnim("登录中"));
        HpManager.startAuth(type.id(), this);
#else
        finish(RoxScreen.OK);
#end
        return true;
    }

    private function waitingAnim(label: String) : Sprite {
        var mask = new Sprite();
        mask.graphics.rox_fillRect(0x77000000, 0, 0, screenWidth, screenHeight);
        var loading = MyUtils.getLoadingAnim(label).rox_move(screenWidth / 2, screenHeight / 2);
        mask.addChild(loading);
        mask.name = "waitingMask";
        return mask;
    }

    private function onApiCallback(apiName: String, resultCode: String, str: String) {
        trace("onApiCallback: name="+apiName+",result="+resultCode+",str="+str);
        UiUtil.rox_removeByName(this, "waitingMask"); // remove mask
        if (resultCode == "ok") {
            if (str == "ok") {
                finish(RoxScreen.OK);
            }
        } else {
            UiUtil.message("登录错误. error=" + str);
        }
    }


}
