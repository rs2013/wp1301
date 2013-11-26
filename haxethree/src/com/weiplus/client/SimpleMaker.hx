package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import com.weiplus.client.model.AppData;
import flash.geom.Rectangle;
using com.roxstudio.i18n.I18n;
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

    private static inline var SIDELEN: Float = 540;
    private static inline var SNAP_SIDELEN: Float = 400;
    private static inline var LEVEL_BTN_W = 213.34;

    private var viewHeight: Float;
    private var btnJigsaw: RoxFlowPane;
    private var btnSwap: RoxFlowPane;
    private var btnSlide: RoxFlowPane;
    private var btnJigsawBw: RoxFlowPane;
    private var btnSwapBw: RoxFlowPane;
    private var btnSlideBw: RoxFlowPane;
    private var btnSimple: RoxFlowPane;
    private var btnNormal: RoxFlowPane;
    private var btnHard: RoxFlowPane;
    private var levelPane: Sprite;
    private var levelBg: Sprite;
    private var level: Int = 0;
    private var preview: Sprite;
    private var snapPath: String;
    private var imageTags: Array<String>;

    private var type = "jigsaw";

    override public function createContent(height: Float) : Sprite {
        content = super.createContent(height);
        viewHeight = height;
        addTitleButton(btnNextStep, UiUtil.RIGHT);
        btnJigsaw = UiUtil.button(UiUtil.CENTER, "res/icon_jigsaw_maker.png", null, 0, 0, UiUtil.VCENTER, null);
        btnSwap = UiUtil.button(UiUtil.CENTER, "res/icon_swap_maker.png", null, 0, 0, UiUtil.VCENTER, null);
        btnSlide = UiUtil.button(UiUtil.CENTER, "res/icon_slide_maker.png", null, 0, 0, UiUtil.VCENTER, null);
        btnJigsawBw = UiUtil.button(UiUtil.CENTER, "res/icon_jigsaw_maker_bw.png", null, 0, 0, UiUtil.VCENTER, null, setType.bind(_, "jigsaw"));
        btnSwapBw = UiUtil.button(UiUtil.CENTER, "res/icon_swap_maker_bw.png", null, 0, 0, UiUtil.VCENTER, null, setType.bind(_, "swappuzzle"));
        btnSlideBw = UiUtil.button(UiUtil.CENTER, "res/icon_slide_maker_bw.png", null, 0, 0, UiUtil.VCENTER, null, setType.bind(_, "slidepuzzle"));
        btnJigsaw.name = btnJigsawBw.name = "jigsaw";
        btnJigsaw.rox_move(LEVEL_BTN_W / 2, 38);
        btnJigsawBw.rox_move(LEVEL_BTN_W / 2, 38);
        btnSwap.name = btnSwapBw.name = "swappuzzle";
        btnSwap.rox_move(LEVEL_BTN_W + LEVEL_BTN_W / 2, 38);
        btnSwapBw.rox_move(LEVEL_BTN_W + LEVEL_BTN_W / 2, 38);
        btnSlide.name = btnSlideBw.name = "slidepuzzle";
        btnSlide.rox_move(LEVEL_BTN_W * 2 + LEVEL_BTN_W / 2, 38);
        btnSlideBw.rox_move(LEVEL_BTN_W * 2 + LEVEL_BTN_W / 2, 38);
        btnSimple = UiUtil.button(UiUtil.CENTER, null, "简单".i18n(), 0xFFFFFF, titleFontSize, setLevel.bind(_, 0));
        btnNormal = UiUtil.button(UiUtil.CENTER, null, "中等".i18n(), 0xFFFFFF, titleFontSize, setLevel.bind(_, 1));
        btnHard = UiUtil.button(UiUtil.CENTER, null, "困难".i18n(), 0xFFFFFF, titleFontSize, setLevel.bind(_, 2));
        levelBg = UiUtil.bitmap("res/bg_maker_bottom_selected.png");
        var panelH = 165;
        levelPane = new Sprite();
        levelPane.addChild(UiUtil.bitmap("res/bg_maker_bottom.png"));
        levelPane.addChild(levelBg.rox_move(0, panelH - levelBg.height));
        levelPane.addChild(btnJigsaw);
        levelPane.addChild(btnSwapBw);
        levelPane.addChild(btnSlideBw);
        levelPane.addChild(btnSimple.rox_move(LEVEL_BTN_W / 2, panelH - 44));
        levelPane.addChild(btnNormal.rox_move(LEVEL_BTN_W + LEVEL_BTN_W / 2, panelH - 44));
        levelPane.addChild(btnHard.rox_move(LEVEL_BTN_W * 2 + LEVEL_BTN_W / 2, panelH - 44));
        levelPane.rox_scale(d2rScale);
        levelPane.rox_move(0, height - panelH * d2rScale);

        content.addChild(levelPane);
        preview = new Sprite();
        content.addChild(preview);
        return content;
    }

    override public function onNewRequest(inData: Dynamic) {
        trace("indata=" + inData + ",appData=" + status.appData);
        var bmd: BitmapData = inData.bmd;
        imageTags = inData.tags;
        var stdbmd = new BitmapData(SIDELEN, SIDELEN, true, 0);
        untyped data.image = stdbmd;
        var sc: Float = GameUtil.max(SIDELEN / bmd.width, SIDELEN / bmd.height);
        var xoff = (SIDELEN - sc * bmd.width) / 2, yoff = (SIDELEN - sc * bmd.height) / 2;
        stdbmd.draw(bmd, new Matrix(sc, 0, 0, sc, xoff, yoff), true);
        level = 0;
        setType(null, type);
    }

    override public function onNextStep() {
        data.size = level + 3;

        var w = Std.int(SNAP_SIDELEN);
        var img: BitmapData = data.image;
        var size: Int = data.size;
        var osl = SimpleMaker.SIDELEN / size;
        var sl = w / size;
        var shape = new Shape();
        var newimg = new BitmapData(w, w, true, 0);
        switch (type) {
        case "jigsaw":
            shape.graphics.rox_drawRegion(img, 0, 0, w, w);
            shape.graphics.rox_drawRegion(ResKeeper.loadAssetImage("res/jigsaw_mask.png"), 0, 0, w, w);
        case "slidepuzzle", "swappuzzle":
            var set: Array<Int> = [];
            if (type == "slidepuzzle") {
                for (i in 0...(size * size - 1)) set.push(i);
                set.push(-1);
                com.weiplus.apps.slidepuzzle.App.shuffle(set, size, size);
            } else {
                for (i in 0...(size * size)) set.push(i);
                GameUtil.shuffle(set);
            }
            for (i in 0...size) {
                for (j in 0...size) {
                    var idx = set[i * size + j];
                    if (idx < 0) continue;
                    shape.graphics.rox_drawRegion(img, new Rectangle(Std.int(idx / size)  * osl, Std.int(idx % size) * osl, osl, osl), j * sl, i * sl, sl, sl);
                    shape.graphics.rox_drawRect(2, 0xFFFFFFFF, j * sl + 1, i * sl + 1, sl - 1, sl - 1);
                }
            }
        }
        newimg.draw(shape);
        this.image = { path: null, bmd: newimg, tags: imageTags };
        var appdata: AppData = status.appData;
        appdata.width = w;
        appdata.height = w;
        appdata.type = this.type;

        status.makerData = data;
        super.onNextStep();
    }

    private function setType(_, type: String) {
        levelPane.rox_removeByName(this.type);
        levelPane.rox_removeByName(type);
        var addBtnBw = switch (this.type) { case "jigsaw": btnJigsawBw; case "swappuzzle": btnSwapBw; case "slidepuzzle": btnSlideBw; case _: null; }
        var addBtn = switch (type) { case "jigsaw": btnJigsaw; case "swappuzzle": btnSwap; case "slidepuzzle": btnSlide; case _: null; }
        levelPane.addChild(addBtnBw);
        levelPane.addChild(addBtn);

        this.type = type;
        setLevel(null, level);

    }

    private function setLevel(_, level: Int) {
        this.level = level;
        levelBg.x = LEVEL_BTN_W * level;
        preview.rox_removeAll();
        var bmp = new Bitmap(cast(data.image));
        bmp.smoothing = true;
        preview.addChild(bmp.rox_move(-bmp.width / 2, -bmp.height / 2));
        var xscale = screenWidth / bmp.width;
        var viewh = viewHeight - levelPane.height;
        var yscale = viewh / bmp.height;
//        trace("bmp="+bmp.width+","+bmp.height+",scale="+xscale+",yscale"+",viewh="+viewh);
        preview.rox_scale(GameUtil.min(xscale, yscale));
        preview.rox_move(screenWidth / 2, viewh / 2);
        addGrids(level + 3);
    }

    private function addGrids(n: Int) {
        if (type == "jigsaw") {
            var shape = ResKeeper.getAssetImage("res/shape_1.png");
            var top = 1, left = 1, rows = n, columns = n;
            var pw = (preview.width / preview.scaleX);
            var sideLen = pw / n;
            var maxLen = sideLen * shape.height / 184;
//        trace("sideLen="+sideLen+",maxLen="+maxLen+",scale="+preview.scaleX);
            var bottoms: Array<Int> = [];
            var grid = new Shape();
            for (i in 0...rows) {
                left = 1;
                for (j in 0...columns) {
                    var top = i == 0 ? 1 : 3 - (bottoms[j] - 2);
                    var bottom = i == rows - 1 ? 1 : Std.random(2) + 2;
                    bottoms[j] = bottom;
                    var right = j == columns - 1 ? 1 : Std.random(2) + 2;
                    var sides: Array<Int>, x: Float, y: Float;
                    sides = [ top, right, bottom, left ];
                    x = sideLen / 2 + sideLen * j;
                    y = sideLen / 2 + sideLen * i;
                    var t = com.weiplus.apps.jigsaw.Tile.getMask(shape, maxLen, sides);
//                trace("t.w="+t.width+",t.h="+t.height+",x="+x+",y="+y);
                    grid.graphics.rox_drawRegion(t, x - maxLen / 2, y - maxLen / 2);
                    left = 3 - (right - 2);
                }
            }
            preview.addChild(grid.rox_move(-pw / 2, -pw / 2));
        } else {
            var gridw = SIDELEN / n;
            var shape = new Shape();
            for (i in 0...n) {
                for (j in 0...n) {
                    if (type == "slidepuzzle" && i == j && i == n - 1) {
                        shape.graphics.rox_drawRegion(ResKeeper.getAssetImage("res/bg_main.jpg"), i * gridw + 1, j * gridw + 1, gridw, gridw);
                    } else {
                        shape.graphics.rox_drawRect(4, 0xFFFFFFFF, i * gridw + 1, j * gridw + 1, gridw - 2, gridw - 2);
                    }
                }
            }
            preview.addChild(shape.rox_move(-shape.width / 2, -shape.height / 2));
        }
    }

}
