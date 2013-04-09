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
                [ "icon_sina", "SINA_WEIBO" ],
                [ "icon_tencent", "TENCENT_WEIBO" ],
                [ "icon_renren", "RENREN_WEIBO" ] ];
        var spacing = 18 * d2rScale;
        h += spacing;
        var btnh = 90 * d2rScale;
        var btnw = 600 * d2rScale;
        var btnr = 15 * d2rScale;
        for (i in 0...binds.length) {
            var icon = binds[i][0], type = binds[i][1];
            var binding = Binding.valueOf(type);
            var btn = UiUtil.button(UiUtil.TOP_LEFT, "res/" + icon + ".png", binding.name() + "账号登录", 0, 36, null, onLogin);
            btn.name = binding.id();
            content.addChild(btn.rox_move((screenWidth - btn.width) / 2, h + btnh * i + (btnh - btn.height) / 2));
        }
        var x = (screenWidth - btnw) / 2;
        content.graphics.rox_fillRoundRect(0xFFF7F7F7, x, h, btnw, btnh * 3, btnr);
        content.graphics.rox_drawRoundRect(2, 0xFFCACACA, x, h, btnw, btnh * 3, btnr);
        content.graphics.rox_line(2, 0xFFCACACA, x + 2, h + btnh - 2, x + btnw - 2, h + btnh - 2);
        content.graphics.rox_line(2, 0xFFFFFFFF, x + 2, h + btnh, x + btnw - 2, h + btnh);
        content.graphics.rox_line(2, 0xFFCACACA, x + 2, h + 2 * btnh - 2, x + btnw - 2, h + 2 * btnh - 2);
        content.graphics.rox_line(2, 0xFFFFFFFF, x + 2, h + 2 * btnh, x + btnw - 2, h + 2 * btnh);

        return content;
    }

    private function onLogin(e: Dynamic) {
#if android
        var name = e.target.name;
        trace("onLogin, name=" + name);
        var type = Binding.valueOf(name);
        addChild(waitingAnim("登录中"));
        HpManager.startAuth(type.id(), this);
#else
        finish(RoxScreen.OK);
#end
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
