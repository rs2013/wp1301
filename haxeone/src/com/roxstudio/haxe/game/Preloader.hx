package com.roxstudio.haxe.game;

#if cpp
import com.roxstudio.haxe.utils.SimpleJob;
import com.roxstudio.haxe.utils.Worker;
#end
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.io.Unzipper;
import com.roxstudio.haxe.net.RoxURLLoader;
import haxe.Timer;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.ProgressEvent;
import nme.utils.ByteArray;

using StringTools;

class Preloader extends EventDispatcher {

    public var progress: Float = 0.0;

    private static inline var DYN = "***";
    private var step: Float;
    private var autoUnzip: Bool;
    private var list: List<String>;
    private var bundleId: String;
    private var idmap: Hash<String>;
    private var timer: Timer;
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
#if cpp
        worker = new Worker();
#end
        for (i in 0...urls.length) {
            var url = urls[i];
            trace(">>>>>>>>url=" + url);
            var prefix = url.length > 7 ? url.substr(0, 7) : "";
            switch (prefix) {
                case "http://":
                    download(url);
                case "https:/":
                    download(url);
                case "file://":
#if cpp
                    worker.addJob(new SimpleJob<Dynamic>({ url: url, data: null }, load, loadComplete));
#end
                case "assets:":
                    list.add(url.substr(9));
                default:
                    list.add(url);
            }
        }
        if (list.length > 0) {
            timer = new Timer(1);
            timer.run = loadAsset;
        }
    }

    private function loadAsset() {
        if (list.length == 0) {
            timer.stop();
            timer = null;
            return;
        }
        var s = list.pop();
//        trace("update: assets=" + s);
        var data: Dynamic = switch (FileUtil.fileExt(s, true)) {
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
        if (data != null) {
            addData("assets://" + s, data);
        } else {
            throw "Preloader: load asset " + s + " failed.";
        }
    }

    private function download(url: String) {
//        trace("download: url=" + url + ",ext="+FileUtil.fileExt(url, true));
        var type = switch (FileUtil.fileExt(url, true)) {
            case "png": RoxURLLoader.IMAGE;
            case "jpg": RoxURLLoader.IMAGE;
            case "jpeg": RoxURLLoader.IMAGE;
            case "txt": RoxURLLoader.TEXT;
            case "xml": RoxURLLoader.TEXT;
            case "json": RoxURLLoader.TEXT;
            default: RoxURLLoader.BINARY;
        }
        var ldr = new RoxURLLoader(url, type);
        ldr.addEventListener(Event.COMPLETE, downComplete);
    }

    private inline function downComplete(e: Dynamic) {
//        trace("downComplete: e.target=" + e.target);
        var ldr = cast(e.target, RoxURLLoader);
        if (ldr.status == RoxURLLoader.OK) {
            addData(ldr.url, ldr.data);
        } else {
            throw "Preloader: download " + ldr.url + " failed.";
        }
    }

#if cpp
    private function load(d: Dynamic) {
//        trace("load: d=" + d);
        var url = d.url;
        var path = ResKeeper.url2path(url);
        var data: Dynamic = switch (FileUtil.fileExt(path, true)) {
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
//        trace("loadComp: d=" + d);
        if (d.data != null) {
            addData(d.url, d.data);
        } else {
            throw "Preloader: load local file " + d.url + " failed.";
        }
    }
#end

    private function addData(id: String, data: Dynamic) {
        if (!autoUnzip || !id.endsWith(".zip")) {
            ResKeeper.add(idmap.get(id), data, bundleId);
            doProgress(null);
        } else {
            var unz = new Unzipper(cast(data, ByteArray), idmap.get(id) + "/");
            unz.addEventListener(Event.COMPLETE, doProgress);
        }
    }

    private function doProgress(e: Dynamic) {
        if (e != null) {
            var files = cast(e.target, Unzipper).files;
            for (f in files.keys()) {
                ResKeeper.add(f, files.get(f), bundleId);
            }
        }
        progress += step;
        if (progress + step > 1) {
            dispatchEvent(new Event(Event.COMPLETE));
        } else {
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, Std.int(progress * 100), 100));
        }
    }

}