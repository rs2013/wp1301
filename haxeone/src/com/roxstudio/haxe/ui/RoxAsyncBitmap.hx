package com.roxstudio.haxe.ui;

import com.roxstudio.haxe.game.GameUtil;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.DisplayObject;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class RoxAsyncBitmap extends Sprite {

    public var loader(default, null): RoxURLLoader;
    public var loadingDisplay: DisplayObject;
    public var errorDisplay: DisplayObject;

    private var w: Null<Float>;
    private var h: Null<Float>;

    public function new(loader: RoxURLLoader, ?width: Null<Float>, ?height: Null<Float>,
                        ?loadingDisplay: DisplayObject, ?errorDisplay: DisplayObject) {
        super();
        this.w = width;
        this.h = height;
        this.loadingDisplay = loadingDisplay;
        this.errorDisplay = errorDisplay;
        this.loader = loader;
        if (loader.status == RoxURLLoader.LOADING) {
            loader.addEventListener(Event.COMPLETE, update);
        }
        update(null);
    }

    private function update(_) {
        var dp: DisplayObject = switch (loader.status) {
            case RoxURLLoader.OK:
                new Bitmap(cast(loader.data));
            case RoxURLLoader.ERROR:
                errorDisplay;
            case RoxURLLoader.LOADING:
                loadingDisplay;
        }
        if (numChildren > 0) removeChildAt(0);
        if (dp != null) {
            if (w != null) dp.width = w;
            if (h != null) dp.height = h;
            addChild(dp);
        } else {
            if (w != null && h != null) graphics.rox_fillRect(0x01FFFFFF, 0, 0, w, h);
        }
//        trace(">2>min="+minWidth+","+minHeight+",this="+this.width+","+this.height+(dp!=null?",dp="+dp.width+","+dp.height:""));
    }

}
