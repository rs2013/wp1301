package com.weiplus.client;

import com.roxstudio.haxe.ui.DipUtil;
import ru.stablex.ui.UIBuilder;
import ru.stablex.ui.widgets.Floating;
import com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.i18n.I18n;
import haxe.Json;
import com.roxstudio.haxe.ui.RoxScreenManager;
import com.roxstudio.haxe.game.GameUtil;
import nme.geom.Rectangle;
import nme.display.Shape;
import nme.text.TextField;
import nme.display.BitmapData;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Bitmap;
import com.roxstudio.haxe.ui.RoxNinePatch;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.weiplus.client.model.Status;
import nme.display.Sprite;
import com.roxstudio.haxe.ui.RoxScreen;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.ui.DipUtil;

class PostScreen extends BaseScreen {

    private static inline var SPACING = 30;

#if android
    private static inline var MAKER_DIR = "/sdcard/.harryphoto/maker";
#end

    var status: Status;
    var image: BitmapData;
    var data: Dynamic;
    var preview: Sprite;
    var input: TextField;
    var main: Sprite;
    var useBinds: Hash<Bool>;
    private var tagStr = "";

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("发布".i18n(), 0xFFFFFF, titleFontSize * 1.2));
        super.onCreate();
        graphics.rox_fillRect(0xFF2C2C2C, 0, 0, screenWidth, screenHeight);
        var btn = UiUtil.button(UiUtil.TOP_LEFT, null, "发布".i18n(), 0xFFFFFF, titleFontSize, "res/btn_red.9.png", doPost);
        addTitleButton(btn, UiUtil.RIGHT);
    }

    override public function createContent(height: Float) : Sprite {
        var content = super.createContent(height);

        useBinds = new Hash<Bool>();
        for (t in com.weiplus.client.model.Binding.allTypes()) {
            var enabled = true;
#if (android && !testin)
            enabled = HpManager.isBindingEnabled(com.weiplus.client.model.Binding.id(t));
#end
            useBinds.set(com.weiplus.client.model.Binding.id(t), enabled);
        }
//        trace("useBinds="+useBinds);

        main = new Sprite();
        var mainh = height / d2rScale;

        preview = new Sprite();
        preview.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, 320, 320);
        preview.graphics.rox_fillRect(0xFF2C2C2C, 4, 4, 312, 312);

        main.addChild(preview.rox_move((designWidth - preview.width) / 2, SPACING));

        var sharepanel = sharePanel();
        main.addChild(sharepanel.rox_move(0, mainh - sharepanel.height));

        var inputh = mainh - sharepanel.height - preview.height - 3 * SPACING;
        var shape = new Shape();
        shape.graphics.rox_fillRoundRect(0xFFFFFFFF, 0, 0, 80, 80);
        var bmd = new BitmapData(80, 80, true, 0);
        bmd.draw(shape);
        var npd = new RoxNinePatchData(new Rectangle(20, 20, 40, 40), bmd);
        input = UiUtil.staticText("", 0, titleFontSize * 0.8, UiUtil.LEFT, true, 576, inputh - 40);
        var inputbox = new RoxFlowPane(616, inputh, UiUtil.TOP_LEFT, [ input ], new RoxNinePatch(npd), function(_) {
            var text1 = "编辑内容".i18n();
            var text2 = "完成".i18n();
#if android
            HaxeStub.startInputDialog(text1, input.text, text2, this);
#end
        });

        main.addChild(inputbox.rox_move(12, preview.height + 2 * SPACING));
//        trace("inputh="+inputh+",mainh="+mainh+",inputboxh="+inputbox.height+",input=("+input.width+","+input.height
//                +"),text=("+input.textWidth+","+input.textHeight+")");

        main.rox_scale(d2rScale);
        content.addChild(main);
        return content;
    }

    override public function onNewRequest(makerData: Dynamic) {
        status = makerData.status;
        image = makerData.image.bmd;
        data = makerData.data;
//        trace("PostScreen: image.w=" + image.width + ",h=" + image.height);
        var tags: Array<String> = makerData.image.tags;
        tagStr = "";

        if (tags != null) {
            for (s in tags) tagStr += " " + s;
        }
        input.text = "#哈利波图#".i18n();
        if (status.user != null && status.text != null) { // it's retweet
            input.text = "//@" + status.user.name + " " + status.text;
        }
        var rect: Rectangle = if (image.width == image.height) {
            null;
        } else {
            var min: Float = GameUtil.min(image.width, image.height);
            new Rectangle((image.width - min) / 2, (image.height - min) / 2, min, min);
        }
        preview.graphics.rox_drawRegion(image, rect, 4, 4, 312, 312);
//        var bmp = new Bitmap(image);
//        preview.addChild(bmp);
        var type = status.appData.type;
        if (type != "image") {
            var playButton = UiUtil.button("res/btn_play.png", onPlay);
            playButton.rox_scale(0.6);
            preview.addChild(playButton);
            playButton.rox_move((preview.width - playButton.width) / 2, (preview.height - playButton.height) / 2);
        }

    }

    private function onPlay(_) {
        var classname = "com.weiplus.apps." + status.appData.type + ".App";
//        trace("play class=" + classname + ",status=" + status);
        startScreen(classname, status);
    }

    override public function onBackKey() {
        var dialog = UIBuilder.getAs("confirm_dialog", Floating);
        if (dialog != null) {
            dialog.hide();
            dialog.free();
            return false;
        }
        return true;
    }

    private function doPost(_) {
//        trace("doPost");

        if (HpApi.instance.isDefault()) {
            var dialog: Floating = null;
            dialog = cast UIBuilder.buildFn("ui/confirm_dialog.xml")( {
                    title: "登录哈利波图".i18n(), message: "请登录或使用公共账户继续。".i18n(),
                    okButtonText: "登录".i18n(), cancelButtonText: "继续".i18n(),
                    onOk: function() { startScreen(Type.getClassName(LoginScreen), 12346); dialog.free(); },
                    onCancel: function() { dialog.free(); startPost(); }
            } );
            dialog.show();

            return;
        }
        startPost();
    }

    private function startPost() {
        var text = "发布中".i18n();
#if (android && !testin)
        addChild(waitingAnim(text));
        var imgPath = MAKER_DIR + "/image.jpg";
        if (!sys.FileSystem.exists(imgPath)) imgPath = "";
        var zipPath = MAKER_DIR + "/data.zip";
        if (!sys.FileSystem.exists(zipPath)) zipPath = "";
        var types: Array<String> = [];
        for (t in useBinds.keys()) {
            if (useBinds.get(t)) types.push(t);
        }
        HpManager.postStatus(types, input.text + tagStr, imgPath, status.appData.type, zipPath, "", "", this);
#else
        onApiCallback("statuses_create", "ok", "");
#end
    }

    override public function onScreenResult(requestCode: Int, resultCode: Int, resultData: Dynamic) {
        trace("onScreenResult,resultCode=" + resultCode+",data="+resultData);
        if (requestCode == 12346 && resultCode == RoxScreen.OK) {
            UiUtil.delay(startPost);
        }
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
        switch (apiName) {
            case "statuses_create":
                if (resultCode != "ok") return;
//                var makerList: MakerList = cast manager.findScreen(Type.getClassName(MakerList));
//                var toScreen = makerList.parentScreen;
                finish(SCREEN(MyUtils.makerParentScreen != null ? MyUtils.makerParentScreen : Type.getClassName(HomeScreen)), RoxScreen.OK);
            case "startAuth":
                if (resultCode == "ok" && str == "ok") {
                    resetSharePanel();
                }
            case "startInputDialog":
                if (resultCode == "ok" && str.length > 0) {
                    input.text = str;
                }
        }
    }

    private function sharePanel() : Sprite {
        var btn0 = shareButton("sina", "新浪微博".i18n(), "tl", "SINA_WEIBO");
        var btn1 = shareButton("tencent", "腾讯微博".i18n(), "tr", "TENCENT_WEIBO");
        var btn2 = shareButton("renren", "人人网".i18n(), "ml", "RENREN_WEIBO");
        var btn3 = shareButton("weixin", "微信".i18n(), "mr", "WEIXIN");
//        var btn3 = shareButton("sohu_g", "搜狐微博", "ml");
//        var btn4 = shareButton("qqspace_g", "QQ空间", "ml");
//        var btn5 = shareButton("twit_g", "Twitter", "mr");
        var layout = new RoxNinePatchData(new Rectangle(0, 0, 20, 20));
        var lpanel = new RoxFlowPane([ btn0, btn2 ], new RoxNinePatch(layout), UiUtil.HCENTER, [ 0 ]);
        var rpanel = new RoxFlowPane([ btn1, btn3 ], new RoxNinePatch(layout), UiUtil.HCENTER, [ 0 ]);
        var sp = new Sprite();
        var label = UiUtil.staticText("同步到：".i18n(), 0x808080, titleFontSize * 0.8, UiUtil.LEFT, 610);
        sp.addChild(label.rox_move(20, 0));
        sp.addChild(lpanel.rox_move(12, label.height + 12));
        sp.addChild(rpanel.rox_move(320, label.height + 12));

//        var input = UiUtil.input(TEXT, 0, 30, UiUtil.LEFT, false, 576, 56);
//        sp.addChild(input.rox_move(20, label.height + 12 + lpanel.height + 5));
        sp.name = "sharePanel";
        return sp;
    }

    private function shareButton(icon: String, name: String, bg: String, type: String) : RoxFlowPane {
        var bg = UiUtil.ninePatch("res/btn_share_" + bg + ".9.png");
#if (android && !testin)
        var valid = (!HpApi.instance.isDefault() || type == "WEIXIN")
            && type != "" && HpManager.isBindingSessionValid(type) && useBinds.get(type);
//        trace("type=" + type + ",hasBinding=" + HpManager.hasBinding(type) + ",isValid=" + HpManager.isBindingSessionValid(type));
#else
        var valid = true;
#end
        var ico = icon != null ? new Bitmap(ResKeeper.getAssetImage("res/icon_" + icon + (valid ? "" : "_g") + ".png")).rox_smooth() : null;
        var txt = icon != null ? UiUtil.staticText(name, valid ? 0xFFFFFF : 0x666666, titleFontSize, UiUtil.LEFT, 150) : null;

        var sp = new RoxFlowPane(308, 88, UiUtil.TOP_LEFT, icon != null ? [ ico, txt ] : [],
                bg, UiUtil.VCENTER, [ 10 ], icon != null ? onShareButton : null);
        sp.name = type;
        return sp;
    }

    private function resetSharePanel() {
        var sharepanel = main.getChildByName("sharePanel");
        var y = sharepanel.y;
        main.removeChild(sharepanel);
        main.addChild(sharePanel().rox_move(0, y));
    }

    private function onShareButton(e: Dynamic) {
//        trace("share button " + e.target.name + " clicked");
        var text = "登录中".i18n();
#if (android && !testin)
        var type = e.target.name;
        if (type != "WEIXIN" && HpApi.instance.isDefault()) {
            startScreen(Type.getClassName(LoginScreen), 12346);
            return;
        }
        if (HpManager.isBindingSessionValid(type)) {
            useBinds.set(type, !useBinds.get(type));
            resetSharePanel();
            return;
        }
        addChild(waitingAnim(text));
        HpManager.startAuth(type, this);
#end
    }

}
