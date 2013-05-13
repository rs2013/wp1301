package com.roxstudio.haxe.net;

import com.roxstudio.haxe.ui.UiUtil;
import nme.events.ErrorEvent;
import org.bytearray.gif.decoder.GIFDecoder;
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

    private var oncomplete: Bool -> Dynamic -> Void; // isSuccessful, data(String/ByteArray/BitmapData)
    private var onraw: ByteArray -> Void;
    private var onprogress: Float -> Float -> Void;

    public function new(url: String, type: Int = BINARY, onComplete: Bool -> Dynamic -> Void) {
        this.url = url;
        this.type = type;
        this.oncomplete = onComplete;
    }

    public inline function onRaw(inCallback: ByteArray -> Void) : RoxURLLoader {
        onraw = inCallback;
        return this;
    }

    public inline function onProgress(inCallback: Float -> Float -> Void) : RoxURLLoader {
        onprogress = inCallback;
        return this;
    }

    public function start() {
        if (started) return;
        started = true;
        try {
            var loader = new URLLoader();
            loader.dataFormat = URLLoaderDataFormat.BINARY;
            loader.addEventListener(Event.COMPLETE, onDone);
            if (onprogress != null) {
                loader.addEventListener(ProgressEvent.PROGRESS, function(e: ProgressEvent) {
                    onprogress(e.bytesLoaded, e.bytesTotal);
                });
            }
            loader.addEventListener(IOErrorEvent.IO_ERROR, function(e: Event) {
                oncomplete(false, new Error(IOErrorEvent.IO_ERROR));
            });
#if !html5
            loader.addEventListener(nme.events.SecurityErrorEvent.SECURITY_ERROR, function(e: Event) {
                oncomplete(false, new Error(nme.events.SecurityErrorEvent.SECURITY_ERROR));
            });
#end
            loader.load(new URLRequest(url));
        } catch (e: Dynamic) {
            haxe.Timer.delay(function() { oncomplete(false, e); }, 0);
        }
    }

    private inline function onDone(e: Dynamic) {
        var ba: ByteArray = cast e.target.data;
        if (onraw != null) onraw(ba);
        switch (type) {
            case IMAGE:
                var iscpp = #if cpp true #else false #end;
                if (iscpp && ba[0] == 'G'.code && ba[1] == 'I'.code && ba[2] == 'F'.code) {
                    var gifdec = new GIFDecoder();
                    gifdec.read(ba);
                    var bmd = gifdec.getFrameCount() > 0 ? gifdec.getImage().bitmapData : new BitmapData(0, 0);
                    oncomplete(true, bmd);
                } else { // not a gif image or it's on flash target
                    var ldr = new Loader();
                    var imageDone = function(_) {
                        var bmd = cast(ldr.content, Bitmap).bitmapData;
                        oncomplete(true, bmd);
                    }
                    ldr.loadBytes(ba);
                    if (ldr.content != null) {
                        imageDone(null);
                    } else {
                        var ldri = ldr.contentLoaderInfo;
                        ldri.addEventListener(Event.COMPLETE, imageDone);
                    }
                }
            case TEXT:
                oncomplete(true, ba.toString());
            case BINARY:
                oncomplete(true, ba);
        }
    }

}
