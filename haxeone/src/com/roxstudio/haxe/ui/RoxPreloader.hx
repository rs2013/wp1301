package com.roxstudio.haxe.ui;

#if cpp
import com.roxstudio.haxe.utils.SimpleJob;
import com.roxstudio.haxe.utils.Worker;
#end
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.net.RoxURLLoader;
import format.zip.Reader;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import Lambda;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.ProgressEvent;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Loader;
import nme.display.Sprite;
import nme.utils.ByteArray;

using StringTools;
using com.roxstudio.haxe.io.IOUtil;

class RoxPreloader extends EventDispatcher {

    public var progress: Float = 0.0;

    private static inline var DYN = "***";
    private var step: Float;
    private var autoUnzip: Bool;
    private var list: List<String>;
    private var bundleId: String;
    private var idmap: Hash<String>;
    private var zipImages: Hash<Loader>;
#if cpp
    private var worker: Worker;
#end

    public function new(urls: Array<String>, ?ids: Array<String>, ?bundleId: String, ?autoUnzip: Bool = false) {
        super();
        if (ids != null && ids.length != urls.length) throw "ID array must be of same length to URL array.";
        if (ids == null) ids = urls;
        this.bundleId = bundleId;
        this.autoUnzip = autoUnzip;
        idmap = new Hash<String>();
        for (i in 0...urls.length) idmap.set(urls[i], ids[i]);

        step = 1 / urls.length;
        list = new List<String>();
        zipImages = new Hash<Loader>();
#if cpp
        worker = new Worker();
#end
        for (i in 0...urls.length) {
            var url = urls[i];
            var prefix = url.length > 7 ? url.substr(0, 7) : "";
            switch (prefix) {
                case "http://":
                    download(url);
                case "https:/":
                    download(url);
#if cpp
                case "file://":
                    worker.addJob(new SimpleJob<Dynamic>({ url: url, data: null }, load, loadComplete));
#end
                case "assets:":
                    list.add(url.substr(9));
                default:
                    list.add(url);
            }
        }
        if (list.length > 0) {
            nme.Lib.current.stage.addEventListener(Event.ENTER_FRAME, update);
        }
    }

    private function update(_) {
        if (list.length == 0) {
            nme.Lib.current.stage.removeEventListener(Event.ENTER_FRAME, update);
            return;
        }
        var s = list.pop();
        trace("update: assets=" + s);
        var data: Dynamic = switch (ext(s)) {
            case DYN: {};
            case "png": ResKeeper.loadAssetImage(s);
            case "jpg": ResKeeper.loadAssetImage(s);
            case "jpeg": ResKeeper.loadAssetImage(s);
            case "txt": ResKeeper.loadAssetText(s);
            case "xml": ResKeeper.loadAssetText(s);
            case "json": ResKeeper.loadAssetText(s);
            case "mp3": ResKeeper.loadAssetSound(s);
            case "wav": ResKeeper.loadAssetSound(s);
            case "ogg": ResKeeper.loadAssetSound(s);
            default: ResKeeper.loadAssetData(s);
        }
        addData(s, data);
    }

    private function download(url: String) {
        trace("download: url=" + url + ",ext="+ext(url));
        var type = switch (ext(url)) {
            case "png": RoxURLLoader.IMAGE;
            case "jpg": RoxURLLoader.IMAGE;
            case "jpeg": RoxURLLoader.IMAGE;
            case "txt": RoxURLLoader.TEXT;
            case "xml": RoxURLLoader.TEXT;
            case "json": RoxURLLoader.TEXT;
            default: RoxURLLoader.BINARY;
        }
        var ldr = new RoxURLLoader(url, type);
        ldr.addEventListener(Event.COMPLETE, onComplete);
    }

    private inline function onComplete(e: Dynamic) {
        trace("oncomplete: e.target=" + e.target);
        var ldr = cast(e.target, RoxURLLoader);
        addData(ldr.url, ldr.data);
    }

#if cpp
    private function load(d: Dynamic) {
        trace("load: d=" + d);
        var url = d.url;
        var path = ResKeeper.url2path(url);
        var data: Dynamic = switch (ext(path)) {
            case DYN: {};
            case "png": ResKeeper.loadLocalImage(path);
            case "jpg": ResKeeper.loadLocalImage(path);
            case "jpeg": ResKeeper.loadLocalImage(path);
            case "txt": ResKeeper.loadLocalText(path);
            case "xml": ResKeeper.loadLocalText(path);
            case "json": ResKeeper.loadLocalText(path);
            default: ResKeeper.loadLocalData(path);
        }
        d.data = data;
    }

    private function loadComplete(d: Dynamic) {
        trace("loadComp: d=" + d);
        addData(d.url, d.data);
    }
#end

    private function addData(id: String, data: Dynamic) {
        if (!autoUnzip || !id.endsWith(".zip")) {
            ResKeeper.add(idmap.get(id), data, bundleId);
        } else {
            var r = new Reader(new BytesInput(cast(data, ByteArray).rox_toBytes()));
            var prefix = idmap.get(id) + "/";
            var zipdata = r.read();
            for (e in zipdata) {
                var bytes: Bytes;
                if ((bytes = e.data) == null) continue; // directory
                trace("entry " + e.fileName +",len=" + e.fileSize+",data="+e.data.length+",datasize="+e.dataSize);
                var name = prefix + e.fileName;
//                trace("zipentry: name=" + e.fileName + ",id=" + name);
                var data: Dynamic = switch (ext(name)) {
                    case DYN: {};
                    case "png": bytes2image(name, bytes); null;
                    case "jpg": bytes2image(name, bytes); null;
                    case "jpeg": bytes2image(name, bytes); null;
                    case "txt": bytes.readString(0, bytes.length);
                    case "xml": bytes.readString(0, bytes.length);
                    case "json": bytes.readString(0, bytes.length);
                    default: bytes.rox_toByteArray();
                }
                if (data != null) ResKeeper.add(name, data, bundleId);
            }
        }

//        trace(">>>>progress=" + progress);
        progress += step;
        if (progress + step > 1) {
            zipImageDone();
        } else {
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, Std.int(progress * 100), 100));
        }
    }

    private function bytes2image(id: String, bytes: Bytes) {
        var bb = bytes.rox_toByteArray();
        var ldr = new Loader();
        ldr.loadBytes(bb);
        zipImages.set(id, ldr);
        var imageDone = function(_) {
            zipImageDone(id);
        }
        if (ldr.content != null) {
            imageDone(null);
        } else {
            var ldri = ldr.contentLoaderInfo;
            ldri.addEventListener(Event.COMPLETE, imageDone);
        }
    }

    private function zipImageDone(?id: String) {
        if (id != null) {
            var ldr = zipImages.get(id);
            var data = cast(ldr.content, Bitmap).bitmapData;
            ResKeeper.add(id, data, bundleId);
            zipImages.remove(id);
        }
        if (progress + step > 1 && Lambda.count(zipImages) == 0)
            dispatchEvent(new Event(Event.COMPLETE));
    }

    private inline static function ext(s: String) : String {
        var idx = s.lastIndexOf(".");
        return idx > 0 ? s.toLowerCase().substr(idx + 1) : "";
    }

}
