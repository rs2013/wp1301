//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

import flambe.asset.AssetEntry.AssetFormat;
import flambe.display.FillSprite;
import flambe.display.Sprite;
import flambe.display.Font;
import flambe.debug.FpsDisplay;
import flambe.display.TextSprite;
import flambe.Entity;
import haxe.Json;
import flambe.util.Promise;
import flambe.asset.AssetPack;
import flambe.asset.Manifest;
import flambe.System;

using StringTools;

class Main {

//    private static inline var BASE = "http://localhost:7000";
//    private static inline var BASE = "http://www.appmagics.cn/download/fl";
//    private static inline var DIR = "/data1";

    public static var pack: AssetPack;
    public static var status: Dynamic;

    private static function main() {
        System.init();
        System.stage.lockOrientation(Landscape);

        var progBg = new FillSprite(0xFFFFFFFF, System.stage.width * 0.8, 40).centerAnchor().setXY(System.stage.width / 2, System.stage.height / 2);
        var progFg: FillSprite = new FillSprite(0xFF0000FF, 0, 30);
        progFg.setXY(5, 5);

        var progress = new Entity().add(progBg);
        progress.addChild(new Entity().add(progFg));
        System.root.addChild(progress);

#if flash
        var id = "38";
#else
        var href = untyped __js__("document.location.href");
        var id = href.substring(href.indexOf("id=") + 3);
#end
        var statusUrl = "http://www.appmagics.cn/api/statuses/show/" + id + ".json";

        var onerror = function(message) {
            trace("Loading error: " + message);
        };
        var onprogress = function(loader: Promise<AssetPack>) {
            trace("Loading progress... " + loader.progress + " of " + loader.total);
        }
        var doProgress = function(p: Float) {
            progFg.setSize((System.stage.width * 0.8 - 10) * p, 30);
        }

        var loader = System.loadAssetPack(Manifest.build("res"));
        loader.error.connect(onerror);
        loader.progressChanged.connect(onprogress.bind(loader));
        loader.success.connect(function (pack) {
            Main.pack = pack;
            doProgress(0.6);
            var manifest = new Manifest();
            manifest.add("status", statusUrl);
            var loader = System.loadAssetPack(manifest);
            loader.error.connect(onerror);
            loader.progressChanged.connect(onprogress.bind(loader));
            loader.success.connect(function (pack: AssetPack) {
                doProgress(0.7);
                status = Json.parse(pack.getFile("status").toString()).statuses[0];
//                trace(status);
                var manifest = new Manifest();
                manifest.add("data", inZipUrl(status.attachments[0].attachUrl, status.gameType, "data.json"));
                var loader = System.loadAssetPack(manifest);
                loader.error.connect(onerror);
                loader.progressChanged.connect(onprogress.bind(loader));
                loader.success.connect(function (pack: AssetPack) {
                    doProgress(0.8);
                    var data = Json.parse(pack.getFile("data").toString());
//                    trace(data);
                    var manifest = new Manifest();
                    manifest.add("image", inZipUrl(status.attachments[0].attachUrl, status.gameType, data.image), AssetFormat.JPG);
                    manifest.add("tiles", inZipUrl(status.attachments[0].attachUrl, status.gameType, "tiles.png"), AssetFormat.PNG);
                    var loader = System.loadAssetPack(manifest);
                    loader.error.connect(onerror);
                    loader.progressChanged.connect(onprogress.bind(loader));
                    loader.success.connect(function (pack: AssetPack) {
//                        trace("done,pack="+pack);
                        var tiles = pack.getTexture("tiles");
                        var image = pack.getTexture("image");
                        var game = switch (status.gameType) {
                            case "jigsaw": new Jigsaw(data, image, tiles);
                            case "slidepuzzle": new SlidePuzzle(data, image, tiles);
                            case "swappuzzle": new SwapPuzzle(data, image, tiles);
                            case _: null;
                        }
                        progress.dispose();
                        System.root.add(game);
//                        var font = new Font(Main.pack, "tinyfont");
//                        System.root.addChild(new Entity()
//                        .add(new TextSprite(font))
//                        .add(new FpsDisplay()));
                    });
                });
            });
        });

    }

    private static inline function inZipUrl(url: String, type: String, file: String) {
//        trace("inzipurl:"+(url.replace("/attach/", "/gametool/") + "?type=" + type + "&file=" + file));
        return url.replace("/attach/", "/gametool/") + "?type=" + type + "&file=" + file;
    }

}
