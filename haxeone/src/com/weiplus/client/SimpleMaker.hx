package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxFlowPane;
import nme.display.Shape;
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Matrix;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class SimpleMaker extends MakerScreen {

    private static inline var ALBUM_DIR = "/sdcard/DCIM/Camera";
    public static inline var SIDELEN: Float = 900;
    private static inline var LEVEL_BTN_W = 213.34;

    private var requestCode = -1;
    private var viewHeight: Float;
    private var btnHarry: RoxFlowPane;
    private var btnCamera: RoxFlowPane;
    private var btnLocal: RoxFlowPane;
    private var btnReset: RoxFlowPane;
    private var btnSimple: RoxFlowPane;
    private var btnNormal: RoxFlowPane;
    private var btnHard: RoxFlowPane;
    private var levelPane: Sprite;
    private var levelBg: Sprite;
    private var level: Int = 0;
    private var preview: Sprite;
    private var snapPath: String;

    override public function createContent(height: Float) : Sprite {
        content = super.createContent(height);
        viewHeight = height;
        btnHarry = UiUtil.button(UiUtil.CENTER, null, "魔法相机", 0xFFFFFF, 50, "res/btn_common.9.png", onHarry);
        btnCamera = UiUtil.button(UiUtil.CENTER, null, "系统相机", 0xFFFFFF, 50, "res/btn_common.9.png", onCamera);
        btnLocal = UiUtil.button(UiUtil.CENTER, null, "本地图库", 0xFFFFFF, 50, "res/btn_common.9.png", onLocal);
        btnReset = UiUtil.button(UiUtil.TOP_LEFT, null, "重新选择", 0xFFFFFF, 36, "res/btn_common.9.png", setSelectUI);
        btnSimple = UiUtil.button(UiUtil.CENTER, null, "简单", 0xFFFFFF, 36, function(_) { setLevel(0); });
        btnNormal = UiUtil.button(UiUtil.CENTER, null, "中等", 0xFFFFFF, 36, function(_) { setLevel(1); });
        btnHard = UiUtil.button(UiUtil.CENTER, null, "困难", 0xFFFFFF, 36, function(_) { setLevel(2); });
        levelBg = UiUtil.bitmap("res/bg_maker_bottom_selected.png");
        var levelPaneH = levelBg.height;
        levelPane = new Sprite();
        levelPane.addChild(UiUtil.bitmap("res/bg_maker_bottom.png"));
        levelPane.addChild(levelBg);
        levelPane.addChild(btnSimple.rox_move(LEVEL_BTN_W / 2, levelPaneH / 2));
        levelPane.addChild(btnNormal.rox_move(LEVEL_BTN_W + LEVEL_BTN_W / 2, levelPaneH / 2));
        levelPane.addChild(btnHard.rox_move(LEVEL_BTN_W * 2 + LEVEL_BTN_W / 2, levelPaneH / 2));
        levelPane.rox_scale(d2rScale);
        levelPane.rox_move(0, height - levelPaneH * d2rScale);

        preview = new Sprite();

        setSelectUI(null);

//        this.addEventListener(Event.DEACTIVATE, onDeactive);
        this.addEventListener(Event.ACTIVATE, onActive);
        return content;
    }

    private function setSelectUI(_) {
        removeTitleButton(btnReset);
        removeTitleButton(btnNextStep);
        content.rox_remove(preview);
        content.rox_remove(levelPane);

        content.addChild(btnHarry.rox_move(screenWidth / 2, viewHeight / 2 - 180));
        content.addChild(btnCamera.rox_move(screenWidth / 2, viewHeight / 2));
        content.addChild(btnLocal.rox_move(screenWidth / 2, viewHeight / 2 + 180));
    }

    private function setImageUI() {
        content.rox_remove(btnHarry);
        content.rox_remove(btnCamera);
        content.rox_remove(btnLocal);
        addTitleButton(btnNextStep, UiUtil.RIGHT);
        addTitleButton(btnReset, UiUtil.RIGHT);
        content.addChild(levelPane);
        setLevel(0);
        content.addChild(preview);
    }

    private function setLevel(level: Int) {
        this.level = level;
        levelBg.x = LEVEL_BTN_W * level;
        preview.rox_removeAll();
        var bmp = new Bitmap(cast(data.image));
        bmp.smoothing = true;
        preview.addChild(bmp.rox_move(-bmp.width / 2, -bmp.height / 2));
        var xscale = screenWidth / bmp.width;
        var viewh = viewHeight - levelPane.height;
        var yscale = viewh / bmp.height;
        preview.rox_scale(GameUtil.min(xscale, yscale));
        preview.rox_move(screenWidth / 2, viewh / 2);
    }

    private function addGrids(n: Int) {
        var gridw = SIDELEN / n;
        var shape = new Shape();
        for (i in 0...n) {
            for (j in 0...n) {
                shape.graphics.rox_drawRect(4, 0xFFFFFFFF, i * gridw + 1, j * gridw + 1, gridw - 2, gridw - 2);
            }
        }
        preview.addChild(shape.rox_move(-shape.width / 2, -shape.height / 2));
    }

    private function onActive(_) {
        if (requestCode < 0) return;
#if android
        var s = HaxeStub.getResult(requestCode);
        var json: Dynamic = haxe.Json.parse(s);
        trace("))))))))))))) active, requestCode=" + requestCode + ",result=" + s + ",parsed=" + json);
        if (untyped json.resultCode != "ok") return;
        var path = requestCode == 1 ? snapPath : untyped json.intentDataPath;
//        path = StringTools.replace(path, "\\/", "/");
        var bmd = ResKeeper.loadLocalImage(path);
#else
        var bmd = ResKeeper.loadAssetImage("res/data/11.jpg");
#end
        requestCode = -1;
        var stdbmd = new BitmapData(SIDELEN, SIDELEN, true, 0);
        untyped data.image = stdbmd;
        var xscale = SIDELEN / bmd.width, yscale = SIDELEN / bmd.height;
        var sc: Float = GameUtil.max(xscale, yscale);
        var xoff = (SIDELEN - sc * bmd.width) / 2, yoff = (SIDELEN - sc * bmd.height) / 2;
        stdbmd.draw(bmd, new Matrix(sc, 0, 0, sc, xoff, yoff), true);
        setImageUI();
    }

//    private function onDeactive(_) {
//        trace("))))))))))))) deactive");
//    }

    private function onHarry(_) {
        trace("onHarryCamera");
        requestCode = 3;
#if android
        HaxeStub.startHarryCamera(requestCode);
#else
        onActive(null);
#end
    }

    private function onCamera(_) {
        trace("oncamera");
        requestCode = 1;
#if android
        if (!sys.FileSystem.exists(ALBUM_DIR)) com.roxstudio.haxe.io.FileUtil.mkdirs(ALBUM_DIR);
        var name = "harryphoto_" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
        snapPath = ALBUM_DIR + "/" + name;
        HaxeStub.startImageCapture(requestCode, snapPath);
#else
        onActive(null);
#end
    }

    private function onLocal(_) {
        trace("onlocal");
//        if (!FileSystem.exists(ALBUM_DIR)) FileUtil.mkdirs(ALBUM_DIR);
//        var name = "" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
        requestCode = 2;
#if android
        HaxeStub.startGetContent(requestCode, "image/*");
#else
        onActive(null);
#end
    }
}
