/**
* This class lets you play animated GIF files in AS3
* @author Thibault Imbert (bytearray.org)
* @version 0.6
*/

package org.bytearray.gif.player;

import nme.errors.RangeError;
import nme.errors.Error;
import nme.events.TimerEvent;
import nme.net.URLLoaderDataFormat;
import nme.net.URLLoader;
import nme.net.URLRequest;
import nme.events.Event;
//import nme.system.LoaderContext;
import nme.utils.ByteArray;
import nme.utils.Timer;
import nme.display.Bitmap;
import nme.display.BitmapData;
//import nme.utils.getTimer;
import nme.events.IOErrorEvent;
//import nme.errors.ScriptTimeoutError;
import org.bytearray.gif.frames.GIFFrame;
import org.bytearray.gif.decoder.GIFDecoder;
import org.bytearray.gif.events.GIFPlayerEvent;
import org.bytearray.gif.events.FrameEvent;
import org.bytearray.gif.events.TimeoutEvent;
import org.bytearray.gif.events.FileTypeEvent;
import org.bytearray.gif.errors.FileTypeError;

class GIFPlayer extends Bitmap
{
    private var urlLoader:URLLoader;
    private var gifDecoder:GIFDecoder;
    private var aFrames:Array<GIFFrame>;
    private var myTimer:Timer;
    private var iInc:Int;
    private var iIndex:Int;
    private var auto:Bool;
    private var arrayLng:Int;

    public function new ( pAutoPlay:Bool = true )
    {
        super();
        auto = pAutoPlay;
        iIndex = iInc = 0;

        myTimer = new Timer ( 0, 0 );
        aFrames = []; //new Array();
        urlLoader = new URLLoader();
        urlLoader.dataFormat = URLLoaderDataFormat.BINARY;

        urlLoader.addEventListener ( Event.COMPLETE, onComplete );
        urlLoader.addEventListener ( IOErrorEvent.IO_ERROR, onIOError );

        myTimer.addEventListener ( TimerEvent.TIMER, update );

        gifDecoder = new GIFDecoder();
    }

    private function onIOError ( pEvt:IOErrorEvent ):Void
    {
        dispatchEvent ( pEvt );
    }

    private function onComplete ( pEvt:Event ):Void
    {
        readStream ( pEvt.target.data );
    }

    private function readStream ( pBytes:ByteArray ):Void
    {
        var gifStream:ByteArray = pBytes;

        aFrames = [];//new Array();
        iInc = 0;

        try
        {
            gifDecoder.read ( gifStream );

            var lng:Int = gifDecoder.getFrameCount();

            for (i in 0...lng)
                aFrames[i] = gifDecoder.getFrame(i);

            arrayLng = aFrames.length;

            auto ? play() : gotoAndStop (1);

            dispatchEvent ( new GIFPlayerEvent ( GIFPlayerEvent.COMPLETE , aFrames[0].bitmapData.rect ) );

//        } catch ( e:ScriptTimeoutError )
//        {
//            dispatchEvent ( new TimeoutEvent ( TimeoutEvent.TIME_OUT ) );

        } catch ( e:FileTypeError )
        {
            dispatchEvent ( new FileTypeEvent ( FileTypeEvent.INVALID ) );

        } catch ( e:Error )
        {
            throw new Error ("An unknown error occured, make sure the GIF file contains at least one frame\nNumber of frames : " + aFrames.length);
        }

    }

    private function update ( pEvt:TimerEvent ) :Void
    {
        var delay:Int = aFrames[ iIndex = iInc++ % arrayLng ].delay;

        pEvt.target.delay = ( delay > 0 ) ? delay : 100;

        switch ( gifDecoder.disposeValue )
        {
            case 1:
                if ( iIndex != 0 )
                    bitmapData = aFrames[ 0 ].bitmapData.clone();
                bitmapData.draw ( aFrames[ iIndex ].bitmapData );
            case 2:
                bitmapData = aFrames[ iIndex ].bitmapData;
        }

        dispatchEvent ( new FrameEvent ( FrameEvent.FRAME_RENDERED, aFrames[ iIndex ] ) );
    }

    private function concat ( pIndex:Int ):Int
    {
        bitmapData.lock();
        for (i in 0...pIndex)
            bitmapData.draw ( aFrames[ i ].bitmapData );
        bitmapData.unlock();

        return pIndex;
    }

    /**
     * Load any GIF file
     *
     * @return Void
    */
    public function load ( pRequest:URLRequest ):Void
    {
        stop();
        urlLoader.load ( pRequest );
    }

    /**
     * Load any valid GIF ByteArray
     *
     * @return Void
    */
    public function loadBytes ( pBytes:ByteArray ):Void
    {
        readStream ( pBytes );
    }

    /**
     * Start playing
     *
     * @return Void
    */
    public function play ():Void
    {
        if ( aFrames.length > 0 )
        {
            if ( !myTimer.running )
                myTimer.start();

        } else throw new Error ("Nothing to play");
    }

    /**
     * Stop playing
     *
     * @return Void
    */
    public function stop ():Void
    {
        if ( myTimer.running )
            myTimer.stop();
    }

    /**
     * Returns current frame being played
     *
     * @return frame number
    */
    public var currentFrame(get_currentFrame, null):Int;
    private function get_currentFrame ():Int
    {
        return iIndex+1;
    }

    /**
     * Returns GIF's total frames
     *
     * @return number of frames
    */
    public var totalFrames(get_totalFrames, null):Int;
    private function get_totalFrames ():Int
    {
        return aFrames.length;
    }

    /**
     * Returns how many times the GIF file is played
     * A loop value of 0 means repeat indefinitiely.
     *
     * @return loop value
    */
    public var loopCount(get_loopCount, null):Int;
    private function get_loopCount ():Int
    {
        return gifDecoder.getLoopCount();
    }

    /**
     * Returns is the autoPlay value
     *
     * @return autoPlay value
    */
    public var autoPlay(get_autoPlay, null):Bool;
    private function get_autoPlay ():Bool
    {
        return auto;
    }

    /**
     * Returns an array of GIFFrame objects
     *
     * @return aFrames
    */
    public var frames(get_frames, null):Array<GIFFrame>;
    private function get_frames ():Array<GIFFrame>
    {
        return aFrames;
    }

    /**
     * Moves the playhead to the specified frame and stops playing
     *
     * @return Void
    */
    public function gotoAndStop (pFrame:Int):Void
    {
        if ( pFrame >= 1 && pFrame <= aFrames.length )
        {
            if ( pFrame == currentFrame ) return;
            iIndex = iInc = pFrame-1;

            switch ( gifDecoder.disposeValue )
            {
                case 1:
                    bitmapData = aFrames[ 0 ].bitmapData.clone();
                    bitmapData.draw ( aFrames[ concat ( iInc ) ].bitmapData );
                case 2:
                    bitmapData = aFrames[ iInc ].bitmapData;
            }

            if ( myTimer.running )
                myTimer.stop();

        } else throw new RangeError ("Frame out of range, please specify a frame between 1 and " + aFrames.length );
    }

    /**
     * Starts playing the GIF at the frame specified as parameter
     *
     * @return Void
    */
    public function gotoAndPlay (pFrame:Int):Void
    {
        if ( pFrame >= 1 && pFrame <= aFrames.length )
        {
            if ( pFrame == currentFrame ) return;
            iIndex = iInc = pFrame-1;

            switch ( gifDecoder.disposeValue )
            {
                case 1:
                    bitmapData = aFrames[ 0 ].bitmapData.clone();
                    bitmapData.draw ( aFrames[ concat ( iInc ) ].bitmapData );
                case 2:
                    bitmapData = aFrames[ iInc ].bitmapData;
            }
            if ( !myTimer.running ) myTimer.start();

        } else throw new RangeError ("Frame out of range, please specify a frame between 1 and " + aFrames.length );
    }

    /**
     * Retrieves a frame from the GIF file as a BitmapData
     *
     * @return BitmapData object
    */
    public function getFrame ( pFrame:Int ):GIFFrame
    {
        var frame:GIFFrame;

        if ( pFrame >= 1 && pFrame <= aFrames.length )
            frame = aFrames[ pFrame-1 ];

        else throw new RangeError ("Frame out of range, please specify a frame between 1 and " + aFrames.length );

        return frame;
    }

    /**
     * Retrieves the delay for a specific frame
     *
     * @return Int
    */
    public function getDelay ( pFrame:Int ):Int
    {
        var delay:Int;

        if ( pFrame >= 1 && pFrame <= aFrames.length )
            delay = aFrames[ pFrame-1 ].delay;

        else throw new RangeError ("Frame out of range, please specify a frame between 1 and " + aFrames.length );

        return delay;
    }

    /**
     * Dispose a GIFPlayer instance
     *
     * @return Int
    */
    public function dispose():Void
    {
        stop();
        var lng:Int = aFrames.length;

        for (i in 0...lng)
            aFrames[i].bitmapData.dispose();
    }
}
