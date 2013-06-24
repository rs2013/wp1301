package com.weiplus.apps.jigsaw;

import nme.geom.Rectangle;
import nme.display.Shape;
import com.roxstudio.haxe.game.ResKeeper;
import com.weiplus.client.model.AppData;
import com.weiplus.client.SimpleMaker;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.geom.Matrix;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class Maker extends SimpleMaker {

    override private function setLevel(level: Int) {
        super.setLevel(level);
        untyped data.size = level + 3;
        addGrids(level + 3);
    }

    override private function addGrids(n: Int) {
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
                var t = Tile.getMask(shape, maxLen, sides);
//                trace("t.w="+t.width+",t.h="+t.height+",x="+x+",y="+y);
                grid.graphics.rox_drawRegion(t, x - maxLen / 2, y - maxLen / 2);
                left = 3 - (right - 2);
            }
        }
        preview.addChild(grid.rox_move(-pw / 2, -pw / 2));
    }

    override public function onNextStep() {
        var w = Std.int(SimpleMaker.SIDELEN / 2);
        var img: BitmapData = data.image;
        var size: Int = data.size;
        var osl = SimpleMaker.SIDELEN / size;
        var sl = w / size;
        var shape = new Shape();
        shape.graphics.rox_drawRegion(img, 0, 0, w, w);
        shape.graphics.rox_drawRegion(ResKeeper.loadAssetImage("res/jigsaw_mask.png"), 0, 0, w, w);
        img = new BitmapData(w, w, true, 0);
        img.draw(shape);
        this.image = { path: null, bmd: img };
        var appdata: AppData = status.appData;
        appdata.width = w;
        appdata.height = w;
        appdata.type = "jigsaw";
        status.makerData = data;
        super.onNextStep();
    }

}
