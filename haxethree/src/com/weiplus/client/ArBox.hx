package com.weiplus.client;

import ru.stablex.ui.skins.Paint;
import flash.geom.Point;
import flash.display.Graphics;
import ru.stablex.ui.widgets.Widget;


/**
* Fill widget with color
*
*/
class ArBox extends Paint {

    private static inline var DASH_LEN = 6;

    override public function draw (w:Widget) : Void {
        var width  : Float = w.w - this.paddingLeft - this.paddingRight;
        var height : Float = w.h - this.paddingTop - this.paddingBottom;

//if size is wrong, draw nothing
        if( width <= 0 || height <= 0 ) return;

        if( this.color >= 0 ){
            w.graphics.beginFill(this.color, this.alpha);
            w.graphics.drawRect(this.paddingLeft, this.paddingTop, width, height);
            w.graphics.endFill();
        }

        var border = Math.max(this.border, 1);
        w.graphics.lineStyle(border, this.borderColor, this.borderAlpha);

        drawDashLine(w.graphics, this.paddingLeft, this.paddingTop, this.paddingLeft + width, this.paddingTop);
        drawDashLine(w.graphics, this.paddingLeft + width, this.paddingTop, this.paddingLeft + width, this.paddingTop + height);
        drawDashLine(w.graphics, this.paddingLeft + width, this.paddingTop + height, this.paddingLeft, this.paddingTop + height);
        drawDashLine(w.graphics, this.paddingLeft, this.paddingTop + height, this.paddingLeft, this.paddingTop);

    }//function draw()

    private function drawDashLine(g: Graphics, x1: Float, y1: Float, x2: Float, y2: Float) {
        var dist = Point.distance(new Point(x1, y1), new Point(x2, y2));
        var ang = Math.atan2(y2 - y1, x2 - x1);
        var dx = DASH_LEN * Math.cos(ang), dy = DASH_LEN * Math.sin(ang);
        var draw = true, count = Std.int(dist / DASH_LEN);
        for (i in 0...count) {
            if (draw) {
                g.moveTo(x1 + i * dx, y1 + i * dy);
                g.lineTo(x1 + (i + 1) * dx, y1 + (i + 1) * dy);
            }
            draw = !draw;
        }
        if (draw) {
            g.moveTo(x1 + count * dx, y1 + count * dy);
            g.lineTo(x2, y2);
        }
    }
}