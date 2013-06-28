package com.weiplus.client;

using com.roxstudio.i18n.I18n;
import com.weiplus.client.MyUtils;
import nme.display.Shape;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class ShareSetting extends BaseScreen {

    public function new() {
        super();
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        resetContent(content);
        return content;
    }

    private function resetContent(content: Sprite) {
        content.rox_removeAll();
        var spacing = 20 * d2rScale;
        var yoff = spacing;
        var arr: Array<ListItem> = [
        { id: "SINA_WEIBO", icon: "res/icon_sina.png", name: "新浪微博".i18n(), type: 3, data: on("SINA_WEIBO") },
        { id: "TENCENT_WEIBO", icon: "res/icon_tencent.png", name: "腾讯微博".i18n(), type: 3, data: on("TENCENT_WEIBO") },
        { id: "RENREN_WEIBO", icon: "res/icon_renren.png", name: "人人网".i18n(), type: 3, data: on("RENREN_WEIBO") },
        ];
        var list = MyUtils.list(arr, screenWidth - 2 * spacing, function(i: ListItem) : Bool {
            var text = "登录中".i18n();
#if (android && !testin)
            var type = i.id;
            if (HpManager.isBindingSessionValid(type)) {
                HpManager.setBindingEnabled(type, !HpManager.isBindingEnabled(type));
                return true;
            }
            addChild(waitingAnim(text));
            HpManager.startAuth(type, this);
            return false;
#else
            return true;
#end
        });
        content.addChild(list.rox_move(spacing, yoff));
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
//        trace("onApiCallback: name="+apiName+",result="+resultCode+",str="+str);
        UiUtil.rox_removeByName(this, "waitingMask"); // remove mask
        if (resultCode == "ok") {
            if (str == "ok") {
                resetContent(content);
            }
        } else {
            UiUtil.message("登录错误. error=".i18n() + str);
        }
    }
    private static inline function on(id: String) : Bool {
#if (android && !testin)
        return HpManager.isBindingEnabled(id);
#else
        return true;
#end
    }

}
