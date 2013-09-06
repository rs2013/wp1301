package com.roxstudio.haxe.game;

import flash.geom.Point;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.display.BitmapData;

class BmdUtil {

    public static inline var RESIZE_EXACT = 0;
    public static inline var RESIZE_CROP_OVERFLOW = 1;
    public static inline var RESIZE_USE_MARGIN = 2;
    public static inline var RESIZE_AUTO_SIZE = 3;

    private function new() {
    }

    public static function transform(bmd: BitmapData, optr: String, args: Array<Float>) {
        trace("transform: optr=" + optr + ",args=" + args + ",len=" + args.length);
        var newbmd: BitmapData = bmd;
        switch (optr) {
            case "create":
                var color = args.length > 2 ? Std.int(args[2]) : 0;
                newbmd = new BitmapData(Std.int(args[0]), Std.int(args[1]), true, color);
            case "clip":
                newbmd = new BitmapData(Std.int(args[2]), Std.int(args[3]), true, 0);
                newbmd.copyPixels(bmd, new Rectangle(args[0], args[1], args[2], args[3]), new Point(0, 0));
            case "resize": // w, h, ?flag (0: exact, 1: keep aspect ratio & crop overflow, 2: keep a-ratio & use margin, 3: keep a-ratio & auto-size)
                var flag = args.length > 2 ? args[2] : RESIZE_EXACT;
                var w = Std.int(args[0]), h = Std.int(args[1]);
                var rw = w / bmd.width, rh = h / bmd.height;
                var offx = 0.0, offy = 0.0;
                if (flag != RESIZE_EXACT) {
                    rw = rh = flag == RESIZE_CROP_OVERFLOW ? Math.max(rw, rh) : Math.min(rw, rh);
                    if (flag == RESIZE_AUTO_SIZE) {
                        w = Std.int(rw * bmd.width);
                        h = Std.int(rh * bmd.height);
                    } else {
                        offx = ((w - (rw * bmd.width)) / 2); // / rw;
                        offy = ((h - (rh * bmd.height)) / 2); // / rh;
                    }
                }
                trace("transform: bmd=" + bmd.width + "," + bmd.height + ",resize=" + w + "," + h + ",r=" + rw + "," + rh + ",off=" + offx + "," + offy);
                newbmd = new BitmapData(w, h, true, 0);
                newbmd.draw(bmd, new Matrix(rw, 0, 0, rh, offx, offy), true);
            case "scale":
                var sx = args[0], sy = args.length > 1 ? args[1] : args[0];
                newbmd = new BitmapData(Std.int(bmd.width * sx), Std.int(bmd.height * sy), true, 0);
                newbmd.draw(bmd, new Matrix(sx, 0, 0, sy), true);
            case "flip":
                newbmd = new BitmapData(bmd.width, bmd.height, true, 0);
                newbmd.draw(bmd, new Matrix(1, 0, 0, -1, 0, bmd.height));
            case "mirror":
                newbmd = new BitmapData(bmd.width, bmd.height, true, 0);
                newbmd.draw(bmd, new Matrix(-1, 0, 0, 1, bmd.width, 0));
            default:
        }
        return newbmd;
    }

}
