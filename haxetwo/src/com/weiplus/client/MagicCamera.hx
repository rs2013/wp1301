package com.weiplus.client;

import ru.stablex.ui.widgets.Scroll;
import com.weiplus.client.TimelineScreen;
import sys.io.File;
import haxe.Json;
import com.roxstudio.haxe.ui.UiUtil;
import com.weiplus.client.TimelineScreen;
import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.ui.UiUtil;
import flash.display.BitmapEncodingColorSpace;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import ru.stablex.ui.events.DndEvent;
import ru.stablex.ui.Dnd;
import ru.stablex.ui.widgets.VBox;
import flash.events.MouseEvent;
import ru.stablex.ui.widgets.Bmp;
import com.roxstudio.i18n.I18n;
import com.roxstudio.haxe.game.BmdUtil;
import ru.stablex.ui.skins.Img;
import com.roxstudio.haxe.io.FileUtil;
import ru.stablex.ui.widgets.Button;
import ru.stablex.ui.widgets.HBox;
import ru.stablex.ui.UIBuilder;
import ru.stablex.ui.misc.BtnState;
import ru.stablex.ui.widgets.Widget;
import Lambda;
import ru.stablex.ui.widgets.StateButton;
import ru.stablex.ui.UIBuilder;
import com.roxstudio.haxe.ui.DipUtil;
import flash.Lib;
import com.roxstudio.haxe.game.GfxUtil;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.io.IOUtil;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import flash.geom.Point;
import com.roxstudio.haxe.ui.UiUtil;
import flash.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxScreen;
import com.weiplus.client.model.AppData;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxFlowPane;
import flash.display.Shape;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.ui.DipUtil;
using com.roxstudio.i18n.I18n;

class MagicCamera extends MakerScreen {

    private static inline var ALBUM_DIR = "/sdcard/DCIM/MagicCamera";
    private var currentCid = -1;
    private var currentAr: Sprite;
    private var getBmd: Bool;

    public function new() {
        super();
//        disposeAtFinish = false;
        hasTitleBar = false;
    }

    override public function createContent(height: Float) : Sprite {
        content = UIBuilder.buildFn("ui/haxe_camera.xml")();

        showFolder();
        trace("content created");
        return content;
    }

    override public function onNewRequest(data: Dynamic) {
        getBmd = data == null;
    }

    private function showFolder() {
        var data = restoreCache("arfolders.json");
        if (data != null) {
            UiUtil.delay(folderLoaded.bind(200, data, false));
            HpApi.instance.get("/ar/catalogs/list", { sinceId: 0, rows: 100 }, folderLoaded.bind(_, _, true));
        } else {
            HpApi.instance.get("/ar/catalogs/list", { sinceId: 0, rows: 100 }, folderLoaded.bind(_, _, false));
        }
    }

    override public function onDestroy() {
        trace("onDestroy");
        if (currentCid >= 0) {
            var bundleId = "ar_folder_" + currentCid;
            ResKeeper.disposeBundle(bundleId);
        }
        UIBuilder.get("HaxeCamera").free(true);
    }

    override public function onBackKey() {
        trace("onBackKey: currentCid="+currentCid+",frame2.visible="+UIBuilder.get("CameraFrame2").visible);
        if (UIBuilder.get("CameraFrame2").visible) { // cancel snap
            trace("onBackKey: to cancel snap");
            cancelSnap();
            return false;
        } else if (currentCid >= 0) {
            var bundleId = "ar_folder_" + currentCid;
            ResKeeper.disposeBundle(bundleId);
            currentCid = -1;
//            UIBuilder.get("folderList").parent.visible = true;
//            UIBuilder.get("arList").parent.visible = false;
            showFolder();
            return false;
        }
        return true;
    }

    private function folderLoaded(code: Int, data: Dynamic, updateCacheOnly: Bool) {
        trace("folderLoaded: code="+code+",data="+data+",updateCacheOnly="+updateCacheOnly);
        if (code != 200) {
            UiUtil.message("网络错误. code=".i18n() + code + ",message=" + data);
            return;
        }
        storeCache("arfolders.json", data);
        if (updateCacheOnly) return;

        var folderList: HBox = UIBuilder.getAs("folderList", HBox);
        if (folderList == null) return; // screen freed
        folderList.rox_removeAll();

        for (c in cast(data.catalogs.records, Array<Dynamic>)) {
//            w="(140).dp()" h="(140).dp()" skin:Paint-border="1" skin:Paint-color="0x00FF00" text="'folder'" />
            var folder: Button = UIBuilder.create(Button, {
                defaults: "ArFolderButtons",
                text: "", //c.name,
                userData: { id: c.id, url: c.icon }
            });
            folder.addEventListener(MouseEvent.CLICK, function(_) {
                var name = "arlist_" + c.id + ".json";
                var data = restoreCache(name);
                if (data != null) {
                    UiUtil.delay(arLoaded.bind(200, data, name, false));
                    HpApi.instance.get("/ar/goods/by_catalog/" + c.id, { sinceId: 0, rows: 100 }, arLoaded.bind(_, _, name, true));
                } else {
                    HpApi.instance.get("/ar/goods/by_catalog/" + c.id, { sinceId: 0, rows: 100 }, arLoaded.bind(_, _, name, false));
                }
//                folderList.parent.visible = false;
                currentCid = c.id;
            });
            folderList.addChild(folder);
            MyUtils.asyncArImage(c.icon, function(bmd) {
                if (bmd == null || bmd.width == 0) {
                    trace("load AR folder failed, id=" + c.id + ",url=" + c.icon);
                    return;
                }
                folder.ico = new Bmp();
                folder.ico.bitmapData = BmdUtil.transform(bmd, "resize", [ (132).dp(), (132).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
                folder.refresh();
            });
        }
        var scroll: Scroll = cast folderList.parent;
        scroll.tweenStop();
        scroll.scrollX = 0;
    }

    private function arLoaded(code: Int, data: Dynamic, cacheFilename: String, updateCacheOnly: Bool) {
        trace("arLoaded: code="+code+",data="+data+",cache="+cacheFilename+",updatecacheOnly="+updateCacheOnly);
        if (code != 200) {
            UiUtil.message("网络错误. code=".i18n() + code + ",message=" + data);
            return;
        }
        storeCache(cacheFilename, data);
        if (updateCacheOnly) return;

        var folderList: HBox = UIBuilder.getAs("folderList", HBox);
        if (folderList == null) return; // screen freed
        folderList.rox_removeAll();
        var canvas = UIBuilder.get("CameraCanvas");

        var btn: Button = UIBuilder.create(Button, {
            defaults: "ArFolderButtons",
            text: ""
        });
        btn.ico = new Bmp();
        btn.ico.bitmapData = BmdUtil.transform(ResKeeper.getAssetImage("res/icon_ar_prev.png"), "resize", [ (100).dp(), (100).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
        btn.addEventListener(MouseEvent.CLICK, function(_) {
            onBackKey();
        });
        btn.refresh();
        folderList.addChild(btn);

        for (c in cast(data.goods.records, Array<Dynamic>)) {
//            w="(140).dp()" h="(140).dp()" skin:Paint-border="1" skin:Paint-color="0x00FF00" text="'folder'" />
            var btn: Button = UIBuilder.create(Button, {
                defaults: "ArFolderButtons",
                text: "",
                userData: { id: c.id, url: c.image }
            });
            var bundleId = "ar_folder_" + currentCid;
            MyUtils.asyncArImage(c.image, function(bmd) {
                if (bmd == null || bmd.width == 0) {
                    trace("load AR failed, id=" + c.id + ",url=" + c.image);
                    return;
                }
                btn.ico = new Bmp();
                btn.ico.bitmapData = BmdUtil.transform(bmd, "resize", [ (132).dp(), (132).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
                btn.addEventListener(MouseEvent.CLICK, function(_) {
                    var sp = new Sprite();
                    sp.graphics.rox_drawRegion(bmd, null, 0, 0);
                    sp.rox_scale(DipUtil.dpFactor);
                    var obj: Widget = UIBuilder.create(Widget, { defaults: "ArObject" });
                    obj.addChild(sp);
                    obj.top += (-bmd.height / 2) * DipUtil.dpFactor;
                    obj.left += (-bmd.width / 2) * DipUtil.dpFactor;
                    obj.userData = bmd;
                    var agent = new RoxGestureAgent(obj);
                    obj.addEventListener(MouseEvent.MOUSE_DOWN, function(_) { trace("mouse down"); });
                    obj.addEventListener(RoxGestureEvent.GESTURE_ROTATION, handleEvent);
                    obj.addEventListener(RoxGestureEvent.GESTURE_PINCH, handleEvent);
                    obj.addEventListener(RoxGestureEvent.GESTURE_PAN, handleEvent);
                    obj.addEventListener(RoxGestureEvent.GESTURE_LONG_PRESS, handleEvent);
//                    obj.addEventListener(MouseEvent.MOUSE_DOWN, function(_) { Dnd.drag(obj); });
//                    obj.addEventListener(DndEvent.DROP, function(e) { e.drop(); });
                    canvas.addChild(obj);
                });
                btn.refresh();
            }, bundleId);
            folderList.addChild(btn);
        }
        var scroll: Scroll = cast folderList.parent;
        scroll.tweenStop();
        scroll.scrollX = 0;

    }

    private function restoreCache(filename: String) : Dynamic {
        var cache = ResKeeper.get("cache:" + filename);
        if (cache != null) return cache;
        var path = TimelineScreen.CACHE_DIR + "/" + filename;
        if (sys.FileSystem.exists(path)) {
            return Json.parse(File.getContent(path));
        }
        return null;
    }

    private function storeCache(filename: String, data: Dynamic) {
        FileUtil.mkdirs(TimelineScreen.CACHE_DIR);
        var path = TimelineScreen.CACHE_DIR + "/" + filename;
        var jsonStr = Json.stringify(data);
        File.saveContent(path, jsonStr);
        ResKeeper.add("cache:" + filename, data, ResKeeper.DEFAULT_BUNDLE);
    }

    private function handleEvent(e: RoxGestureEvent) {
//        trace(">>>t=" + e.target.name+",o="+owner.name+",e="+e);
        var obj: Widget = cast(e.target);
        if (obj.defaults != "ArObject") return;
        var canvas = UIBuilder.get("CameraCanvas");
        if (canvas.numChildren > 1) canvas.swapChildren(obj, canvas.getChildAt(canvas.numChildren - 1));
        var sp: Sprite = cast obj.getChildAt(0);
//        trace("sp=" + sp + ",obj=" + obj + ",def=" + obj.defaults);
        var menu = UIBuilder.get("ArObjectMenu");
        menu.visible = false;
        switch (e.type) {
            case RoxGestureEvent.GESTURE_PAN:
                var pt: Point = cast(e.extra);
                obj.x += pt.x;
                obj.y += pt.y;
            case RoxGestureEvent.GESTURE_PINCH:
                var scale: Float = e.extra;
                var dx = obj.x - e.stageX, dy = obj.y - e.stageY;
                var angle = Math.atan2(dy, dx);
                var nowlen = new Point(dx, dy).length;
                var newlen = nowlen * scale;
                var newpos = Point.polar(newlen, angle);
                newpos.offset(e.stageX, e.stageY);
//                newpos = sp.parent.globalToLocal(newpos);
                sp.scaleX *= scale;
                sp.scaleY *= scale;
                obj.x = newpos.x;
                obj.y = newpos.y;

//                var scale: Float = e.extra;
//                sp.scaleX *= scale;
//                sp.scaleY *= scale;
            case RoxGestureEvent.GESTURE_ROTATION:
                var angle: Float = e.extra;
                var dx = obj.x - e.stageX, dy = obj.y - e.stageY;
                var nowang = Math.atan2(dy, dx);
                var length = new Point(dx, dy).length;
                var newang = nowang + angle;
                var newpos = Point.polar(length, newang);
                newpos.offset(e.stageX, e.stageY);
//                newpos = sp.parent.globalToLocal(newpos);
                sp.rotation += 180 / Math.PI * angle;
                obj.x = newpos.x;
                obj.y = newpos.y;
//                var angle: Float = e.extra;
//                sp.rotation += 180 / Math.PI * angle;
            case RoxGestureEvent.GESTURE_LONG_PRESS:
                menu.visible = true;
                canvas.swapChildren(menu, canvas.getChildAt(canvas.numChildren - 1));
                if (e.stageX < screenWidth / 2) { menu.left = e.stageX; } else { menu.left = e.stageX - menu.w; }
                if (e.stageY < screenHeight / 2) { menu.top = e.stageY; } else { menu.top = e.stageY - menu.h; }
                currentAr = sp;
        }
        updateBounds(obj);
    }

    private function updateBounds(obj: Widget) {
//        var bound: Shape = obj.numChildren > 1 ? cast(obj.getChildAt(obj.numChildren - 1), Shape) : new Shape();
//        var rect = obj.getChildAt(0).getRect(flash.Lib.current.stage);
//        trace("rect=" + rect.x + "," + rect.y+","+rect.width+","+rect.height);
//        bound.graphics.clear();
//        bound.graphics.rox_drawRect(2, 0xFFFFFFFF, rect.x - obj.x, rect.y - obj.y, rect.width, rect.height);
//        obj.addChild(bound);
    }

    override public function drawBackground() { // suppress drawing default background
    }


    override public function onShown() {
        trace("onShown");
        var frame = UIBuilder.get("CameraFrame2");
        if (frame != null && frame.visible) return;
#if android
        flash.Lib.current.stage.opaqueBackground = 0x00000000;
        var camId = HaxeCamera.getCurrentCameraId();
        if (camId < 0) camId = 0;
        trace("openCamera: camId="+camId);
        HaxeCamera.openCamera(camId, this, "cameraOpened");
#else
        cameraOpened("ok", null);
#end
    }

    override public function onHidden() {
        trace("onHidden");
#if android
        flash.Lib.current.stage.opaqueBackground = 0xFF000000;
        HaxeCamera.closeCamera();
#end
    }

    private function cameraOpened(resultCode: String, resultData: String) {
        trace("cameraOpened: result="+resultCode+",data="+resultData);
        UiUtil.delay(resetUi);
    }

    private function dummy(resultCode: String, resultData: String) {
    }

    private function resetUi() {

        var numCams = #if android HaxeCamera.getNumberOfCameras() #else 2 #end;
        if (numCams <= 1) {
            UIBuilder.get('btnSwitch').visible = false;
        }
        var modeNames = [ "auto" => "自动".i18n(), "on" => "开启".i18n(), "off" => "关闭".i18n() ];
        var modes: Array<String> = #if android HaxeCamera.getFlashModes() #else [ "auto", "on", "off" ] #end;
        var btn: StateButton = UIBuilder.getAs('btnFlash', StateButton);
        trace("btnFlash=" +  btn + ",visible=" + btn.visible + ",modes=" + modes);
        if (modes.length > 1) {
            btn.order = modes;
            trace("modes=" + modes);
//            btn.states = new ru.stablex.DynamicList(BtnState);
            for (m in btn.order) {
                btn.states.resolve(m).text = modeNames.get(m);
                trace("m=" + m + ",txt=" + btn.states.resolve(m).text);
            }
            btn.state = modes[0];
            btn.visible = true;
        } else {
            btn.visible = false;
        }
        trace("btnFlash=" +  btn + ",visible=" + btn.visible + ",state=" + btn.state);
//#if android
//        HaxeCamera.openCamera(HaxeCamera.getCurrentCameraId(), this, "dummy"); // ensure camera is opened
//#end
    }

    private function switchCamera() {
        trace("switchCamera");
#if android
        var numCams = HaxeCamera.getNumberOfCameras();
        HaxeCamera.openCamera((HaxeCamera.getCurrentCameraId() + 1) % numCams, this, "cameraOpened");
#end
    }

    private function switchFlashMode() {
#if android
        HaxeCamera.switchFlashMode();
#end
    }

#if cpp
//    private var thread1: cpp.vm.Thread;
//    private var thread2: cpp.vm.Thread;
//    private var thread3: cpp.vm.Thread;
#end

    private function doSnap() {
        trace("doSnap");
#if cpp
//        thread1 = cpp.vm.Thread.current();
#end

        UIBuilder.get("ArObjectMenu").visible = false;
#if android
        if (!sys.FileSystem.exists(ALBUM_DIR)) com.roxstudio.haxe.io.FileUtil.mkdirs(ALBUM_DIR);
        var name = "IMG_" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
        var snapPath = ALBUM_DIR + "/" + name;
        HaxeCamera.snap(snapPath, this, "snapped");
#else
        UiUtil.delay(function() {
            snapped("ok", "res/8.jpg");
        });
#end
        trace("end dosnap");
    }

    private function snapped(resultCode: String, resultData: String) {
#if cpp
//        thread2 = cpp.vm.Thread.current();
#end

        trace("snapped, code=" + resultCode + ",data=" + resultData);
        if (resultCode != "ok") {
            trace("Snap failed. error=" + resultData);
            return;
        }
        UiUtil.runOnUiThread(function() { safeSnapped(resultData); });
    }

    private function safeSnapped(path: String) {
#if cpp
//        thread3 = cpp.vm.Thread.current();
//        trace("thread1==thread2?" + (thread1==thread2));
//        trace("thread2==thread3?" + (thread2==thread3));
//        trace("thread1==thread3?" + (thread1==thread3));
#end

#if android
        var bmd = ResKeeper.loadLocalImage(path);
#else
        var bmd = ResKeeper.loadAssetImage(path);
#end
        if (bmd == null) {
            trace("snapped: bmd is null");
            return;
        }
        UIBuilder.get("CameraFrame").visible = false;
        UIBuilder.get("CameraPreview").visible = true;
        var bmp: Bmp = UIBuilder.getAs("CameraPreviewBmp", Bmp);
        bmp.bitmapData = bmd;
        bmp.userData = path;
        bmp.smooth = true;
        bmp.scaleX = bmp.scaleY = screenWidth / bmd.width;
        bmp.top = (screenHeight - (bmd.height * bmp.scaleX)) / 2;
        bmp.refresh();
        UIBuilder.get("CameraFrame2").visible = true;
        trace("end snapped");
    }

    private function confirmSnap() {
        trace("confirmSnap");
        var bmp: Bmp = UIBuilder.getAs("CameraPreviewBmp", Bmp);
        var origbmd = bmp.bitmapData;
        var scale = bmp.scaleX;
        var offy = bmp.top / scale;
        var canvas = UIBuilder.get("CameraCanvas");
        trace("bmd: scale="+scale+",offy="+offy);
        var bmd = new BitmapData(origbmd.width, origbmd.height, true, 0);
        bmd.copyPixels(origbmd, new Rectangle(0, 0, origbmd.width, origbmd.height), new Point(0, 0));
        for (i in 0...canvas.numChildren) {
            var arobj = cast(canvas.getChildAt(i), Widget);
            if (arobj.id == "ArObjectMenu") continue;
            var arsp = arobj.getChildAt(0);
            var arbmd: BitmapData = cast arobj.userData;
            var arscalex = arsp.scaleX / scale, arscaley = arsp.scaleY / scale;
            var arangle = arscalex > 0 ? arsp.rotation : -arsp.rotation;
            var dx = arobj.left / scale;
            var dy = arobj.top / scale - offy;
            var mat = new Matrix();
            mat.rotate(((arangle + 360) % 360) * Math.PI / 180);
            mat.translate(dx / arscalex, dy / arscaley);
            mat.scale(arscalex, arscaley);
            trace("ar["+i+"]: arscx=" + arsp.scaleX + ",arscale="+arscalex+","+arscaley+",arangle="+arangle+",dx="+dx+",dy="+dy);
            bmd.draw(arbmd, mat, true);
        }
//#if cpp
//        var name = "bbb_" + Std.random(10000) + ".jpg";
//        sys.io.File.saveBytes(#if android "/sdcard/" + name #else name #end, GameUtil.encodeJpeg(bmd));
//#end
        if (getBmd) {
            finish(RoxAnimate.NO_ANIMATE, RoxScreen.OK, bmd);
            trace("MagicCamera finish: OK");
        } else {
            image = { path: null, bmd: bmd };
            var appdata: AppData = status.appData;
            appdata.width = image.bmd.width;
            appdata.height = image.bmd.height;
            appdata.type = "image";
            onHidden();
            onNextStep();
            trace("MagicCamera nextStep");
        }

        trace("end confirmSnap");
    }

    private function cancelSnap() {
        UIBuilder.get("CameraFrame").visible = true;
        UIBuilder.get("CameraPreview").visible = false;
        UIBuilder.get("CameraFrame2").visible = false;
        onShown();
    }

}
