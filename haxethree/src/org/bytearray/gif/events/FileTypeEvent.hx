package org.bytearray.gif.events;

import nme.events.Event;

class FileTypeEvent extends Event
{
    public static inline var INVALID:String = "invalid";

    public function new ( pType:String )
    {
        super ( pType, false, false );
    }
}
