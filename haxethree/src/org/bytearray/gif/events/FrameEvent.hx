package org.bytearray.gif.events;
import nme.events.Event;
import org.bytearray.gif.frames.GIFFrame;

class FrameEvent extends Event
{
    public var frame:GIFFrame;

    public static inline var FRAME_RENDERED:String = "rendered";

    public function new ( pType:String, pFrame:GIFFrame )
    {
        super ( pType, false, false );

        frame = pFrame;
    }
}