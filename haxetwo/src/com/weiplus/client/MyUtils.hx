package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.utils.SimpleJob;
import com.roxstudio.haxe.utils.Job;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.io.IOUtil;
import nme.utils.ByteArray;
import nme.events.Event;
import nme.display.Shape;
import com.roxstudio.haxe.ui.UiUtil;
import nme.events.MouseEvent;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.io.IOUtil;
import com.roxstudio.haxe.ui.AutoplaySprite;
import spritesheet.data.BehaviorData;
import spritesheet.data.SpritesheetFrame;
import spritesheet.Spritesheet;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.display.BitmapData;

using com.roxstudio.i18n.I18n;
using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;
using StringTools;

class MyUtils {

    public static inline var IMAGE_CACHE_DIR =
#if android
        "/sdcard/.harryphoto/image_cache";
#else
    "image_cache";
#end
    public static inline var AR_CACHE_DIR =
#if android
        "/sdcard/.harryphoto/ar_cache";
#else
    "ar_cache";
#end
    public static inline var LOADING_ANIM_NAME = "MyUtils.loadingAnim";
    public static var makerParentScreen;

    public function new() {
    }

    public static function getLoadingAnim(label: String) : Sprite {
        var sheet = ResKeeper.get("spritesheet:res/progress.png");
        if (sheet == null) {
            sheet = new Spritesheet(ResKeeper.loadAssetImage("res/progress.png"));
            var frames: Array<Int> = [];
            for (i in 0...6) {
                sheet.addFrame(new SpritesheetFrame(74 * i, 0, 74, 74));
                frames.push(i);
            }
            sheet.addBehavior(new BehaviorData("loading", frames, true, 10, 37, 37));
            ResKeeper.add("spritesheet:res/progress.png", sheet, "default");
        }
        var sp = new Sprite();
        sp.graphics.rox_fillRoundRect(0x88000000, -55, -55, 110, 110, 10);
        var prog = new AutoplaySprite(sheet);
        sp.name = LOADING_ANIM_NAME;
        prog.alpha = 0.8;
        sp.addChild(prog.rox_move(0, -13));
        var txt = UiUtil.staticText(label, 0xFFFFFF, 21);
//        var sp = new Sprite();
//        sp.addChild(prog);
        sp.addChild(txt.rox_move(-txt.width / 2, -txt.height / 2 + 39));
        return sp;
    }

#if cpp
    public static function asyncOperation<T>(data: T, asyncOp: T -> Void, ?syncOp: T -> Void, waitingLabel: String) {
        var mask = new Sprite();
        mask.graphics.rox_fillRect(0x77000000, 0, 0, RoxApp.screenWidth, RoxApp.screenHeight);
        var loading = MyUtils.getLoadingAnim(waitingLabel);
        loading.rox_move(RoxApp.screenWidth / 2, RoxApp.screenHeight / 2);
        mask.addChild(loading);
        mask.name = "loadingMask";
        RoxApp.stage.addChild(mask);
        GameUtil.worker.addJob(new SimpleJob<T>(data, asyncOp, function(data: T) {
            if (syncOp != null) syncOp(data);
            RoxApp.stage.removeChild(mask);
        }));
    }
#end

    public static function logout() {
#if (android && !testin)
        HpManager.logout();
        HpApi.instance.update({ accessToken: "", uid: "", refreshToken: "" });
#end
        clearTimelineCache();
    }

    public static function clearTimelineCache() {
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

    public static function clearImageCache() {
#if cpp
        FileUtil.rmdir(IMAGE_CACHE_DIR, true);
#end
    }

    public static function timeStr(date: Date) : String {
        var now = Date.now().getTime() / 1000;
        var time = date.getTime() / 1000;
        var dt = now - time;
        if (dt <= 60) {
            return "刚刚".i18n();
        } else if (dt <= 3600) {
            return "" + Std.int(dt / 60) + "分钟前".i18n();
        } else if (dt <= 86400) {
            return "" + Std.int(dt / 3600) + "小时前".i18n();
        } else {
            return "" + (date.getMonth() + 1) + "-" + date.getDate() + " " + date.getHours() + ":" + date.getMinutes();
        }

    }

    public inline static function isEmpty(s: String) {
        return s == null || s == "";
    }

    public static function asyncArImage(url: String, onComplete: BitmapData -> Void, ?bundleId: String) {
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            UiUtil.delay(onComplete.bind(null));
            return;
        }
#if cpp
        var img: BitmapData = ResKeeper.get(url);
        if (img != null) {
            UiUtil.delay(onComplete.bind(img));
            return;
        }
        var idx = url.lastIndexOf("/");
        var path = AR_CACHE_DIR + "/" + url.substr(idx + 1);
        trace("asyncImage: path=" + path + ",exists=" + sys.FileSystem.exists(path));
        if (sys.FileSystem.exists(path)) {
            GameUtil.worker.addJob(new com.roxstudio.haxe.utils.SimpleJob<Array<BitmapData>>([], function(d: Array<BitmapData>) {
                d[0] = ResKeeper.loadLocalImage(path);
                var map: Hash<Int> = ResKeeper.get("preloadedArMap");
                if (map.exists(url.substring(idx + 1))) {
//                    trace("file " + (url.substring(idx + 1)) + " is preloaded");
                    d[0] = ResKeeper.createArImage(d[0]);
                } else {
//                    trace("file " + (url.substring(idx + 1)) + " is not preloaded");
                }
                ResKeeper.add(url, d[0], bundleId);
            }, function(d: Array<BitmapData>) {
                onComplete(d[0]);
            }));
//            img = ResKeeper.loadLocalImage(path);
//            ResKeeper.add(url, img, bundleId);
//            UiUtil.delay(onComplete.bind(img));
            return;
        }
        UiUtil.asyncImage(url, onComplete, function(ba: ByteArray) {
            GameUtil.worker.addJob(new com.roxstudio.haxe.utils.SimpleJob<{}>(null, function(_) {
                FileUtil.mkdirs(AR_CACHE_DIR);
                sys.io.File.saveBytes(path, IOUtil.rox_toBytes(ba));
            }, function(_) {}));
        });
#else
        UiUtil.asyncImage(url, onComplete, bundleId);
#end
    }

    public static function asyncImage(url: String, onComplete: BitmapData -> Void, ?bundleId: String) {
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            UiUtil.delay(onComplete.bind(null));
            return;
        }
#if cpp
        var img: BitmapData = ResKeeper.get(url);
        if (img != null) {
            UiUtil.delay(onComplete.bind(img));
            return;
        }
        var path = IMAGE_CACHE_DIR + "/" + StringTools.urlEncode(url);
        trace("asyncImage: path=" + path + ",exists=" + sys.FileSystem.exists(path));
        if (sys.FileSystem.exists(path)) {
//            GameUtil.worker.addJob(new com.roxstudio.haxe.utils.SimpleJob<Array<BitmapData>>([], function(d: Array<BitmapData>) {
//                d[0] = ResKeeper.loadLocalImage(path);
//                ResKeeper.add(url, d[0], bundleId);
//            }, function(d: Array<BitmapData>) {
//                onComplete(d[0]);
//            }));
            img = ResKeeper.loadLocalImage(path);
            ResKeeper.add(url, img, bundleId);
            UiUtil.delay(onComplete.bind(img));
            return;
        }
        UiUtil.asyncImage(url, onComplete, function(ba: ByteArray) {
            GameUtil.worker.addJob(new com.roxstudio.haxe.utils.SimpleJob<{}>(null, function(_) {
                FileUtil.mkdirs(IMAGE_CACHE_DIR);
                sys.io.File.saveBytes(path, IOUtil.rox_toBytes(ba));
            }, function(_) {}));
        });
#else
        UiUtil.asyncImage(url, onComplete, bundleId);
#end
    }

    public static function list(items: Array<ListItem>, width: Float, onClick: ListItem -> Bool) : Sprite {
        var d2rscale = RoxApp.screenWidth / 640;
        var spacing = 16 * d2rscale;
        var fontsize = 36 * d2rscale;
        var yoff = 0.0;
        var sp = new Sprite();
        for (i in 0...items.length) {
            var item = items[i];
            var spi = new Sprite();
            var ico = item.icon != null ? UiUtil.rox_scale(UiUtil.bitmap(item.icon), d2rscale) : null;
            var txt = UiUtil.staticText(item.name, 0, fontsize);
            var h = txt.height + 2 * spacing;
            GfxUtil.rox_fillRect(spi.graphics, 0x01FFFFFF, 0, 0, width, h);
            if (i < items.length - 1) {
                GfxUtil.rox_line(spi.graphics, 2, 0xFFCACACA, 1, h - 2, width - 1, h - 2);
                GfxUtil.rox_line(spi.graphics, 2, 0xFFFFFFFF, 1, h, width - 1, h);
            }
            switch (item.type) {
                case 1:
                    if (ico != null) spi.addChild(UiUtil.rox_move(ico, spacing, (h - ico.height) / 2));
                    spi.addChild(UiUtil.rox_move(txt, spacing + (ico != null ? ico.width + spacing : 0), spacing));
                    var next = UiUtil.bitmap("res/icon_next.png");
                    spi.addChild(UiUtil.rox_move(next, width - spacing - next.width, (h - next.height) / 2));
                case 2:
                    var w2 = ico != null ? ico.width + spacing + txt.width : txt.width;
                    var xoff = (width - w2) / 2;
                    if (ico != null) spi.addChild(UiUtil.rox_move(ico, xoff, (h - ico.height) / 2));
                    spi.addChild(UiUtil.rox_move(txt, ico != null ? ico.x + ico.width + spacing : xoff, spacing));
                case 3:
                    if (ico != null) spi.addChild(UiUtil.rox_move(ico, spacing, (h - ico.height) / 2));
                    spi.addChild(UiUtil.rox_move(txt, spacing + (ico != null ? ico.width + spacing : 0), spacing));
                    var swc = UiUtil.switchControl(cast(item.data, Bool));
                    spi.addChild(UiUtil.rox_move(swc, width - spacing - swc.width, (h - swc.height) / 2));
            }
            spi.mouseEnabled = true;
            spi.addEventListener(MouseEvent.CLICK, function(_) {
                var result = onClick(item);
                if (item.type == 3 && result) {
                    spi.removeChildAt(spi.numChildren - 1); // switch control
                    item.data = !cast(item.data, Bool);
                    var swc = UiUtil.switchControl(cast(item.data, Bool));
                    spi.addChild(UiUtil.rox_move(swc, width - spacing - swc.width, (h - swc.height) / 2));
                }
            });
            sp.addChild(UiUtil.rox_move(spi, 0, yoff));
            yoff += h;
        }
        GfxUtil.rox_fillRoundRect(sp.graphics, 0xFFF7F7F7, 0, 0, width, yoff, 15 * d2rscale);
        GfxUtil.rox_drawRoundRect(sp.graphics, 2, 0xFFCACACA, 0, 0, width, yoff, 15 * d2rscale);

        return sp;
    }

    public static function bubbleList(items: Array<ListItem>, onClick: ListItem -> Bool) : Sprite {
        var d2rscale = RoxApp.screenWidth / 640;
        var width = 390 * d2rscale;
        var spacing = 20 * d2rscale;
        var labelfontsize = 20 * d2rscale;
        var itemfontsize = 34 * d2rscale;
        var labelheight = 32 * d2rscale;
        var itemheight = 80 * d2rscale;
        var backheight = labelheight + itemheight;

        var yoff = 2.0;
        var h = yoff;
        for (it in items) { h += it.type == 1 ? labelheight : it.type == 4 ? backheight : itemheight; }
        h += 2.0;
        var sp = new Sprite();
        var r = 14 * d2rscale, tailr = 14 * d2rscale;
        var gfx = sp.graphics;
        gfx.beginFill(0x2F2F2F, 1);
        gfx.moveTo(0, r);
        gfx.curveTo(0, 0, r, 0);
        gfx.lineTo(width - r, 0);
        gfx.curveTo(width, 0, width, r);
        gfx.lineTo(width, h - r);
        gfx.curveTo(width, h, width - r, h);
        gfx.lineTo(width / 2 + tailr, h);
        gfx.lineTo(width / 2, h + tailr);
        gfx.lineTo(width / 2 - tailr, h);
        gfx.lineTo(r, h);
        gfx.curveTo(0, h, 0, h - r);
        gfx.lineTo(0, r);
        gfx.endFill();

        for (i in 0...items.length) {
            var item = items[i];
            var spi = new Sprite();
            var type = item.type;
            var ico = type != 1 ? UiUtil.rox_scale(UiUtil.bitmap(item.icon), d2rscale) : null;
            var txt = item.type != 4 ? UiUtil.staticText(item.name, 0xFFFFFF, item.type == 1 ? labelfontsize : itemfontsize) : null;
            var sph = item.type == 1 ? labelheight : item.type == 4 ? backheight : itemheight;
            var backcolor = item.type == 1 ? 0xFF202020 : 0xFF2F2F2F;
            spi.graphics.rox_fillRect(0x01FFFFFF, 0, 0, width, sph); // for mouse event
            sp.graphics.rox_fillRect(backcolor, 2, yoff, width - 4, sph);
            if (i < items.length - 1 && items[i + 1].type != 1) {
                sp.graphics.rox_line(1, 0xFF222222, 2, yoff + sph - 1, width - 4, yoff + sph - 1);
                sp.graphics.rox_line(1, 0xFF3C3C3C, 2, yoff + sph, width - 4, yoff + sph);
            }
            switch (item.type) {
                case 1:
                    spi.addChild(txt.rox_move(spacing / 2, (sph - txt.height) / 2));
                case 2:
                    spi.addChild(ico.rox_move(spacing, (sph - ico.height) / 2));
                    spi.addChild(txt.rox_move(2 * spacing + ico.width, (sph - txt.height) / 2));
                case 3:
                    spi.addChild(ico.rox_move(spacing, (sph - ico.height) / 2));
                    spi.addChild(txt.rox_move(2 * spacing + ico.width, (sph - txt.height) / 2));
                    var triangle = UiUtil.bitmap("res/icon_triangle.png").rox_scale(d2rscale);
                    spi.addChild(triangle.rox_move(width - triangle.width - spacing, (sph - triangle.height) / 2));
                case 4:
                    spi.addChild(UiUtil.rox_move(ico, (width - ico.width) / 2, (sph - ico.height) / 2));
            }
            if (item.type != 1) {
                spi.mouseEnabled = true;
                spi.addEventListener(MouseEvent.CLICK, function(e: Event) {
                    onClick(item);
                    e.rox_stopPropagation();
                });
            }
            sp.addChild(UiUtil.rox_move(spi, 0, yoff));
            yoff += sph;
        }
        gfx.lineStyle(4, 0xFFFFFF, 1);
        gfx.moveTo(0, r);
        gfx.curveTo(0, 0, r, 0);
        gfx.lineTo(width - r, 0);
        gfx.curveTo(width, 0, width, r);
        gfx.lineTo(width, h - r);
        gfx.curveTo(width, h, width - r, h);
        gfx.lineTo(width / 2 + tailr, h);
        gfx.lineTo(width / 2, h + tailr);
        gfx.lineTo(width / 2 - tailr, h);
        gfx.lineTo(r, h);
        gfx.curveTo(0, h, 0, h - r);
        gfx.lineTo(0, r);
        gfx.lineStyle();
//        GfxUtil.rox_drawRoundRect(sp.graphics, 4, 0xFFFFFFFF, 0, 0, width, yoff + 2, 14 * d2rscale);

        return sp;
    }

}

typedef ListItem = {
    id: String,
    icon: String,
    name: String,
    type: Int, // 1: list_item; 2: button; 3: switch
    data: Dynamic,
}

