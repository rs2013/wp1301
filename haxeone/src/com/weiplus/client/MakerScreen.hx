package com.weiplus.client;

using com.roxstudio.i18n.I18n;
import nme.geom.Point;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.weiplus.client.model.AppData;
import com.roxstudio.haxe.game.GameUtil;
import nme.display.Sprite;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.game.ResKeeper;
import com.weiplus.client.model.AppData;
import com.weiplus.client.model.Status;
import haxe.Json;
import nme.display.BitmapData;
import nme.geom.Rectangle;
import nme.utils.ByteArray;
#if cpp
import com.roxstudio.haxe.utils.SimpleJob;
import sys.io.File;
import sys.FileSystem;
#end

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.io.IOUtil;
using com.roxstudio.haxe.ui.UiUtil;

class MakerScreen extends BaseScreen {

    public var btnNextStep: RoxFlowPane;
    public var status: Status;
    public var image: { var bmd: BitmapData; var path: String; }; // appData.image
    public var data: Dynamic; // to be stored in the zip with filename "data.json", the image members will be encoded to jpeg format

#if android
    private static inline var MAKER_DIR = "/sdcard/.harryphoto/maker";
#elseif windows
    private static inline var MAKER_DIR = "maker";
//    private static inline var MAKER_DIR = "D:/tmp/maker";
#end

    override public function onCreate() {
        status = new Status();
        var appdata: AppData = status.appData = new AppData();
        appdata.id = "fromMaker";
        image = null;
        data = {};
        btnNextStep = UiUtil.button(UiUtil.TOP_LEFT, null, "下一步".i18n(), 0xFFFFFF, titleFontSize, "res/btn_common.9.png", function(_) { onNextStep(); } );
        super.onCreate();
//        addTitleButton(btnNextStep, UiUtil.RIGHT);
    }

    public function onNextStep() {
        // can be overrided by sub-classes
        var text = "处理中".i18n();
#if cpp
        var mask = new Sprite();
        mask.graphics.rox_fillRect(0x77000000, 0, 0, screenWidth, screenHeight);
        var loading = MyUtils.getLoadingAnim(text).rox_move(screenWidth / 2, screenHeight / 2);
        mask.addChild(loading);
        addChild(mask);
        GameUtil.worker.addJob(new SimpleJob<Dynamic>(null, packData, function(_) {
            removeChildAt(numChildren - 1);
            startScreen(Type.getClassName(PostScreen), makerData());
            trace("onNextStep: makerData=" + makerData());
        } ));
#else
        startScreen(Type.getClassName(PostScreen), makerData());
#end
    }

    private inline function makerData() {
        return { status: status, image: image, data: data };
    }

    public function packData(_) {
#if cpp
        if (FileSystem.exists(MAKER_DIR)) FileUtil.rmdir(MAKER_DIR, true);
        FileUtil.mkdirs(MAKER_DIR);
        if (image.path == null) {
            trace("start saving image");
            File.saveBytes(MAKER_DIR + "/image.jpg", GameUtil.encodeJpeg(image.bmd));
//            trace("image saved, type=\"" + status.appData.type + "\"");
        } else {
            File.copy(image.path, MAKER_DIR + "/image.jpg");
        }
        if (status.appData.type == "image") return;
        trace("start saving zip data");
        var cnt = 1;
        var out = {};
        var zipdata = new format.zip.Data();
        var ef = new List<format.zip.Data.ExtraField>();
        var now = Date.now();
        for (f in Reflect.fields(data)) {
            var v = Reflect.field(data, f);
            if (Std.is(v, BitmapData)) {
                var name = "" + (cnt++) + ".jpg";
                var bytes = GameUtil.encodeJpeg(cast(v));
                zipdata.add({ fileName: name, fileSize: bytes.length, fileTime: now, compressed: false,
                            dataSize: bytes.length, data: bytes, crc32: null, extraFields: ef });
                Reflect.setField(out, f, name);
//                ResKeeper.add(PlayScreen.ZIPDATA_NAME + "/" + name, v);
            } else {
                Reflect.setField(out, f, v);
            }
        }
        var bytes = Bytes.ofString(Json.stringify(out));
        zipdata.add({ fileName: "data.json", fileSize: bytes.length, fileTime: now, compressed: false,
                    dataSize: bytes.length, data: bytes, crc32: null, extraFields: ef });
        var output = File.write(MAKER_DIR + "/data.zip");
        var w = new format.zip.Writer(output);
#if haxe3
        w.write(zipdata);
#else
        w.writeData(zipdata);
#end
        output.close();
        trace("zip saved");
#end
    }

}
