package com.weiplus.client;

import nme.geom.Matrix;
import nme.display.Bitmap;
import com.roxstudio.haxe.io.IOUtil;
import flash.display.BitmapData;
import flash.utils.ByteArray;
import org.bytearray.gif.encoder.GIFEncoder;
import nme.display.Shape;
import org.bytearray.gif.player.GIFPlayer;
import org.bytearray.gif.decoder.GIFDecoder;
import com.roxstudio.haxe.game.ResKeeper;
import nme.events.MouseEvent;
import nme.display.Sprite;
import com.roxstudio.haxe.ui.RoxScreen;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class TestCurve extends RoxScreen {

    var bmd: BitmapData;

    public function new() {
        super();
    }

    override public function onCreate() {
        super.onCreate();
//        var sp = new Sprite();
//        sp.cacheAsBitmap = true;
//        var gfx = sp.graphics;
//        var bmd = ResKeeper.getAssetImage("res/8.jpg");
//        gfx.beginBitmapFill(bmd, null, true, true);
//        gfx.moveTo(0, 0);
//        gfx.curveTo(85, 20, 80, 0);
//        gfx.curveTo(55, -36, 100, -36);
//        gfx.curveTo(145, -36, 120, 0);
//        gfx.curveTo(115, 20, 200, 0);
//        gfx.lineTo(200, 200);
//        gfx.lineTo(0, 200);
//        gfx.lineTo(0, 0);
//        gfx.endFill();
//        sp.rox_scale(0.5);
//        sp.mouseEnabled = true;
//        sp.addEventListener(MouseEvent.CLICK, function(_) {
//            trace("click!");
//        });
//        addChild(sp.rox_move(100, 100));

        var ba = ResKeeper.getAssetData("res/test.gif.dat");
        var inp = new GIFDecoder();
        inp.read(ba);
        var shape = new Shape();
        shape.graphics.rox_line(1, 0xFFFF0000, 0, 0, 0, 20);
        shape.graphics.rox_line(1, 0xFF00FF00, 2, 0, 2, 20);
        shape.graphics.rox_line(1, 0xFF0000FF, 4, 0, 4, 20);
        shape.graphics.rox_line(1, 0xFFFF0000, 6, 0, 6, 20);
        shape.graphics.rox_line(1, 0xFF00FF00, 8, 0, 8, 20);
        shape.graphics.rox_line(1, 0xFF0000FF, 10, 0, 10, 20);
        shape.graphics.rox_line(1, 0xFFFF0000, 12, 0, 12, 20);
        shape.graphics.rox_line(1, 0xFF00FF00, 14, 0, 14, 20);
        shape.graphics.rox_line(1, 0xFF0000FF, 16, 0, 16, 20);
        shape.graphics.rox_line(1, 0xFFFF0000, 18, 0, 18, 20);
        shape.graphics.rox_line(1, 0xFF00FF00, 20, 0, 20, 20);
        bmd = new BitmapData(220, 200, true, 0xFF777777);
        bmd.draw(shape, new Matrix(10, 0, 0, 10));
        var sp = new Sprite();
        sp.addChild(new Bitmap(bmd).rox_move(100, 100));
        sp.mouseEnabled = true;
        sp.addEventListener(MouseEvent.CLICK, function(_) {
            trace("test");
            test(inp);
        });
        addChild(sp);
//        var xoff = 0.0, yoff = 0.0;
//        var inout = new GIFDecoder();
//        inout.read(out.stream);
//        for (i in 0...inout.getFrameCount()) {
//            var bmd = inout.getFrame(i).bitmapData;
////            trace("out:w=" + bmd.width + ",h=" + bmd.height);
//        }
//        var gif = new GIFPlayer();
//        gif.loadBytes(out.stream);
//        addChild(gif.rox_move(100, 100));
    }

    private function test(inp: GIFDecoder) {
        var out = new GIFEncoder();
        out.start();
        out.setFrameRate(2);
        out.addFrame(bmd);
//        for (i in 0...inp.getFrameCount()) {
//            var bmd = inp.getFrame(i).bitmapData;
//            bmd.draw(shape);
//            trace("bmd:w=" + bmd.width + ",h=" + bmd.height);
//            out.addFrame(bmd);
//            sp.graphics.rox_drawRegion(bmd, xoff, yoff);
//            xoff += bmd.width;
//            if (xoff >= screenWidth) {
//                xoff = 0;
//                yoff += bmd.height;
//            }
//        }
        out.finish();
        sys.io.File.saveBytes("test.gif", IOUtil.rox_toBytes(out.stream));
    }
}
