package org.bytearray.gif.frames;

import nme.display.BitmapData;

class GIFFrame
{
    public var bitmapData:BitmapData;
    public var delay:Int;

    public function new( pImage:BitmapData, pDelay:Int )
    {
        bitmapData = pImage;
        delay = pDelay;
    }
}
