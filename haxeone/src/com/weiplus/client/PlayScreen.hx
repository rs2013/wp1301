package com.weiplus.client;

using com.roxstudio.i18n.I18n;
import nme.text.TextField;
import com.eclecticdesignstudio.motion.easing.Linear;
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
import com.eclecticdesignstudio.motion.easing.Elastic;
import com.eclecticdesignstudio.motion.Actuate;
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
    public var image: BitmapData;

    override public function onCreate() {
        designWidth = DESIGN_WIDTH;
        d2rScale = screenWidth / designWidth;
        designHeight = screenHeight / d2rScale;
        buttonFontSize = Std.int(32 * d2rScale);
        titleBar = UiUtil.bitmap("res/bg_play_top.png");
        titleBtnOffsetL = BTN_SPACING;
        titleBtnOffsetR = titleBar.width - BTN_SPACING;
        if (title != null) {
            titleBar.addChild(title.rox_anchor(UiUtil.CENTER).rox_move(titleBar.width / 2, titleBar.height / 2));
        }
        titleBar.rox_scale(d2rScale);
        viewWidth = screenWidth;
        viewHeight = (designHeight - TOP_HEIGHT) * d2rScale;
        content = createContent(viewHeight);
        content.rox_move(0, TOP_HEIGHT * d2rScale);
        contentBg(viewWidth, viewHeight);
        addChild(content);
        frontLayer = new Sprite();
        addChild(frontLayer.rox_move(0, TOP_HEIGHT * d2rScale));
        addChild(titleBar);
        var btnBack = UiUtil.button(UiUtil.TOP_LEFT, null, "返回".i18n(), 0xFFFFFF, titleFontSize, "res/btn_dark.9.png", function(_) { finish(RoxScreen.OK); } );
        addTitleButton(btnBack, UiUtil.LEFT);

        addEventListener(Event.DEACTIVATE, onDeactive);

    }

    override public function onNewRequest(data: Dynamic) {
        this.status = cast(data);
//        trace("playscreen: status=" + status);
        this.userAvatar = ResKeeper.getAssetImage("res/no_avatar.png");
        if (status.makerData != null) { // from maker
            onStart(null);
            return;
        }
        var appData = status.appData;
        var appId = appData.type + "_" + appData.id;
        MyUtils.asyncImage(status.user.profileImage, function(bmd: BitmapData) {
            this.userAvatar = bmd != null && bmd.width > 0 ? bmd : ResKeeper.getAssetImage("res/no_avatar.png");
        });
        getSavedData();
        if (checkCache(appId)) {
            loadFromCache(appId);
        } else { // load remotely
            loadUrl(appData.url);
        }
        var mask = new Sprite();
        mask.graphics.rox_fillRect(0x77000000, 0, 0, viewWidth, viewHeight);
        var loading = MyUtils.getLoadingAnim("载入中".i18n());
        loading.rox_move(viewWidth / 2, viewHeight / 2);
        mask.addChild(loading);
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
        frontLayer.addChild(timertf.rox_move(screenWidth - 140, 20));
        timer = new Timer(1000);
        timer.run = function() {
//            trace("" + timestr(getElapsedTime()));
            cast(timertf.childAt(1), TextField).text = timestr(getElapsedTime());
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
        return (minutes > 0 ? "" + minutes + "分".i18n() : "") + (seconds > 0 ? "" + seconds + "秒".i18n() : "");
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
        var text = UiUtil.staticText("你太有才了！".i18n(), 0xFFFFFF, buttonFontSize * 1.1);
        var textx = 2 * spacing + head.width;
        var dist = textx + text.width;
        var button: Sprite = null, buttonPic: Sprite = null;
        if (status.makerData == null && !MyUtils.isEmpty(HpApi.instance.uid)) {
            button = UiUtil.button(UiUtil.TOP_LEFT, null, "发表感受".i18n(), 0xFFFFFF, buttonFontSize * 0.7, "res/btn_dark.9.png", function(_) {
                var txt = "我用".i18n() + timestr2(getElapsedTime()) + "完成了你制作的游戏！".i18n();
                var text1 = "发表感受".i18n();
                var text2 = "发布".i18n();
#if android
                HaxeStub.startInputDialog(text1, txt, text2, this);
#else
                onApiCallback("startInputDialog", "ok", txt);
#end
            });
            onApiCallback("autoComment", "ok", "完成游戏，用时".i18n() + timestr2(getElapsedTime()));
            if (image != null) {
                buttonPic = UiUtil.button(UiUtil.TOP_LEFT, null, "查看原图".i18n(), 0xFFFFFF, buttonFontSize * 0.7, "res/btn_dark.9.png", function(_) {
                    startScreen(Type.getClassName(PictureScreen), image);
                });
            }
        }
        frontLayer.addChild(tip.rox_move(0, -tip.height));
        frontLayer.addChild(head.rox_move(spacing - dist, spacing));
        frontLayer.addChild(text.rox_move(textx - dist, (tiph - text.height) / 2));
        if (buttonPic != null) frontLayer.addChild(buttonPic.rox_move(screenWidth + spacing, (tiph - buttonPic.height) / 2));
        if (button != null) frontLayer.addChild(button.rox_move(screenWidth + 2 * spacing + button.width, (tiph - button.height) / 2));
        Actuate.tween(tip, 0.8, { y: 0 }).ease(Elastic.easeOut);
        Actuate.tween(head, 0.8, { x: spacing }).delay(0.2).ease(Elastic.easeOut);
        Actuate.tween(text, 0.8, { x: textx }).delay(0.4).ease(Elastic.easeOut);
        if (buttonPic != null) Actuate.tween(buttonPic, 0.8, { x: screenWidth - 2 * spacing - 2 * buttonPic.width }).delay(0.4).ease(Elastic.easeOut);
        if (button != null) Actuate.tween(button, 0.8, { x: screenWidth - spacing - button.width }).delay(0.2).ease(Elastic.easeOut);
        var arr = [ "res/img_star.png", "res/img_heart.png", "res/img_flower.png" ];
        var wd2 = screenWidth / 2, hd2 = (screenHeight - titleBar.height * d2rScale) / 2;
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
        UiUtil.delay(function() { startScreen(Type.getClassName(PictureScreen), image); }, 2.2);
    }

    private function onApiCallback(apiName: String, result: String, str: String) {
        if (result == "ok" && str.length > 0) {
            HpApi.instance.get("/comments/create/" + status.id, { text: str }, function(code: Int, data: Dynamic) {
                if (code == 200 && apiName != "autoComment") {
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
