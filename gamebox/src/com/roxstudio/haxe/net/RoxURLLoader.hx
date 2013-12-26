package com.roxstudio.haxe.net;

import nme.events.ErrorEvent;
//import org.bytearray.gif.decoder.GIFDecoder;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Loader;
import nme.errors.Error;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.net.URLLoader;
import nme.net.URLLoaderDataFormat;
import nme.net.URLRequest;
import nme.utils.ByteArray;

using StringTools;

/**
* Currently support: String, ByteArray, BitmapData
**/
class RoxURLLoader {

    public static inline var BINARY = 1;
    public static inline var TEXT = 2;
    public static inline var IMAGE = 3;

    public var url(default, null): String;
    public var type(default, null): Int;
    public var started(default, null): Bool = false;
    private var timeout: Float = 15;
    private var timer: haxe.Timer;

    public function new(url: String, type: Int = BINARY, onComplete: Bool -> Dynamic -> Void, ?timeout: Float = 15) {
        this.url = url;
        this.type = type;
        this.onComplete = onComplete;
        this.timeout = timeout;
    }

    public dynamic function onComplete(isOk: Bool, data: Dynamic) : Void {}

    public dynamic function onRaw(rawData: ByteArray) : Void {}

    public dynamic function onProgress(bytesLoaded: Float, bytesTotal: Float) : Void {}

    public function start() {
        if (started) return;
        started = true;
        try {
            if (!url.startsWith("http://") && !url.startsWith("https://")) throw "Malformed URL: " + url;
            var loader = new URLLoader();
            loader.dataFormat = URLLoaderDataFormat.BINARY;
            loader.addEventListener(Event.COMPLETE, onDone);
            if (onProgress != null) {
                loader.addEventListener(ProgressEvent.PROGRESS, function(e: ProgressEvent) {
                    onProgress(e.bytesLoaded, e.bytesTotal);
                });
            }
            loader.addEventListener(IOErrorEvent.IO_ERROR, function(e: Event) {
                asyncOnComp(false, new Error(IOErrorEvent.IO_ERROR));
            });
#if !html5
            loader.addEventListener(nme.events.SecurityErrorEvent.SECURITY_ERROR, function(e: Event) {
                asyncOnComp(false, new Error(nme.events.SecurityErrorEvent.SECURITY_ERROR));
            });
#end
            timer = new haxe.Timer(Std.int(timeout * 1000));
            timer.run = oncomp.bind(false, new Error("Request timeout"));
            loader.load(new URLRequest(url));
        } catch (e: Dynamic) {
            asyncOnComp(false, e);
        }
    }

    private function onDone(e: Dynamic) {
        if (timer != null) timer.stop();
        var ba: ByteArray = cast e.target.data;
        if (onRaw != null) onRaw(ba);
        switch (type) {
            case IMAGE:
                var iscpp = #if cpp true #else false #end;
                if (iscpp && ba[0] == 'G'.code && ba[1] == 'I'.code && ba[2] == 'F'.code) {
//                    trace("it's gif");
//                    var gifdec = new GIFDecoder();
//                    gifdec.read(ba);
//                    var bmd = gifdec.getFrameCount() > 0 ? gifdec.getImage().bitmapData : new BitmapData(0, 0);
//                    trace("gif ok");
//                    oncomp(true, bmd);
                    oncomp(false, new Error("GIF is not supported"));
                } else { // not a gif image or it's on flash target
#if cpp
                    var bmd = null;
                    try {
                        bmd = BitmapData.loadFromBytes(ba);
                        if (bmd == null || bmd.width == 0) throw "error";
                        oncomp(true, bmd);
                    } catch (e: Dynamic) {
                        oncomp(false, new Error("Malformed image data"));
                    }
#else
                    var ldr = new Loader();
                    var imageDone = function(_) {
                        var bmd = cast(ldr.content, Bitmap).bitmapData;
                        oncomp(true, bmd);
                    }
                    ldr.loadBytes(ba);
                    if (ldr.content != null) {
                        imageDone(null);
                    } else {
                        var ldri = ldr.contentLoaderInfo;
                        ldri.addEventListener(Event.COMPLETE, imageDone);
                    }
#end
                }
            case TEXT:
                oncomp(true, ba.toString());
            case BINARY:
                oncomp(true, ba);
        }
    }

    private inline function asyncOnComp(isOk: Bool, data: Dynamic) {
        haxe.Timer.delay(oncomp.bind(isOk, data), 0);
    }

    private inline function oncomp(isOk: Bool, data: Dynamic) {
        if (!isOk) trace("RoxURLLoader: error=" + data);
        if (timer != null) timer.stop();
        onComplete(isOk, data);
    }

}
