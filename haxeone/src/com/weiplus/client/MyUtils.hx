package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.io.IOUtil;
import com.roxstudio.haxe.ui.AutoplaySprite;
import com.eclecticdesignstudio.spritesheet.data.BehaviorData;
import com.eclecticdesignstudio.spritesheet.data.SpritesheetFrame;
import com.eclecticdesignstudio.spritesheet.Spritesheet;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.display.BitmapData;

using com.roxstudio.haxe.ui.UiUtil;

class MyUtils {

    public static inline var LOADING_ANIM_NAME = "MyUtils.loadingAnim";

    public function new() {
    }

    public static function getLoadingAnim(label: String) : Sprite {
        var sheet = ResKeeper.get("spritesheet:res/progress.png");
        if (sheet == null) {
            sheet = new Spritesheet(ResKeeper.loadAssetImage("res/progress.png"));
            var frames: Array<Int> = [];
            for (i in 0...12) {
                sheet.addFrame(new SpritesheetFrame(100 * i, 0, 100, 100));
                frames.push(i);
            }
            sheet.addBehavior(new BehaviorData("loading", frames, true, 10, 50, 50));
            ResKeeper.add("spritesheet:res/progress.png", sheet, "default");
        }
        var prog = new AutoplaySprite(sheet);
        prog.name = LOADING_ANIM_NAME;
        prog.alpha = 0.6;
        var txt = UiUtil.staticText(label, 0xFFFFFF, 18);
//        var sp = new Sprite();
//        sp.addChild(prog);
        prog.addChild(txt.rox_move(-txt.width / 2, -txt.height / 2));
        return prog;
    }

    public static function logout() {
#if android
        HpManager.logout();
        HpApi.instance.update({ accessToken: "", uid: "", refreshToken: "" });
#end
#if cpp
        FileUtil.rmdir(TimelineScreen.CACHE_DIR, true);
#end
        var cacheNames = [
        "com_weiplus_client_PublicScreen.json",
        "com_weiplus_client_SelectedScreen.json",
        "com_weiplus_client_HomeScreen.json",
        "com_weiplus_client_UserScreen.json"
        ];
        for (n in cacheNames) {
            ResKeeper.remove("cache:" + n);
        }
    }

    public static function timeStr(date: Date) : String {
        var now = Date.now().getTime() / 1000;
        var time = date.getTime() / 1000;
        var dt = now - time;
        if (dt <= 60) {
            return "刚刚";
        } else if (dt <= 3600) {
            return "" + Std.int(dt / 60) + "分钟前";
        } else if (dt <= 86400) {
            return "" + Std.int(dt / 3600) + "小时前";
        } else {
            return "" + (date.getMonth() + 1) + "-" + date.getDate() + " " + date.getHours() + ":" + date.getMinutes();
        }

    }

    public inline static function isEmpty(s: String) {
        return s == null || s == "";
    }

}
