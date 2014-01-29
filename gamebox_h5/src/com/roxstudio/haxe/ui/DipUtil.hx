package com.roxstudio.haxe.ui;

import flash.Lib;

class DipUtil {

    public static var dpFactor: Float = 1;
    public static var stageWidthDp: Float = 0;
    public static var stageHeightDp: Float = 0;

    private function new() {
    }

    public static function init(designDimension: Int, useWidth: Bool = true) {
        var realDimension = useWidth ? Lib.current.stage.stageWidth : Lib.current.stage.stageHeight;
        dpFactor = realDimension / designDimension;
        if (useWidth) {
            stageWidthDp = designDimension;
            stageHeightDp = Lib.current.stage.stageHeight / dpFactor;
        } else {
            stageWidthDp = Lib.current.stage.stageWidth / dpFactor;
            stageHeightDp = designDimension;
        }
    }

    public static inline function dpScale(res: String) {
        return res + ";scale(" + dpFactor + ")";
    }

    public static inline function dp(val: Float) : Float {
        return val * dpFactor;
    }

}
