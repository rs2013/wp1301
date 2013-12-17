package com.weiplus.client;

import Reflect;
import flash.net.SharedObject;
import ru.stablex.ui.UIBuilder;
import ru.stablex.ui.widgets.Floating;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxScreen;
using com.roxstudio.i18n.I18n;
import com.weiplus.client.MyUtils;
import nme.display.Shape;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.ui.DipUtil;

class SettingScreen extends BaseScreen {

    public static inline var SHARED_OBJECT_NAME = "harryphoto.settings";
    private static var settingsSo: SharedObject;

    private var starttm: Float;

    public function new() {
        super();
        starttm = haxe.Timer.stamp();
        settingsSo = SharedObject.getLocal(SHARED_OBJECT_NAME);
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        var spacing = 20 * d2rScale;
        var yoff = spacing;
        var arr: Array<ListItem> = null;
        var list: Sprite = null;

        if (!MyUtils.isEn()) {
            arr = [];
            arr.push({ id: "share", icon: null, name: "分享设置".i18n(), type: 1, data: null });
            list = MyUtils.list(arr, screenWidth - 2 * spacing, function(i: ListItem) : Bool {
                startScreen(Type.getClassName(ShareSetting));
                return true;
            });
            content.addChild(list.rox_move(spacing, yoff));
            yoff += list.height + spacing;
        }

        arr = [];
        var autoUpdate = !Reflect.hasField(settingsSo.data, "autoUpdateAr") || settingsSo.data.autoUpdateAr;
        arr.push({ id: "auto_update_ar", icon: null, name: "Wifi下自动更新魔贴".i18n(), type: 3, data: autoUpdate });
        arr.push({ id: "force_update_ar", icon: null, name: "立即检测更新魔贴".i18n(), type: 1, data: null });
//        arr.push({ id: "umeng_xp", icon: null, name: "推荐应用".i18n(), type: 1, data: null });
        arr.push({ id: "umeng_fb", icon: null, name: "意见反馈".i18n(), type: 1, data: null });
        arr.push({ id: "clear_image_cache", icon: null, name: "清除图片缓存".i18n(), type: 1, data: null });
        arr.push({ id: "about", icon: null, name: "关于哈利波图(Beta)".i18n(), type: 1, data: null });
        list = MyUtils.list(arr, screenWidth - 2 * spacing, function(i: ListItem) : Bool {
            switch (i.id) {
                case "auto_update_ar":
                    autoUpdate = !autoUpdate;
                    settingsSo.data.autoUpdateAr = autoUpdate;
                    settingsSo.flush();
                case "force_update_ar":
                    MagicEditor.updateAr();
#if android
                case "umeng_xp": HaxeStub.startUmengXp();
                case "umeng_fb": HaxeStub.startUmengFb();
#end
                case "clear_image_cache":
                    UiUtil.message("开始清除，请稍候".i18n());
                    MyUtils.clearImageCache();
                    UiUtil.message("图片缓存已清除".i18n());
                case "about":
//                    UiUtil.message("迈吉客科技（上海）有限公司".i18n());
                    var dialog: Floating = null;
                    dialog = cast UIBuilder.buildFn("ui/alert_dialog.xml")( {
                        title: "关于哈利波图(Beta)".i18n(),
                        message: "ABOUT".i18n()
                    } );
                    dialog.show();
            }
            return true;
        });
        content.addChild(list.rox_move(spacing, yoff));
        yoff += list.height + spacing;

        if (!MyUtils.isEn()) {
            arr = [];
            arr.push({ id: "logoff", icon: null, name: "注销当前账户".i18n(), type: 2, data: null });
            var list = MyUtils.list(arr, screenWidth - 2 * spacing, function(i: ListItem) : Bool {
                switch (i.id) {
                    case "logoff":
                        MyUtils.logout();
#if (android && !testin)
                HpManager.login(); // use default account
#end
                        startScreen(Type.getClassName(HomeScreen), CLEAR);
//                UiUtil.message("你已经登出".i18n());
                }
                return true;
            });
            content.addChild(list.rox_move(spacing, yoff));
        }
        return content;
    }

    override public function onBackKey() {
        var dialog = UIBuilder.getAs("alert_dialog", Floating);
        if (dialog != null) {
            dialog.hide();
            dialog.free();
            return false;
        }
        return true;
    }

    override public function onNewRequest(_) {
//        trace("SettingScreen started, time=" + (haxe.Timer.stamp() - starttm));
    }

    override public function onScreenResult(requestCode: Int, resultCode: Int, resultData: Dynamic) {
//        trace("publicscreen.onScreenResult:request=" + requestCode + ",result=" + resultCode + ",data=" + resultData);
        if (requestCode == 12346 && resultCode == RoxScreen.OK) {
            UiUtil.delay(finish.bind(SCREEN(Type.getClassName(HomeScreen)), null, RoxScreen.CANCELED, null));
        }
    }

}
