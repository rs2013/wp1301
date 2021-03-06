package com.weiplus.apps.swappuzzle;

import com.roxstudio.haxe.game.GameUtil;
import nme.geom.Rectangle;
import nme.display.Shape;
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

    override public function onNextStep() {
        var w = Std.int(SimpleMaker.SIDELEN / 2);
        var img: BitmapData = data.image;
        var size: Int = data.size;
        var osl = SimpleMaker.SIDELEN / size;
        var sl = w / size;
//        trace("w="+w+",img="+img.width+","+img.height+",size="+size+",osl="+osl+",sl="+sl);
        var set: Array<Int> = [];
        for (i in 0...(size * size)) set.push(i);
        GameUtil.shuffle(set);
        var shape = new Shape();
        for (i in 0...size) {
            for (j in 0...size) {
                var idx = set[i * size + j];
                shape.graphics.rox_drawRegion(img, new Rectangle(Std.int(idx / size)  * osl, Std.int(idx % size) * osl, osl, osl), j * sl, i * sl, sl, sl);
                shape.graphics.rox_drawRect(2, 0xFFFFFFFF, j * sl + 1, i * sl + 1, sl - 1, sl - 1);
            }
        }
        img = new BitmapData(w, w, true, 0);
        img.draw(shape);
        this.image = { path: null, bmd: img, tags: imageTags };
        var appdata: AppData = status.appData;
        appdata.width = w;
        appdata.height = w;
        appdata.type = "swappuzzle";
        status.makerData = data;
        super.onNextStep();
    }

}
