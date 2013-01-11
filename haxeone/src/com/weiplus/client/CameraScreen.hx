package com.weiplus.client;

import nme.geom.Rectangle;
import nme.display.Bitmap;
import flash.display.BitmapData;
#if android
import com.weiplus.client.HaxeStub;
#end
import nme.utils.ByteArray;
import nme.events.Event;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxScreenManager;
import com.roxstudio.haxe.ui.RoxScreen;

class CameraScreen extends RoxScreen {

    var bmd: BitmapData;

    public function new() {
        super();
        RoxApp.stage.opaqueBackground = 0;
        graphics.beginFill(0xff00);
        graphics.drawRect(20, 20, 200, 300);
        graphics.endFill();
//        RoxApp.stage.addEventListener(Event.ENTER_FRAME, update);
//        bmd = new BitmapData(Std.int(RoxApp.screenWidth), Std.int(RoxApp.screenHeight), false, 0x220000);
//        addChild(new Bitmap(bmd));
    }

#if android
    private function update(e: Dynamic) {
        var buffer = HaxeStub.getBuffer();
        if (buffer == null) return;
        //trace("class=" + Type.getClass(buffer));
        //trace("length=" + buffer.length);
        //untyped trace("first=" + buffer[0] +"," + buffer[1]+"," + buffer[2]+"," + buffer[3]);
        var bb: Array<Int> = cast(buffer);
        trace("size=" + bb.length);
//        bmd.setPixels(new Rectangle(0, 0, 320, 240), bb);
        bmd.lock();
        var x = 0, y = 0;
        for (i in 0...bb.length) { // RGB_565
//            var b1: Int = bb[i << 1], b2: Int = bb[(i << 1) + 1];
//            var c = ((b1 >> 3) << 16) + ((b1 & 0x7) << 13) + ((b2 >> 5) << 10) + ((b2 & 0x1F) << 3);
            bmd.setPixel(x++, y, bb[i]);
            if (x >= 320) {
                x = 0;
                y++;
            }
        }
        bmd.unlock();
    }
#end

}
