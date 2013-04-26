package com.weiplus.client;

import com.weiplus.apps.jigsaw.App;
import com.weiplus.apps.slidepuzzle.App;
import com.weiplus.apps.swappuzzle.App;

import com.weiplus.client.model.AppData;
import com.weiplus.client.model.User;
import com.weiplus.client.model.Status;
import com.roxstudio.haxe.io.Unzipper;
import com.roxstudio.haxe.ui.AutoplaySprite;
import com.eclecticdesignstudio.spritesheet.AnimatedSprite;
import com.eclecticdesignstudio.spritesheet.data.BehaviorData;
import com.eclecticdesignstudio.spritesheet.data.SpritesheetFrame;
import com.eclecticdesignstudio.spritesheet.Spritesheet;
import haxe.Timer;
import nme.geom.Rectangle;
import com.roxstudio.haxe.game.ResKeeper;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.io.IOUtil;
using com.roxstudio.haxe.ui.UiUtil;

class Splash extends BaseScreen {

    private var loginOk = false;

    override public function onCreate() {
        hasTitleBar = false;
        hasBack = false;
        super.onCreate();
        UiUtil.delay(doLoad, 1);
#if android
//        HpManager.logout();
        loginOk = HpManager.login();
        trace("loginOk=" + loginOk + ",token=" + HpManager.getTokenAsJson());
#end
    }

    override public function drawBackground() {
        var bg = ResKeeper.getAssetImage("res/bg_splash.jpg");
        graphics.rox_drawRegion(bg, 0, 0, screenWidth, screenHeight);
        var logo = ResKeeper.getAssetImage("res/icon_logo_big.png");
        var ratio = 0.82;
        graphics.rox_drawRegion(logo, null, (screenWidth - logo.width * ratio) / 2, 0.15 * screenHeight,
                logo.width * ratio, logo.height * ratio);
    }

    private function doLoad() {

        MyUtils.getLoadingAnim("");
        var imageNames = [
        "avatar_bg.9.png",
        "bg_play_tip.png",
        "btn_back.9.png",
        "btn_common.9.png",
        "btn_dark.9.png",
        "btn_grey.9.png",
        "btn_red.9.png",
        "icon_bubble.png",
        "icon_logo.png",
        "icon_time.png",
        "img_flower.png",
        "img_heart.png",
        "img_star.png",
        "no_avatar.png",
        "progress.png",
        "shadow6.9.png",
        "shape184.png",
        "shape_new.png"
        ];
        for (n in imageNames) {
            ResKeeper.getAssetImage("res/" + n, ResKeeper.DEFAULT_BUNDLE);
        }
#if flash
        var statusId = root.loaderInfo.parameters.id;
#else
        var statusId = "274";
#end
        trace("statusId=" + statusId);
        HpApi.instance.get("/statuses/show/" + statusId, {}, function(code: Int, data: Dynamic) {
            if (code != 200) throw "网络错误,code=" + code;
            var ss = data.statuses[0];
            var status = new Status();
            status.id = ss.id;
            status.text = ss.status;
            status.createdAt = Date.fromTime(ss.ctime);
            status.commentCount = ss.commentCount;
            status.praiseCount = ss.praiseCount;
            status.repostCount = ss.repostCount;
            status.favoriteCount = ss.favoriteCount;
            status.praised = ss.praise == 1;
            status.mark = ss.mark;

            status.user = new User();
            status.user.id = ss.uid;
            status.user.name = ss.userNickname;
            status.user.profileImage = ss.userAvatar;
            var attachments: Array<Dynamic> = ss.attachments;
            if (attachments != null && attachments.length > 0) {
                var att = attachments[0];
                status.appData = new AppData();
                status.appData.image = att.thumbUrl;
                status.appData.type = ss.gameType == null ? "image" : ss.gameType;
                status.appData.width = att.thumbWidth;
                status.appData.height = att.thumbHeight;
                status.appData.id = att.id;
                status.appData.url = att.attachUrl;
                status.appData.label = att.attachName;
            }
            var classname = "com.weiplus.apps." + status.appData.type + ".App";
            trace("classname=" + classname);
            startScreen(classname, status);
        });

    }

}
