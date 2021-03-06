package com.weiplus.client;

import com.roxstudio.haxe.io.Unzipper;
import com.roxstudio.haxe.ui.AutoplaySprite;
import haxe.Timer;
import nme.geom.Rectangle;
import com.roxstudio.haxe.game.ResKeeper;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.io.IOUtil;
using com.roxstudio.haxe.ui.UiUtil;

class Splash extends BaseScreen {

    private var loginOk = true;

    override public function onCreate() {
        hasTitleBar = false;
        hasBack = false;
        super.onCreate();
        UiUtil.delay(doLoad, 1);
#if (android && !testin)
//        HpManager.logout();
        loginOk = HpManager.login();
//        trace("loginOk=" + loginOk + ",token=" + HpManager.getTokenAsJson());
#end
    }

    override public function drawBackground() {
        var bg = ResKeeper.loadAssetImage("res/bg_splash.jpg");
        var bgr = bg.width / bg.height, scr = screenWidth / screenHeight;
        if (bgr < scr) {
            var r = screenHeight / bg.height, marg = (screenWidth - (bg.width - 10) * r) / 2;
            graphics.rox_drawRegion(bg, new Rectangle(0, 0, 5, bg.height), 0, 0, marg, screenHeight);
            graphics.rox_drawRegion(bg, new Rectangle(5, 0, bg.width - 10, bg.height), marg, 0, (bg.width - 10) * r, screenHeight);
            graphics.rox_drawRegion(bg, new Rectangle(bg.width - 5, 0, 5, bg.height), screenWidth - marg, 0, marg, screenHeight);
        } else {
            var r = screenWidth / bg.width, marg = (screenHeight - (bg.height - 10) * r) / 2;
            graphics.rox_drawRegion(bg, new Rectangle(0, 0, bg.width, 5), 0, 0, screenWidth, marg);
            graphics.rox_drawRegion(bg, new Rectangle(0, 5, bg.width, bg.height - 10), 0, marg, screenWidth, (bg.height - 10) * r);
            graphics.rox_drawRegion(bg, new Rectangle(0, bg.height - 5, bg.width, 5), 0, screenHeight - marg, screenWidth, marg);
        }
//        var bg = ResKeeper.getAssetImage("res/bg_splash.jpg", ResKeeper.DEFAULT_BUNDLE);
//        var r = new Rectangle(0, bg.height - screenHeight / d2rScale, bg.width, screenHeight / d2rScale);
//        graphics.rox_drawRegion(bg, r, 0, 0, screenWidth, screenHeight);
//        var logo = ResKeeper.getAssetImage("res/icon_logo_big.png");
//        graphics.rox_drawRegion(logo, null, (screenWidth - logo.width * d2rScale) / 2, 0.15 * screenHeight,
//                logo.width * d2rScale, logo.height * d2rScale);
//        trace("x=" + ((w - logo.width) / 2) + ",y=" + (0.33 * h));
    }

    private function doLoad() {
//        HarryCamera.processImg(ResKeeper.getAssetImage("res/shafa.jpg"));
//        HarryCamera.processImg(ResKeeper.getAssetImage("res/huaping.jpg"));

        MyUtils.getLoadingAnim("");
#if cpp
        var cacheNames = [
                "com_weiplus_client_PublicScreen.json",
                "com_weiplus_client_SelectedScreen.json",
                "com_weiplus_client_HomeScreen.json",
                "com_weiplus_client_UserScreen.json"
        ];
        for (n in cacheNames) {
            var s = ResKeeper.loadLocalText(TimelineScreen.CACHE_DIR + "/" + n);
            if (s != null) ResKeeper.add("cache:" + n, s, ResKeeper.DEFAULT_BUNDLE);
        }
#end
        var imageNames = [
                "avatar_bg.9.png",
                "bg_input_comment.png",
                "bg_login.png",
                "bg_main.jpg",
                "bg_main_bottom.png",
                "bg_main_bottom_selected.png",
                "bg_main_top.png",
                "bg_maker_bottom.png",
                "bg_maker_bottom_selected.png",
                "bg_play.jpg",
                "bg_play_tip.png",
                "bg_play_top.png",
                "btn_back.9.png",
                "btn_common.9.png",
                "btn_dark.9.png",
                "btn_game_comment.png",
                "btn_grey.9.png",
                "btn_play.png",
                "btn_red.9.png",
                "btn_share_ml.9.png",
                "btn_share_mr.9.png",
                "btn_share_tl.9.png",
                "btn_share_tr.9.png",
                "curtain.png",
                "icon_account.png",
                "icon_bubble.png",
                "icon_comment.png",
                "icon_double_column.png",
                "icon_harry_camera.png",
                "icon_home.png",
                "icon_jigsaw_maker.png",
                "icon_login_close.png",
                "icon_maker.png",
                "icon_message.png",
                "icon_more.png",
                "icon_praise.png",
                "icon_praised.png",
                "icon_renren.png",
                "icon_renren_g.png",
                "icon_selected.png",
                "icon_settings.png",
                "icon_sina.png",
                "icon_sina_g.png",
                "icon_single_column.png",
                "icon_slide_maker.png",
                "icon_swap_maker.png",
                "icon_tencent.png",
                "icon_tencent_g.png",
                "icon_time.png",
                "icon_weixin.png",
                "icon_weixin_g.png",
                "img_flower.png",
                "img_heart.png",
                "img_star.png",
                "no_avatar.png",
                "progress.png",
                "refresh_arrow.png",
                "shadow6.9.png"
        ];
        for (n in imageNames) {
            ResKeeper.getAssetImage("res/" + n, ResKeeper.DEFAULT_BUNDLE);
        }

//        var hash = Unzipper.decompress(ResKeeper.loadAssetData("res/astroBoy_walk_Max.zip"), "");
//        for (n in hash.keys()) {
//            var data: String = cast hash.get(n);
//            sys.io.File.saveContent(n, data);
//        }

        var toScreen = loginOk ? Type.getClassName(HomeScreen) : Type.getClassName(PublicScreen);
        startScreen(toScreen, PARENT);
    }

//    private function doLoad() {
//        new TestA().foo();
//        new TestB().foo();
//        new TestC().foo();
//    }
//
}

//class TestA {
//    public var str = "aaaaaaaaaa";
//    public function new() {
//
//    }
//    public function foo() {
//        var b = new TestB();
//        var str = "bbbbbbbbb";
//        b.foo = function() { trace("str=" + str + ",this.str=" + this.str);}
//        b.foo();
//    }
//}
//
//class TestB {
//    public var str = "cccccccccccc";
//
//    public function new() {}
//    public dynamic function foo() {
//        trace("testb:" + this.str);
//    }
//}
//
//class TestC extends TestB {
//    public function new() {
//        super();
//    }
//    override public function foo() {
//        trace("testc: " + this.str);
//    }
//}