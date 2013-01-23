package com.roxstudio.haxe.io;

import haxe.Timer;
import com.roxstudio.haxe.io.FileUtil;
import format.zip.Reader;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import nme.display.Bitmap;
import nme.display.Loader;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.utils.ByteArray;

using com.roxstudio.haxe.io.IOUtil;

class Unzipper extends EventDispatcher {

    public var completed(default, null): Bool;
    public var files(default, null): Hash<Dynamic>;
    public var prefix(default, null): String;

    private var images: Hash<Loader>;

    public function new(?zipData: ByteArray, ?prefix: String = "") {
        super();
        start(zipData, prefix);
    }

    public function start(zipData: ByteArray, ?prefix: String = "") {
        completed = false;
        files = new Hash<Dynamic>();
        images = new Hash<Loader>();
        var r = new Reader(new BytesInput(zipData.rox_toBytes()));
        var entries = r.read();
        for (e in entries) {
            var bytes: Bytes;
            if ((bytes = e.data) == null) continue; // directory
            var name = prefix + e.fileName;
            trace("entry: name=" + name +",len=" + e.fileSize+",data="+e.data.length+",datasize="+e.dataSize);
            var data: Dynamic = switch (FileUtil.fileExt(name, true)) {
                case "***": {}; // force type to Dynamic
                case "png": bytes2image(name, bytes); null;
                case "jpg": bytes2image(name, bytes); null;
                case "jpeg": bytes2image(name, bytes); null;
                case "txt": bytes.readString(0, bytes.length);
                case "xml": bytes.readString(0, bytes.length);
                case "json": bytes.readString(0, bytes.length);
                default: bytes.rox_toByteArray();
            }
            if (data != null) files.set(name, data);
        }
        zipDone();
    }

    private function bytes2image(id: String, bytes: Bytes) {
        var bb = bytes.rox_toByteArray();
        var ldr = new Loader();
        ldr.loadBytes(bb);
        images.set(id, ldr);
        var imageDone = function(_) { zipDone(id); }
        if (ldr.content != null) {
            Timer.delay(callback(imageDone, null), 1);
        } else {
            var ldri = ldr.contentLoaderInfo;
            ldri.addEventListener(Event.COMPLETE, imageDone);
        }
    }

    private function zipDone(?id: String) {
        if (id != null) {
            var ldr = images.get(id);
            var data = cast(ldr.content, Bitmap).bitmapData;
            files.set(id, data);
            images.remove(id);
        }
        if (Lambda.count(images) == 0) {
            Timer.delay(function() {
//                trace(">>>unzipper.completed, completed="+completed);
                if (completed) return;
                completed = true;
                dispatchEvent(new Event(Event.COMPLETE));
            }, 1);
        }
    }

}
