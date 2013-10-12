package com.weiplus.client;

import com.roxstudio.haxe.utils.SimpleJob;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
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
using StringTools;

class MagicCamera extends MakerScreen {

    private static inline var ALBUM_DIR = MyUtils.ALBUM_DIR;

    private var currentCid = -1;
    private var currentAr: Widget;
    private var operation: Int;
    private var inputBmd: BitmapData = null;
    private var requestCode = -1;

    public function new() {
        super();
//        disposeAtFinish = false;
        hasTitleBar = false;
    }

    override public function createContent(height: Float) : Sprite {
        content = UIBuilder.buildFn("ui/haxe_camera.xml")();

        var arBoxCtrl = UIBuilder.get("ArBoxCtrl");
        var agent = new RoxGestureAgent(arBoxCtrl, RoxGestureAgent.GESTURE_CAPTURE);
        arBoxCtrl.addEventListener(RoxGestureEvent.GESTURE_PAN, function(e: RoxGestureEvent) {
            if (currentAr == null) return;
            var pt: Point = cast e.extra;
            var obj: Sprite = cast currentAr.getChildAt(0);
            var rect = obj.getRect(flash.Lib.current.stage);
            var center = new Point(rect.x + rect.width / 2, rect.y + rect.height / 2);
            var opt = new Point(e.stageX, e.stageY);
            var oang = Math.atan2(opt.y - center.y, opt.x - center.x);
            var ang = Math.atan2(pt.y, pt.x);
            var delta = (ang - oang + Math.PI * 2) % (Math.PI * 2);
//            if (delta > Math.PI * 0.25 && delta < Math.PI * 0.75 || delta > Math.PI * 1.25 && delta < Math.PI * 1.75) { // rotate
            var sdist = pt.length * Math.sin(delta);
            var angle = Math.atan2(sdist, Point.distance(center, opt));
            var evt = new RoxGestureEvent(RoxGestureEvent.GESTURE_ROTATION, 0, 0, center.x, center.y, 0, null, angle);
//                trace("rot:c="+center+",delta="+delta+",dist="+dist+",angle="+angle);
            handleEvent(evt, currentAr);
//            } else { // scale
            var cdist = pt.length * Math.cos(delta);
            var co = Point.distance(center, opt);
            var scale = (cdist + co) / co;
            var evt = new RoxGestureEvent(RoxGestureEvent.GESTURE_PINCH, 0, 0, center.x, center.y, 0, null, scale);
//                trace("scl:c="+center+",delta="+delta+",dist="+dist+",scale="+scale);
            handleEvent(evt, currentAr);
//            }
        });

        var cropBox = UIBuilder.get("CropBox");
        agent = new RoxGestureAgent(cropBox);
        cropBox.addEventListener(RoxGestureEvent.GESTURE_PAN, function(e: RoxGestureEvent) {
            if (e.target != cropBox) {
                return; // discard bubbled event
            }
//            trace("cropbox pan=" + e.extra);
            var pt: Point = cast e.extra;
            var box = UIBuilder.get("CropBox");
            if (!box.visible) return;

            var bmp: Bmp = UIBuilder.getAs("CameraPreviewBmp", Bmp);
            var bmpw = bmp.bitmapData.width * bmp.scaleX;
            var bmph = bmp.bitmapData.height * bmp.scaleY;
            box.left += pt.x;
            if (box.left < 0) box.left = 0;
            if (box.left > bmpw - box.w) box.left = bmpw - box.w;
            box.top += pt.y;
            if (box.top < bmp.top) box.top = bmp.top;
            if (box.top > bmp.top + bmph - box.h) box.top = bmp.top + bmph - box.h;
        });

        var cropCtrl = UIBuilder.get("CropBoxCtrl");
        agent = new RoxGestureAgent(cropCtrl, RoxGestureAgent.GESTURE_CAPTURE);
        cropCtrl.addEventListener(RoxGestureEvent.GESTURE_PAN, function(e: RoxGestureEvent) {
//            trace("cropCtrl pan=" + e.extra);
            var pt: Point = cast e.extra;
            var box = UIBuilder.get("CropBox");
            if (!box.visible) return;

            var bmp: Bmp = UIBuilder.getAs("CameraPreviewBmp", Bmp);
            var bmpw = bmp.bitmapData.width * bmp.scaleX;
            var bmph = bmp.bitmapData.height * bmp.scaleY;
            box.w += pt.x;
            if (box.w < bmpw / 2) box.w = bmpw / 2;
            if (box.w > bmpw - box.left) box.w = bmpw - box.left;
            box.h += pt.y;
            if (box.h < bmph / 2) box.h = bmph / 2;
            if (box.h > bmp.top + bmph - box.top) box.h = bmp.top + bmph - box.top;
        });

        showFolder(null, -1, false);

        this.addEventListener(Event.ACTIVATE, onActive);

        return content;
    }

    override public function onNewRequest(data: Dynamic) {
        operation = data.operation;
        if (operation == 3) { // edit pic only
            requestCode = 11;
            inputBmd = data.bmd;
            onActive(null);
        }
    }

    private function showFolder(_, cid: Int, forceUpdate = false) {
        trace("showFolder, cid=" + cid + ",forceUpdate=" + forceUpdate);
        var cachefile = cid == -1 ? "arfolders.json" : "arlist_" + cid + ".json";
        var data = restoreCache(cachefile);
        if (data == null) forceUpdate = true;
        if (!forceUpdate) {
            if (cid == -1) {
                UiUtil.delay(folderLoaded.bind(data));
            } else {
                UiUtil.delay(arLoaded.bind(data));
            }
        } else {
            MyUtils.showWaiting("更新中".i18n());
            var reqUrl = cid == -1 ? "/ar/catalogs/list" : "/ar/goods/by_catalog/" + cid;
            HpApi.instance.get(reqUrl, { sinceId: 0, rows: 100 }, function(code: Int, data: Dynamic) {
                if (code != 200) {
                    UiUtil.message("网络错误. code=".i18n() + code + ",message=" + data);
                    return;
                }
                storeCache(cachefile, data);
                var queue: List<String> = new List();
                if (cid == -1) {
                    for (c in cast(data.catalogs.records, Array<Dynamic>)) {
                        if (!MyUtils.arCacheExists(c.icon)) queue.add(c.icon);
                    }
                } else {
                    for (c in cast(data.goods.records, Array<Dynamic>)) {
                        if (!MyUtils.arCacheExists(c.image)) queue.add(c.image);
                    }
                }
                var count = queue.length;
                var runner: Void -> Void = null;
                runner = function() {
                    var url = queue.pop();
                    if (url == null) { // all jobs completed
                        MyUtils.hideWaiting();
                        var txt = cid == -1 ? "个新目录".i18n() : "个新魔贴".i18n();
                        UiUtil.message("更新完成，更新了".i18n() + count + txt);
                        if (cid == -1) {
                            folderLoaded(data);
                        } else {
                            arLoaded(data);
                        }
                    } else {
                        MyUtils.asyncArImage(url, function(isOk) {
                            if (!isOk) {
                                trace("load AR folder failed, id=" + cid + ",url=" + url);
                            }
                            runner();
                        });
                    }
                };
                runner();
            });
        }
    }

    override public function onDestroy() {
        trace("onDestroy");
        UIBuilder.get("HaxeCamera").free(true);
    }

    override public function onBackKey() {
        trace("onBackKey: currentCid="+currentCid+",frame2.visible="+UIBuilder.get("CameraFrame2").visible);
        if (currentCid >= 0) {
            currentCid = -1;
//            UIBuilder.get("folderList").parent.visible = true;
//            UIBuilder.get("arList").parent.visible = false;
            showFolder(null, -1, false);
            return false;
        } else if (operation == 3) {
            return true;
        } else if (UIBuilder.get("CameraFrame2").visible) { // cancel snap
//            trace("onBackKey: to cancel snap");
            cancelSnap();
            return false;
        }
        return true;
    }

    private function folderLoaded(data: Dynamic) {
        trace("folderLoaded");

        var folderList: HBox = UIBuilder.getAs("folderList", HBox);
        if (folderList == null || folderList.destroyed) return; // screen freed
        folderList.rox_removeAll();

        var localbtn: Button = UIBuilder.create(Button, { defaults: "ArFolderButtons" });
        localbtn.ico = new Bmp();
        localbtn.ico.bitmapData = BmdUtil.transform(ResKeeper.getAssetImage("res/icon_ar_local.png"), "resize", [ (100).dp(), (100).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
        localbtn.addEventListener(MouseEvent.CLICK, function(_) {
            requestCode = 12;
#if android
            HaxeStub.startGetContent(requestCode, "image/*");
#else
            onActive(null);
#end
        });
        localbtn.refresh();
        folderList.addChild(localbtn);

        for (c in cast(data.catalogs.records, Array<Dynamic>)) {
//            w="(140).dp()" h="(140).dp()" skin:Paint-border="1" skin:Paint-color="0x00FF00" text="'folder'" />
            if (!MyUtils.arCacheExists(c.icon)) continue;

            var folder: Button = UIBuilder.create(Button, {
                defaults: "ArFolderButtons",
                text: "", //c.name,
                userData: { id: c.id, url: c.icon }
            });
            folder.ico = new Bmp();
            GameUtil.worker.addJob(new com.roxstudio.haxe.utils.SimpleJob(folder, function(folder) {
                var bmd = MyUtils.loadArImage(c.icon);
                folder.ico.bitmapData = BmdUtil.transform(bmd, "resize", [ (132).dp(), (132).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
            }, function(folder) {
                folder.addEventListener(MouseEvent.CLICK, function(_) {
                    currentCid = c.id;
                    showFolder(null, currentCid, false);
                });
                folder.refresh();
            }));

            folderList.addChild(folder);
        }

        var updatebtn: Button = UIBuilder.create(Button, { defaults: "ArFolderButtons" });
        updatebtn.ico = new Bmp();
        updatebtn.ico.bitmapData = BmdUtil.transform(ResKeeper.getAssetImage("res/icon_ar_update.png"), "resize", [ (100).dp(), (100).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
        updatebtn.addEventListener(MouseEvent.CLICK, showFolder.bind(_, -1, true));
        updatebtn.refresh();
        folderList.addChild(updatebtn);

        var scroll: Scroll = cast folderList.parent;
        scroll.tweenStop();
        scroll.scrollX = 0;
    }

    private function arLoaded(data: Dynamic) {
        trace("arLoaded");

        var folderList: HBox = UIBuilder.getAs("folderList", HBox);
        if (folderList == null || folderList.destroyed) return; // screen freed
        folderList.rox_removeAll();
        var canvas = UIBuilder.get("CameraCanvas");

        var btn: Button = UIBuilder.create(Button, { defaults: "ArFolderButtons" });
        btn.ico = new Bmp();
        btn.ico.bitmapData = BmdUtil.transform(ResKeeper.getAssetImage("res/icon_ar_prev.png"), "resize", [ (100).dp(), (100).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
        btn.addEventListener(MouseEvent.CLICK, function(_) {
            onBackKey();
        });
        btn.refresh();
        folderList.addChild(btn);

        for (c in cast(data.goods.records, Array<Dynamic>)) {
//            w="(140).dp()" h="(140).dp()" skin:Paint-border="1" skin:Paint-color="0x00FF00" text="'folder'" />
            if (!MyUtils.arCacheExists(c.image)) continue;

            var btn: Button = UIBuilder.create(Button, {
                defaults: "ArFolderButtons",
                text: ""
            });
            var descr: String = c.description;
            var arr: Array<String> = descr != null ? descr.split(" ") : [];
            var tags: Array<String> = [];
            var goType = 0, goUrl = "";
            for (s in arr) {
                var low = s.toLowerCase();
                if (low.startsWith("url:")) {
                    goType = 1;
                    goUrl = s.substr(4).trim();
                    tags.push(goUrl);
                } else if (low.startsWith("shop:")) {
                    goType = 2;
                    goUrl = s.substr(5).trim();
                    tags.push(goUrl);
                } else if (low.startsWith("@")) {
                    tags.push(s);
                }
            }
            btn.userData = { id: c.id, url: c.image, goType: goType, goUrl: goUrl, tags: tags };
            btn.ico = new Bmp();
            GameUtil.worker.addJob(new com.roxstudio.haxe.utils.SimpleJob(btn, function(btn) {
                var bmd = MyUtils.loadArImage(c.image);
                btn.ico.bitmapData = BmdUtil.transform(bmd, "resize", [ (132).dp(), (132).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
            }, function(btn) {
                btn.addEventListener(MouseEvent.CLICK, addAr.bind(_, canvas, c.image, null, btn.userData));
                btn.refresh();
            }));

            folderList.addChild(btn);
        }

        btn = UIBuilder.create(Button, { defaults: "ArFolderButtons" });
        btn.ico = new Bmp();
        btn.ico.bitmapData = BmdUtil.transform(ResKeeper.getAssetImage("res/icon_ar_update.png"), "resize", [ (100).dp(), (100).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
        btn.addEventListener(MouseEvent.CLICK, showFolder.bind(_, currentCid, true));
        btn.refresh();
        folderList.addChild(btn);

        if (folderList.numChildren < 5) { // make sure it's longer than hscroll
            for (i in folderList.numChildren...5) {
                var btn: Button = UIBuilder.create(Button, { defaults: "ArFolderButtons" });
                folderList.addChild(btn);
            }
        }

        var scroll: Scroll = cast folderList.parent;
        scroll.tweenStop();
        scroll.scrollX = 0;

    }

    private function addAr(_, canvas: Widget, url: String, bmd: BitmapData, userData: Dynamic) {
        if (bmd == null) {
            if (!MyUtils.arCacheExists(url)) return; // should not happens
            bmd = MyUtils.loadArImage(url);
        }
        var sp = new Sprite();
        sp.graphics.rox_drawRegion(bmd, null, 0, 0);
        var maxw = 580;
        var maxh = DipUtil.stageHeightDp - 400;
        var wr = maxw / bmd.width, hr = maxh / bmd.height;
        var r = Math.min(1, Math.min(wr, hr));
        sp.rox_scale(DipUtil.dpFactor * r);
//        trace("bmd="+bmd.width+","+bmd.height+",mh="+maxh+",wr="+wr+",hr="+hr+",r="+r);
        var obj: Widget = UIBuilder.create(Widget, { defaults: "ArObject" });
        obj.addChild(sp);
        obj.top += (-bmd.height / 2) * DipUtil.dpFactor;
        obj.left += (-bmd.width / 2) * DipUtil.dpFactor;
        obj.userData = userData;
        obj.userData.bmd = bmd;
        var agent = new RoxGestureAgent(obj);
        obj.addEventListener(RoxGestureEvent.GESTURE_ROTATION, handleEvent.bind(_, null));
        obj.addEventListener(RoxGestureEvent.GESTURE_PINCH, handleEvent.bind(_, null));
        obj.addEventListener(RoxGestureEvent.GESTURE_PAN, handleEvent.bind(_, null));
//                    obj.addEventListener(RoxGestureEvent.GESTURE_LONG_PRESS, handleEvent);
        sp.addEventListener(MouseEvent.MOUSE_DOWN, function(e) {
            currentAr = e.target.parent;
            updateArBox();
        });
//                    obj.addEventListener(DndEvent.DROP, function(e) { e.drop(); });
        canvas.addChild(obj);
        currentAr = obj;
        updateArBox();
    }

    private function restoreCache(filename: String) : Dynamic {
        var cache = ResKeeper.get("cache:" + filename);
        if (cache != null) return cache;
        var path = MyUtils.AR_CACHE_DIR + "/" + filename;
        if (sys.FileSystem.exists(path)) {
            return Json.parse(File.getContent(path));
        }
        return null;
    }

    private function storeCache(filename: String, data: Dynamic) {
        FileUtil.mkdirs(MyUtils.AR_CACHE_DIR);
        var path = MyUtils.AR_CACHE_DIR + "/" + filename;
        var jsonStr = Json.stringify(data);
        File.saveContent(path, jsonStr);
        ResKeeper.add("cache:" + filename, data, ResKeeper.DEFAULT_BUNDLE);
    }

    private function updateArBox() {
        var arbox: Widget = UIBuilder.getAs("ArBox", Widget);
        var obj: Sprite = cast currentAr.getChildAt(0);
        var rect = obj.getRect(flash.Lib.current.stage);
        arbox.visible = true;
        arbox.left = rect.x;
        arbox.top = rect.y;
        arbox.w = rect.width;
        arbox.h = rect.height;

        var arboxInfo: Button = UIBuilder.getAs("ArBoxInfo", Button);
        arboxInfo.visible = currentAr.userData.goType != 0;
        cast(arboxInfo.skin, Img).src = currentAr.userData.goType == 1 ? "res/ar_obj_inf.png".dpScale() : "res/ar_obj_buy.png".dpScale();
//        trace("gotype=" + currentAr.userData.goType + ",skin.src="+ cast(arboxInfo.skin, Img).src);
        arboxInfo.refresh();

        var parent = arbox.parent;
        parent.swapChildren(currentAr, parent.getChildAt(parent.numChildren - 2));
        parent.swapChildren(arbox, parent.getChildAt(parent.numChildren - 1));
    }

    private function handleEvent(e: RoxGestureEvent, obj: Widget) {
        if (obj == null) obj = cast(e.target);
//        trace(">>>t=" + e.target+",e="+e+",def=" + obj.defaults);
        if (obj.defaults != "ArObject") return;
        var sp: Sprite = cast obj.getChildAt(0);
//        trace("sp=" + sp + ",obj=" + obj + ",def=" + obj.defaults);
//        var menu = UIBuilder.get("ArObjectMenu");
//        menu.visible = false;
        currentAr = obj;
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
//            case RoxGestureEvent.GESTURE_LONG_PRESS:
//                menu.visible = true;
//                canvas.swapChildren(menu, canvas.getChildAt(canvas.numChildren - 1));
//                if (e.stageX < screenWidth / 2) { menu.left = e.stageX; } else { menu.left = e.stageX - menu.w; }
//                if (e.stageY < screenHeight / 2) { menu.top = e.stageY; } else { menu.top = e.stageY - menu.h; }
//                currentAr = sp;
        }
        updateArBox();
//        updateBounds(obj);
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

    private inline function reopenCamera() {
#if android
        flash.Lib.current.stage.opaqueBackground = 0x00000000;
        HaxeCamera.openCamera(HaxeCamera.getCurrentCameraId(), this, "dummy");
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
//        trace("btnFlash=" +  btn + ",visible=" + btn.visible + ",modes=" + modes);
        if (modes.length > 1) {
            btn.order = modes;
//            trace("modes=" + modes);
//            btn.states = new ru.stablex.DynamicList(BtnState);
            for (m in btn.order) {
                btn.states.resolve(m).text = modeNames.get(m);
//                trace("m=" + m + ",txt=" + btn.states.resolve(m).text);
            }
            btn.state = modes[0];
            btn.visible = true;
        } else {
            btn.visible = false;
        }
//        trace("btnFlash=" +  btn + ",visible=" + btn.visible + ",state=" + btn.state);
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

        UIBuilder.get("ArBox").visible = false;
#if android
        if (!sys.FileSystem.exists(ALBUM_DIR)) com.roxstudio.haxe.io.FileUtil.mkdirs(ALBUM_DIR);
        var name = "HP_MC_" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
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
        UIBuilder.get("CropButton").visible = true;
        trace("end snapped");
    }

    private function confirmSnap() {
        trace("confirmSnap");
        var bmp: Bmp = UIBuilder.getAs("CameraPreviewBmp", Bmp);
        var origbmd = bmp.bitmapData;
        var scale = bmp.scaleX;
        var offy = bmp.top / scale;
        var canvas = UIBuilder.get("CameraCanvas");
//        trace("bmd: scale="+scale+",offy="+offy);
        var bmd = new BitmapData(origbmd.width, origbmd.height, true, 0);
        bmd.copyPixels(origbmd, new Rectangle(0, 0, origbmd.width, origbmd.height), new Point(0, 0));

        var tags = new Map<String, Int>();

        for (i in 0...canvas.numChildren) {
            var arobj = cast(canvas.getChildAt(i), Widget);
            if (arobj.defaults != "ArObject") continue;
            var tt: Array<String> = arobj.userData.tags;
            for (t in tt) tags.set(t, 1);

            var arsp = arobj.getChildAt(0);
            var arbmd: BitmapData = cast arobj.userData.bmd;
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

        var cropbox = UIBuilder.get("CropBox");
        if (cropbox.visible) {
            trace("do crop");
            var cx = cropbox.left / scale, cy = cropbox.top / scale - offy, cw = cropbox.w / scale, ch = cropbox.h / scale;
            if (cx < 0) cx = 0;
            if (cy < 0) cy = 0;
            if (cw > bmd.width - cx) cw = bmd.width - cx;
            if (ch > bmd.height - cy) ch = bmd.height - cy;
            trace("crop=" + cx +"," + cy +"," + cw +"," + ch);
            var newbmd = new BitmapData(Std.int(cw), Std.int(ch), true, 0);
            newbmd.copyPixels(bmd, new Rectangle(cx, cy, cw, ch), new Point(0, 0));
            bmd.dispose();
            bmd = newbmd;
        }
//#if cpp
//        var name = "bbb_" + Std.random(10000) + ".jpg";
//        sys.io.File.saveBytes(#if android "/sdcard/" + name #else name #end, GameUtil.encodeJpeg(bmd));
//#end
        var tagsArr: Array<String> = [];
        for (t in tags.keys()) tagsArr.push(t);

        MyUtils.showWaiting("保存中".i18n());
        // save to local album
        image = { path: null, bmd: bmd, tags: tagsArr };
        var onComplete = function(imgInfo: Dynamic) {
            if (operation == 2) {
                finish(RoxAnimate.NO_ANIMATE, RoxScreen.OK, imgInfo);
                trace("MagicCamera finish: OK");
            } else { // 1 or 3
                var appdata: AppData = status.appData;
                appdata.width = imgInfo.bmd.width;
                appdata.height = imgInfo.bmd.height;
                appdata.type = "image";
                onHidden();
                trace("MagicCamera nextStep");
                onNextStep();
            }
        }
#if cpp
        GameUtil.worker.addJob(new SimpleJob<Dynamic>(image, function(imgInfo) {
            com.roxstudio.haxe.io.FileUtil.mkdirs(ALBUM_DIR);
            var path = ALBUM_DIR + "/HP_AR_" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
            trace("MagicCamera: start saving image to " + path);
            File.saveBytes(path, GameUtil.encodeJpeg(bmd));
            imgInfo.path = path;
//            trace("image saved, type=\"" + status.appData.type + "\"");
        }, function(imgInfo) {
            MyUtils.hideWaiting();
            onComplete(imgInfo);
        } ));
#else
        onComplete(image);
#end
        trace("end confirmSnap");
    }

    private function cancelSnap() {
        if (operation == 3) {
            finish(RoxScreen.CANCELED);
            return;
        }
        UIBuilder.get("CameraFrame").visible = true;
        UIBuilder.get("CameraPreview").visible = false;
        UIBuilder.get("CameraFrame2").visible = false;
        UIBuilder.get("CropButton").visible = false;
        UIBuilder.get("CropBox").visible = false;
        UIBuilder.get("ArSelect").visible = true;
        reopenCamera();
    }

    private function onLocal() {
        requestCode = 11;
#if android
        HaxeStub.startGetContent(requestCode, "image/*");
#else
        onActive(null);
#end
    }

    private function onActive(_) {
#if android
        trace("onActive, requestCode=" + requestCode + ",resultData=" + HaxeStub.getResult(requestCode));
#else
        trace("onActive, requestCode=" + requestCode);
#end
        if (requestCode < 0) {
            return;
        }
        var bmd: BitmapData = null;
        if (requestCode == 11 && operation == 3) {
            bmd = inputBmd;
        } else {
#if android
            var s = HaxeStub.getResult(requestCode);
            var json: Dynamic = haxe.Json.parse(s);
            if (untyped json.resultCode != "ok") {
                requestCode = -1;
//                reopenCamera();
                return;
            }
            var path = untyped json.intentDataPath;
            bmd = ResKeeper.loadLocalImage(path);
#else
            var path = "res/8.jpg";
            bmd = ResKeeper.loadAssetImage(path);
#end
        }
        if (bmd.width * bmd.height > 1000000) { // too large
            var ratio = Math.sqrt(1000000 / (bmd.width * bmd.height));
            var newbmd = new BitmapData(Std.int(bmd.width * ratio), Std.int(bmd.height * ratio), true, 0);
            newbmd.draw(bmd, new Matrix(ratio, 0, 0, ratio), true);
            bmd.dispose();
            bmd = newbmd;
        }
        switch (requestCode) {
        case 11:

            onHidden();

            UIBuilder.get("CameraFrame").visible = false;
            UIBuilder.get("CameraPreview").visible = true;
            var bmp: Bmp = UIBuilder.getAs("CameraPreviewBmp", Bmp);
            bmp.bitmapData = bmd;
//            bmp.userData = path;
            bmp.smooth = true;
            bmp.scaleX = bmp.scaleY = screenWidth / bmd.width;
            bmp.top = (screenHeight - (bmd.height * bmp.scaleX)) / 2;
            bmp.refresh();
            UIBuilder.get("CameraFrame2").visible = true;
            UIBuilder.get("CropButton").visible = true;
        case 12:
            var tags: Array<String> = [];
            addAr(null, UIBuilder.get("CameraCanvas"), null, bmd, { goType: 0, goUrl: "", tags: tags });
        }
        requestCode = -1;
    }

    private function openBrowser(url: String) {
        trace("openBrowser: " + url);
#if android
        HaxeStub.startBrowser(10, url);
#end
    }

    private function resetCropBox() {
        var bmp: Bmp = UIBuilder.getAs("CameraPreviewBmp", Bmp);
        var cropBox = UIBuilder.get("CropBox");
        cropBox.top = bmp.top + (40).dp();
        if (cropBox.top < (40).dp())
            cropBox.top = (40).dp();
        cropBox.left = (40).dp();
        cropBox.w = (560).dp();
        cropBox.h = (bmp.bitmapData.height * bmp.scaleY) - (80).dp();
        if (cropBox.h > (DipUtil.stageHeightDp - 120).dp() - cropBox.top)
            cropBox.h = (DipUtil.stageHeightDp - 120).dp() - cropBox.top;

    }

}
