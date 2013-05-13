package org.bytearray.gif.events;

import nme.events.Event;

class TimeoutEvent extends Event
{
    public static inline var TIME_OUT:String = "timeout";

    public function new ( pType:String )
    {
        super ( pType, false, false );
    }
}