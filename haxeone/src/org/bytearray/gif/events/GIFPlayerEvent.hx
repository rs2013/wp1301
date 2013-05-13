package org.bytearray.gif.events;

import nme.events.Event;
import nme.geom.Rectangle;

class GIFPlayerEvent extends Event
{
    public var rect:Rectangle;

    public static inline var COMPLETE:String = "complete";

    public function new ( pType:String, pRect:Rectangle )
    {
        super ( pType, false, false );
        rect = pRect;
    }
}