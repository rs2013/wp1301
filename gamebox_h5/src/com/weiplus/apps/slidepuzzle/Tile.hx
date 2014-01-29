package com.weiplus.apps.slidepuzzle;

import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.io.IOUtil;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.BitmapData;
import nme.display.Shape;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.utils.ByteArray;
import nme.Vector;

using com.roxstudio.haxe.ui.UiUtil;

/**
 * ...
 * @author Rocks Wang
 */

class Tile extends Sprite {

    public var sideLen: Float;
    public var colIndex: Int;
    public var rowIndex: Int;

    private var app: App;
    private var bmd: BitmapData;
    private var image: BitmapData;
    private var shape: BitmapData;

    public function new(inApp: App, inColIndex: Int, inRowIndex: Int) {
        super();
        app = inApp;
        image = inApp.image;
        shape = inApp.shape;
        sideLen = inApp.sideLen;
        colIndex = inColIndex;
        rowIndex = inRowIndex;
        bmd = new BitmapData(Std.int(sideLen), Std.int(sideLen));
        addChild(new Bitmap(bmd).rox_smooth().rox_move(-sideLen / 2, -sideLen / 2));
        update();
    }

    private function update() {
        var sl = sideLen;
        var offx = (shape.width - app.columns * sl) / 2, offy = (shape.height - app.rows * sl) / 2;
        var r = new Rectangle(offx + colIndex * sl, offy + rowIndex * sl, sl, sl);
        var p = new Point(0, 0);
        bmd.copyPixels(shape, r, p);

//        var mask = new BitmapData(Std.int(sl), Std.int(sl), 0);
//        var scale = sl / shape.width;
//        mask.draw(shape, new Matrix(scale, 0, 0, scale, 0, 0));
//        var mbuf = mask.getPixels(new Rectangle(0, 0, sl, sl));
//        var bbuf = bmd.getPixels(new Rectangle(0, 0, sl, sl));
//        var obuf = IOUtil.byteArray(mbuf.length);
//        //mbuf.position = bbuf.position = 0;
//        //trace(">>>>>mb=" + mbuf.bytesAvailable + ",len=" + mbuf.length + ",bb=" + bbuf.bytesAvailable + ",len=" + bbuf.length + ",pos=" + mbuf.position);
//        for (i in 0...mbuf.length) {
//            var mb = mbuf[i], bb = bbuf[i];// .readByte() & 0xFF, bb = bbuf.readByte() & 0xFF;
//            if ((i & 0x3) == 0) { // alpha
//                obuf[i] = mb; // obuf.writeByte(mb);
//            } else if (mb > 100 && mb < 155) {
//                obuf[i] = bb; // obuf.writeByte(bb);
//            } else if (mb > 220) {
//                obuf[i] = 255;
//            } else { // mb != 127
//                var v = (bb * mb) >> 7;
//                obuf[i] = v > 255 ? 255 : v;
//            }
//        }
//        //obuf.position = 0;
//        bmd.setPixels(new Rectangle(0, 0, sl, sl), obuf);
////        cast(this.getChildAt(0), Bitmap).bitmapData = mask;
    }

    override public function toString() : String {
        return "SwapPuzzleTile(col=" + colIndex + ",row=" + rowIndex + ")@" + new Point(x, y).rox_pointStr();
    }

}