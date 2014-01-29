package com.roxstudio.haxe.ui;

/**
* Helper class for StablexUI
**/
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.game.BmdUtil;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import Lambda;
import flash.display.BitmapData;
import com.roxstudio.haxe.game.ResKeeper;
import ru.stablex.Assets;

using StringTools;

class SxAdapter {

    private function new() {
    }

    public static function setupAssets() {
        Assets.getBitmapData = getBitmapWithArgs;
        Assets.getBytes = ResKeeper.getAssetData.bind(_, null);
        Assets.getText = ResKeeper.getAssetText.bind(_, null);
    }

    public static function getBitmapWithArgs(src: String, ?useCache: Bool) : BitmapData {
//        trace("getBitmapWithArgs: src=" + src);
        var bmd: BitmapData = ResKeeper.get(ResKeeper.ASSETS_PROT + src);
//        trace("check cache: src="+(ResKeeper.ASSETS_PROT + src)+",bmd="+bmd+(bmd!=null?"("+bmd.width+","+bmd.height+")":""));
        if (bmd != null) return bmd;
        var arr = src.split(";");
        if (arr[0].length > 0) {
            bmd = ResKeeper.get(ResKeeper.ASSETS_PROT + arr[0]);
//            trace("check cache: src="+(ResKeeper.ASSETS_PROT + arr[0])+",bmd="+bmd);
            if (bmd == null) bmd = ResKeeper.loadAssetImage(arr[0]);
//            trace("load res: bmd="+bmd);
        }
        if (arr.length > 1) {
            for (i in 1...arr.length) {
                var idx = arr[i].indexOf("(");
                var optr = arr[i].substring(0, idx);
                var argstr = arr[i].substring(idx + 1, arr[i].length - 1);
                var args = argstr.split(",");
                var argArr: Array<Float> = [];
                for (a in args)
                    if (a.trim() != "") argArr.push(Std.parseFloat(a.trim()));
                bmd = BmdUtil.transform(bmd, optr, argArr);
            }
        }
        ResKeeper.add(ResKeeper.ASSETS_PROT + src, bmd);
//        trace("cache added: id="+(ResKeeper.ASSETS_PROT + src)+",bmd="+bmd);
        return bmd;
    }

}
