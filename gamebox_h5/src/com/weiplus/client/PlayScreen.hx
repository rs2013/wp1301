package com.weiplus.client;

import haxe.Json;
import com.roxstudio.haxe.net.RoxURLLoader;
using com.roxstudio.i18n.I18n;
import nme.text.TextField;
import motion.easing.Linear;
import com.roxstudio.haxe.game.GameUtil;
import nme.geom.Point;
import com.roxstudio.haxe.ui.UiUtil;
import nme.display.Bitmap;
import com.roxstudio.haxe.ui.UiUtil;
import haxe.Timer;
import com.weiplus.client.MyUtils;
import nme.events.MouseEvent;
import com.roxstudio.haxe.ui.UiUtil;
import nme.display.BitmapData;
import motion.easing.Elastic;
import motion.Actuate;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.io.Unzipper;
import com.roxstudio.haxe.game.Preloader;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.RoxScreen;
import com.weiplus.client.model.Status;
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Matrix;
import nme.net.SharedObject;
import nme.utils.ByteArray;
#if cpp
import sys.FileSystem;
import sys.io.File;
#end

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.io.IOUtil;
using com.roxstudio.haxe.ui.UiUtil;
using StringTools;

class PlayScreen extends BaseScreen {

    public static inline var ZIPDATA_NAME = "playscreen_zipdata";
    public var viewWidth: Float;
    public var viewHeight: Float;

#if android
    private static inline var CACHE_DIR = "/sdcard/.harryphoto/savedgames";
#elseif windows
    private static inline var CACHE_DIR = "savedgames";
//    private static inline var CACHE_DIR = "D:/tmp/savedgames";
#end

    private static inline var SAVED_DATA_NAME = "harryphoto.savedData";
    private static inline var CACHE_EXPIRE = 2592000; // one month = 3600 * 24 * 30

    private static inline var DESIGN_WIDTH = 640;
    private static inline var TOP_HEIGHT = 86;
    private static inline var BTN_SPACING = 12;
    private static var globalSo: SharedObject;

    public var status: Status;
    private var userAvatar: BitmapData;
    private var victory: Bool = false;
    private var frontLayer: Sprite;
    private var startTime: Float;
    private var elapsedTime: Float = 0;
    private var timer: Timer;

    override public function onCreate() {
        designWidth = DESIGN_WIDTH;
        d2rScale = screenWidth / designWidth;
        designHeight = screenHeight / d2rScale;

        viewWidth = screenWidth;
        viewHeight = screenHeight;
        reset(null);
        addEventListener(Event.DEACTIVATE, onDeactive);

    }

    override public function addTitleButton(btn: RoxFlowPane, align: Int) {
        frontLayer.addChild(btn.rox_move(screenWidth - btn.width - 20, 20));
    }

    public function reset(status: Dynamic) {
        this.rox_removeAll();
        content = createContent(viewHeight);
        content.rox_move(0, 0);
        contentBg(viewWidth, viewHeight);
        addChild(content);
        frontLayer = new Sprite();
        addChild(frontLayer.rox_move(0, 0));
        victory = false;
        elapsedTime = 0;
        if (status != null) onNewRequest(status);
    }

    override public function onNewRequest(data: Dynamic) {
        this.status = cast(data);
        trace("playscreen: status=" + status);
        if (status.makerData != null) { // from maker
            this.userAvatar = ResKeeper.getAssetImage("res/no_avatar.png");
            onStart(null);
            return;
        }
        var appData = status.appData;
        var appId = appData.type + "_" + appData.id;
//        UiUtil.asyncImage(status.user.profileImage, function(bmd: BitmapData) {
//            this.userAvatar = bmd != null && bmd.width > 0 ? bmd : ResKeeper.getAssetImage("res/no_avatar.png");
//        });
        this.userAvatar = ResKeeper.getAssetImage("res/no_avatar.png");
        if (checkCache(appId)) {
            loadFromCache(appId);
        } else { // load remotely
//            fakeData();
//            loadUrl(appData.url);
            loadZip(appData.url);
        }
        var mask = new Sprite();
        mask.graphics.rox_fillRect(0x77000000, 0, 0, viewWidth, viewHeight);
        var loading = UiUtil.staticText("载入中", 0xFFFFFF, 30, UiUtil.LEFT, false, 110, 40);
        mask.addChild(loading.rox_move((viewWidth - 110) / 2, (viewHeight - 40) / 2));
//        var loading = MyUtils.getLoadingAnim("载入中".i18n());
//        loading.rox_move(viewWidth / 2, viewHeight / 2);
//        mask.addChild(loading);
        mask.name = "loadingMask";
        frontLayer.addChild(mask);
    }

    override public function onShown() {
        onResume();
    }

    override public function onHidden() {
        onPause();
        onDeactive(null);
    }

    public function contentBg(w: Float, h: Float) {
        var bmd = ResKeeper.getAssetImage("res/bg_play.jpg");
        var scalex = w / bmd.width, scaley = h / bmd.height;
        content.graphics.rox_drawImage(bmd, new Matrix(scalex, 0, 0, scaley, 0, 0), false, true, 0, 0, w, h);
    }

    public inline function getFileData(filename: String) {
        trace("getfiledata: name="+filename+",ret="+(ResKeeper.get(ZIPDATA_NAME + "/" + filename)));
        return ResKeeper.get(ZIPDATA_NAME + "/" + filename);
    }

/******************************** to be overrided *******************************/

    public function onStart(saved: Dynamic) {
        elapsedTime = saved != null && Reflect.hasField(saved, "elapsedTime") ? saved.elapsedTime : 0;
        startTimer();
    }

    public function onSave(saved: Dynamic) {}

    public function onPause() {}

    public function onResume() {}

/******************************** private methods ******************************/

    public function startTimer() {
        startTime = Timer.stamp();
        var timertf = UiUtil.button(UiUtil.TOP_LEFT, "res/icon_time.png", timestr(getElapsedTime()), 0xFFFFFF, 24);
        timertf.name = "timer";
        frontLayer.addChild(timertf.rox_move((screenWidth - timertf.width * d2rScale) / 2, 22));
        timer = new Timer(1000);
        timer.run = function() {
            cast(timertf.childAt(1), TextField).htmlText = timestr(getElapsedTime());
        }
    }

    private static inline function timestr(tm: Float) {
        var minutes = Std.int(tm / 60);
        var seconds = Std.int(tm % 60);
        return (minutes <= 10 ? "0" + minutes : "" + minutes) + ":" + (seconds <= 10 ? "0" + seconds : "" + seconds);
    }

    private static inline function timestr2(tm: Float) {
        var minutes = Std.int(tm / 60);
        var seconds = Std.int(tm % 60);
        return (minutes > 0 ? "" + minutes + "分" : "") + (seconds > 0 ? "" + seconds + "秒" : "");
    }

    public function stopTimer() {
        timer.stop();
        elapsedTime = getElapsedTime();
    }

    public function getElapsedTime() {
        return victory ? elapsedTime : Timer.stamp() - startTime + elapsedTime;
    }

    public function setVictory() {
        if (victory) return;
        stopTimer();
        victory = true;

        if (frontLayer.getChildByName("tipsbar") != null) return;
        var frontMask = new Sprite();
        frontMask.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, screenWidth, screenHeight);
        frontLayer.addChild(frontMask);
        frontMask.alpha = 0.01;
        Actuate.tween(frontMask, 0.1, { alpha: 0.7 }).repeat(1).reflect().onComplete(function() {
            frontLayer.removeChild(frontMask);
        });

        var tip = UiUtil.bitmap("res/bg_play_tip.png");
        tip.name = "tipsbar";
        tip.rox_scale(d2rScale);
        var tiph = 100 * d2rScale;
        var head = new Sprite();
        var headw = 60 * d2rScale;
        var spacing = (tiph - headw) / 2;
        head.graphics.rox_drawRegionRound(userAvatar, 0, 0, headw, headw);
        head.graphics.rox_drawRoundRect(2, 0xFFFFFFFF, 0, 0, headw, headw);
        var text = UiUtil.staticText("你太有才了！".i18n(), 0xFFFFFF, 24);
        var textx = 2 * spacing + head.width;
        var dist = textx + text.width;
        var button: RoxFlowPane = UiUtil.button(UiUtil.TOP_LEFT, null, "重玩".i18n(), 0xFFFFFF, 36, "res/btn_dark.9.png", function(_) {
            reset(status);
        });

        frontLayer.addChild(tip.rox_move(0, -tip.height));
        frontLayer.addChild(head.rox_move(spacing - dist, spacing));
        frontLayer.addChild(text.rox_move(textx - dist, (tiph - text.height) / 2));
        if (button != null) addTitleButton(button, UiUtil.RIGHT);
        Actuate.tween(tip, 0.8, { y: 0 }).ease(Elastic.easeOut);
        Actuate.tween(head, 0.8, { x: spacing }).delay(0.2).ease(Elastic.easeOut);
        Actuate.tween(text, 0.8, { x: textx }).delay(0.4).ease(Elastic.easeOut);
        if (button != null) {
            Actuate.tween(button, 0.8, { x: button.x }).delay(0.2).ease(Elastic.easeOut);
            button.x += 200;
        }
        var arr = [ "res/img_star.png", "res/img_heart.png", "res/img_flower.png" ];
        var wd2 = screenWidth / 2, hd2 = screenHeight / 2;
        var r = new Point(wd2, hd2).length;
        var idx: Array<Float> = [];
        for (i in 0...20) idx.push(i * 18 * GameUtil.D2R);
        GameUtil.shuffle(idx);
        var interval = 0.03;
        for (i in 0...idx.length) {
            var sp = UiUtil.bitmap(arr[Std.random(3)], UiUtil.CENTER);
            sp.rox_scale(0.2).rox_move(wd2, hd2);
            sp.rotation = Std.random(360);
//            frontLayer.addChild(sp);
            UiUtil.delay(function() { frontLayer.addChild(sp); }, i * interval);
            Actuate.tween(sp, 5, { x: wd2 + r * Math.cos(idx[i]), y: hd2 + r * Math.sin(idx[i]), scaleX: 1, scaleY: 1, alpha: 0 }).delay(i * interval);
            Actuate.tween(sp, 2.5, { rotation: sp.rotation + 360 }).repeat().ease(Linear.easeNone).delay(i * interval);
        }
        trace("setvictory end");
    }

    private function onApiCallback(apiName: String, result: String, str: String) {
        if (result == "ok" && str.length > 0) {
            HpApi.instance.get("/comments/create/" + status.id, { text: str }, function(code: Int, data: Dynamic) {
                if (code == 200) {
                    UiUtil.message("评论已经添加".i18n());
                }
            });
        }
    }


    private function onDeactive(_) {
        if (status.makerData != null) return;
        var saved = {};
        onSave(saved);
        untyped saved.lastUsage = Std.int(Date.now().getTime() / 1000.0);
        if (!victory) untyped saved.elapsedTime = Std.int(getElapsedTime());
        saveAndScan(saved);
    }

    private function fakeData() {
        ResKeeper.add(ZIPDATA_NAME + "/data.json", ResKeeper.loadAssetText("res/game0/data.json"));
        ResKeeper.add(ZIPDATA_NAME + "/1.png", ResKeeper.loadAssetImage("res/game0/1.png"));
        ResKeeper.add(ZIPDATA_NAME + "/tiles.png", ResKeeper.loadAssetImage("res/game0/tiles.png"));
        UiUtil.delay(function() {
            frontLayer.rox_removeByName("loadingMask"); // remove mask
            onStart(getSavedData());
        });
    }

    private function loadZip(url: String) {
        var baseurl = url.replace("/attach/", "/gametool/");
        var type = status.appData.type;
        var dataurl = baseurl + "?type=" + type + "&file=data.json";
        trace("loadZip:url="+url+",baseurl="+baseurl+",type="+type+",dataurl="+dataurl);
        new RoxURLLoader(dataurl, RoxURLLoader.TEXT, function(isOk, str) {
            trace("loadZip:>>isok="+isOk+",str="+str);
            if (!isOk) {
                UiUtil.message("游戏加载失败，请刷新重试.".i18n());
                return;
            }
            var data = Json.parse(cast str);
            ResKeeper.add(ZIPDATA_NAME + "/data.json", str);
            var imageurl = baseurl + "?type=" + type + "&file=" + data.image;
            var tilesurl = baseurl + "?type=" + type + "&file=tiles.png";
            var preloader = new Preloader([ imageurl, tilesurl ], [ ZIPDATA_NAME + "/" + data.image, ZIPDATA_NAME + "/tiles.png" ], false);
            preloader.addEventListener(Event.COMPLETE, function(_) {
                trace("loadZip.complete:imageurl="+imageurl+",tilesurl="+tilesurl);
                frontLayer.rox_removeByName("loadingMask"); // remove mask
                onStart(getSavedData());
            });
        }).start();
    }

    private function loadUrl(url: String) {
#if (flash || html5)
        var preloader = new Preloader([ url ], [ ZIPDATA_NAME ], true);
#else
        var preloader = new Preloader([ url ], [ ZIPDATA_NAME ], "playscreen_temp_bundle", false);
#end
        preloader.addEventListener(Event.COMPLETE, function(_) {
#if !(flash || html5)
            var zipdata = cast(ResKeeper.get(ZIPDATA_NAME), ByteArray);
            var files = Unzipper.decompress(zipdata, ZIPDATA_NAME + "/");
            for (id in files.keys()) ResKeeper.add(id, files.get(id));
            var dir = CACHE_DIR + "/" + status.appData.type + "_" + status.appData.id;
//            trace("dir="+dir+",exists="+FileSystem.exists(dir));
            if (!FileSystem.exists(dir)) FileUtil.mkdirs(dir);
            var filepath = dir + "/" + ZIPDATA_NAME + ".zip";
            File.saveBytes(filepath, zipdata.rox_toBytes());
            ResKeeper.disposeBundle("playscreen_temp_bundle");
#end
            frontLayer.rox_removeByName("loadingMask"); // remove mask
            onStart(getSavedData());
        } );
    }

    private inline function checkCache(dirName: String) : Bool {
#if (flash || html5)
        return false;
#else
        var filedir = CACHE_DIR + "/" + dirName;
        return FileSystem.exists(filedir);
#end
    }

    private function loadFromCache(dirName: String) {
#if cpp
        var fileurl = FileUtil.fileUrl(CACHE_DIR + "/" + dirName + "/" + ZIPDATA_NAME + ".zip");
        var preloader = new Preloader([ fileurl ], [ ZIPDATA_NAME ], true);
        preloader.addEventListener(Event.COMPLETE, function(_) {
            frontLayer.rox_removeByName("loadingMask"); // remove mask
            onStart(getSavedData());
        } );
#end
    }

    private function removeCache(dirName: String) {
#if cpp
        var filedir = CACHE_DIR + "/" + dirName;
        if (FileSystem.exists(filedir)) FileUtil.rmdir(filedir, true);
#end
    }

    private function getSavedData() : Dynamic {
        if (globalSo == null) {
            globalSo = SharedObject.getLocal(SAVED_DATA_NAME);
        }
        var appId = status.appData.type + "_" + status.appData.id;
        return Reflect.field(globalSo.data, appId);
    }

    private function saveAndScan(saved: Dynamic) {
//        trace(">>saveAndScan: saved="+saved);
        var appId = status.appData.type + "_" + status.appData.id;
        var data = globalSo.data;
        Reflect.setField(data, appId, saved);
        var now = Date.now().getTime() / 1000;
        for (id in Reflect.fields(data)) {
            var val = Reflect.field(data, id);
            if (!Reflect.hasField(val, "lastUsage")) continue;
            var lastUsage: Float = Reflect.field(val, "lastUsage");
            if (now - lastUsage <= CACHE_EXPIRE) continue; // not expired
            removeCache(id);
            Reflect.deleteField(data, id);
        }
        globalSo.flush();
//        trace(">>>flush ok, globalSo.data="+globalSo.data);
    }

}
