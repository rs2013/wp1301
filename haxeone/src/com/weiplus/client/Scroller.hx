package com.weiplus.client;

import nme.geom.Rectangle;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;

class Scroller extends Sprite {

    public static inline var VERTICAL = 1;
    public static inline var HORIZONTAL = 2;
    public static inline var ALL = VERTICAL + HORIZONTAL;

    public var viewportWidth: Float;
    public var viewportHeight: Float;
    public var offsetx: Float;
    public var offsety: Float;
    public var direction: Int;

    public function new(viewportWidth: Float, viewportHeight: Float, direction: Int, ?width: Null<Float>, ?height: Null<Float>) {
        super();
        this.viewport = viewport;
        this.direction = direction;
        var w = (direction & HORIZONTAL) == 0 ? viewport.width : width;
        var h = (direction & VERTICAL) == 0 ? viewport.height : height;
        if (w != null && h != null) this.graphics.rox_fillRect(0x01FFFFFF, 0, 0, w, h);
    }


}
