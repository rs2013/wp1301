package com.weiplus.client;

import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.io.IOUtil;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.FastList;
import nme.geom.Point;
import com.roxstudio.haxe.ui.UiUtil;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxScreen;
import com.weiplus.client.model.AppData;
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

class HarryCamera extends MakerScreen {

    override public function createContent(height: Float) : Sprite {
        content = super.createContent(height);
        this.addEventListener(Event.ACTIVATE, onActive);
#if android
        HaxeStub.startHarryCamera(112);
#end
        return content;
    }

//    override public function onShown() {
//        if (image != null) finish(RoxScreen.CANCELED);
//    }

    private function onActive1(_) {
#if android
        var s = HaxeStub.getResult(112);
        var json: Dynamic = haxe.Json.parse(s);
        trace(">>HarryCamera active, result=" + s + ",parsed=" + json);
        if (untyped json.resultCode != "ok") return;
        var path = untyped json.intentDataPath;
        image = { path: path, bmd: ResKeeper.loadLocalImage(path) };
        var appdata: AppData = status.appData;
        appdata.width = image.bmd.width;
        appdata.height = image.bmd.height;
        appdata.type = "image";
        var bmd = processImg(image.bmd);
        content.graphics.rox_drawImage(ResKeeper.getAssetImage("res/bg_play.jpg"), null, true, true, 0, 0, screenWidth, screenHeight);
        content.graphics.rox_drawImage(bmd, null, false, true, 0, 0, bmd.width, bmd.height);
//        onNextStep();
#end
    }

    private static inline var TOLEH = 1.04;
    private static inline var TOLEL = 0.96;

    public static function processImg(bmd: BitmapData) {
        var bmd2 = new BitmapData(bmd.width, bmd.height, true, 0);
        bmd2.copyPixels(bmd, new Rectangle(0, 0, bmd.width, bmd.height), new Point(0, 0));
        var argb = bmd2.getPixels(new Rectangle(0, 0, bmd2.width, bmd2.height));
//        var rhi: Int = rangeValue(Std.int((argb[1] & 0xFF) * TOLEH), 0, 255);
//        var rlo: Int = rangeValue(Std.int((argb[1] & 0xFF) * TOLEL), 0, 255);
//        var ghi: Int = rangeValue(Std.int((argb[2] & 0xFF) * TOLEH), 0, 255);
//        var glo: Int = rangeValue(Std.int((argb[2] & 0xFF) * TOLEL), 0, 255);
//        var bhi: Int = rangeValue(Std.int((argb[3] & 0xFF) * TOLEH), 0, 255);
//        var blo: Int = rangeValue(Std.int((argb[3] & 0xFF) * TOLEL), 0, 255);
//        trace("r="+rhi+","+rlo+",g="+ghi+","+glo+",b="+bhi+","+blo);
        var stk = new FastList<Int>();
        stk.add(0);
        var linew = 4 * bmd2.width, len: Int = argb.length;
        var idx: Null<Int>;
//        var rt: Int, gt: Int, bt: Int, rr: Int, gr: Int, br: Int, rb: Int, gb: Int, bb: Int, rl: Int, gl: Int, bl: Int;
        var r: Int, g: Int, b: Int;
        var rhi: Int, rlo: Int, ghi: Int, glo: Int, bhi: Int, blo: Int;
        while ((idx = stk.pop()) != null) {
            r = argb[idx + 1];
            g = argb[idx + 2];
            b = argb[idx + 3];
            var rhi = hv(r), rlo = lv(r), ghi = hv(g), glo = lv(g), bhi = hv(b), blo = lv(b);

            argb[idx] = 0;
//            argb[idx + 1] = 0;
//            argb[idx + 2] = 0;
//            argb[idx + 3] = 0;

            var top = idx - linew, right = idx + 4, bottom = idx + linew, left = idx - 4;
            if (top >= 0 && argb[top] != 0 &&
                (r = (argb[top + 1] & 0xFF)) >= rlo && r <= rhi &&
                (g = (argb[top + 2] & 0xFF)) >= glo && g <= ghi &&
                (b = (argb[top + 3] & 0xFF)) >= blo && b <= bhi) { stk.add(top); /*trace("top=" + r + "," + g + "," + b + " added"); */}
            if (right < len && argb[right] != 0 &&
                (r = (argb[right + 1] & 0xFF)) >= rlo && r <= rhi &&
                (g = (argb[right + 2] & 0xFF)) >= glo && g <= ghi &&
                (b = (argb[right + 3] & 0xFF)) >= blo && b <= bhi) { stk.add(right); /*trace("right=" + r + "," + g + "," + b + " added"); */}
            if (bottom < len && argb[bottom] != 0 &&
                (r = (argb[bottom + 1] & 0xFF)) >= rlo && r <= rhi &&
                (g = (argb[bottom + 2] & 0xFF)) >= glo && g <= ghi &&
                (b = (argb[bottom + 3] & 0xFF)) >= blo && b <= bhi) { stk.add(bottom); /*trace("bottom=" + r + "," + g + "," + b + " added"); */}
            if (left >= 0 && argb[left] != 0 &&
                (r = (argb[left + 1] & 0xFF)) >= rlo && r <= rhi &&
                (g = (argb[left + 2] & 0xFF)) >= glo && g <= ghi &&
                (b = (argb[left + 3] & 0xFF)) >= blo && b <= bhi) { stk.add(left); /*trace("left=" + r + "," + g + "," + b + " added"); */}
//                trace("r="+rt+","+rr+","+rb+","+rl+",g="+gt+","+gr+","+gb+","+gl+",b="+bt+","+br+","+bb+","+bl);
//                trace("cnt="+cnt+",r="+rhi+","+rlo+",g="+ghi+","+glo+",b="+bhi+","+blo);
        }
#if cpp
        argb.position = 0;
        bmd2.setPixels(new Rectangle(0, 0, bmd2.width, bmd2.height), argb);
        var dir: String = #if android "/sdcard/" #else "" #end;
        dir += "" + Std.int(Date.now().getTime() / 1000);
        sys.io.File.saveBytes(dir + "_01.png", GameUtil.encodePng(bmd2));
#end
        var l1 = linew, l2 = linew * 2;
        var min = l2 + 2;
        var max = len - min;
        for (i in min...max >> 2) {
            var ii = i << 2;
            if (argb[ii] != 0) {
                argb[ii] = Std.int((argb[ii - l2 - 4] + argb[ii - l2] + argb[ii - l2 + 4] +
                        argb[ii - l1 - 8] + argb[ii - l1 - 4] + argb[ii - l1] + argb[ii - l1 + 4] + argb[ii - l1 + 8] +
                        argb[ii - 8] + argb[ii - 4] + argb[ii] + argb[ii + 4] + argb[ii + 8] +
                        argb[ii + l1 - 8] + argb[ii + l1 - 4] + argb[ii + l1] + argb[ii + l1 + 4] + argb[ii + l1 + 8] +
                        argb[ii + l2 - 4] + argb[ii + l2] + argb[ii + l2 + 4]) / 21);
            }
        }

//        for (i in 0...argb.length >> 2) {
//            var idx = i << 2;
//            var r: Int = argb[idx + 1], g: Int = argb[idx + 2], b: Int = argb[idx + 3];
//            if (r >= rl && r <= rhi && g >= gl && g <= ghi && b >= bl && b <= bhi) argb[idx] = 0;
//        }
        argb.position = 0;
        bmd2.setPixels(new Rectangle(0, 0, bmd2.width, bmd2.height), argb);
#if cpp
        sys.io.File.saveBytes(dir + "_02.png", GameUtil.encodePng(bmd2));

        sys.io.File.saveBytes(dir + "_00.jpg", GameUtil.encodeJpeg(bmd));
#end
        return bmd2;
    }

    private static inline function hv(i: Int) : Int {
        i = Std.int(i * TOLEH);
//        i += 6;
        return i > 255 ? 255 : i;
    }

    private static inline function lv(i: Int) : Int {
        i = Std.int(i * TOLEL);
//        i -= 6;
        return i < 0 ? 0 : i;
    }

    private inline function rangeValue(v: Int, min: Int, max: Int) {
        return v < min ? min : v > max ? max : v;
    }

    override public function onScreenResult(_, _, _) {
        finish(RoxScreen.CANCELED);
    }

    private function onActive(_) {
#if android
        var s = HaxeStub.getResult(112);
        var json: Dynamic = haxe.Json.parse(s);
        trace(">>HarryCamera active, result=" + s + ",parsed=" + json);
        if (json.resultCode != "ok") { // canceled
            finish(RoxScreen.CANCELED);
            return;
        }
        var path = untyped json.intentDataPath;
        image = { path: path, bmd: ResKeeper.loadLocalImage(path) };
        trace("HarryCamera.onActive: image=" + image);
//        var bmp = new nme.display.Bitmap(image);
//        content.addChild(bmp);
        var appdata: AppData = status.appData;
        appdata.width = image.bmd.width;
        appdata.height = image.bmd.height;
        appdata.type = "image";
        onNextStep();
#end
    }

}
