package com.weiplus.client;

import com.roxstudio.haxe.utils.SimpleJob;
import com.roxstudio.i18n.I18n;
import com.roxstudio.haxe.game.BmdUtil;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.ui.DipUtil;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.game.GfxUtil;
import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.game.ResKeeper;
import com.weiplus.client.MyUtils;
import com.weiplus.client.model.AppData;

import sys.io.File;
import haxe.Json;

import flash.Lib;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;

import ru.stablex.ui.widgets.Bmp;
import ru.stablex.ui.widgets.Scroll;
import ru.stablex.ui.skins.Img;
import ru.stablex.ui.widgets.Button;
import ru.stablex.ui.widgets.HBox;
import ru.stablex.ui.widgets.Widget;
import ru.stablex.ui.UIBuilder;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.ui.DipUtil;
using com.roxstudio.i18n.I18n;
using StringTools;

class MagicEditor extends MakerScreen {

    private static inline var ALBUM_DIR = MyUtils.ALBUM_DIR;
    private static inline var BG_MAX_AREA = 300000;
    private static inline var AR_MAX_AREA = 200000;

    private static var updatingAr: Bool = false;

    private var currentCid = -1;
    private var currentAr: Widget;
    private var requestCode = -1;

    public function new() {
        super();
        hasTitleBar = false;
    }

    override public function createContent(height: Float) : Sprite {
        if (UIBuilder.get("MagicEditor") != null) UIBuilder.get("MagicEditor").free(true);

        content = UIBuilder.buildFn("ui/magic_editor.xml")();

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

            var bmp: Bmp = UIBuilder.getAs("EditorBgBmp", Bmp);
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

            var bmp: Bmp = UIBuilder.getAs("EditorBgBmp", Bmp);
            var bmpw = bmp.bitmapData.width * bmp.scaleX;
            var bmph = bmp.bitmapData.height * bmp.scaleY;
            box.w += pt.x;
            if (box.w < bmpw / 2) box.w = bmpw / 2;
            if (box.w > bmpw - box.left) box.w = bmpw - box.left;
            box.h += pt.y;
            if (box.h < bmph / 2) box.h = bmph / 2;
            if (box.h > bmp.top + bmph - box.top) box.h = bmp.top + bmph - box.top;
        });

        showFolder(-1);

        this.addEventListener(Event.ACTIVATE, onActive);

        return content;
    }

    override public function onNewRequest(data: String) {
        var drawingData: Dynamic = Json.parse(data);
        var bgPath = drawingData.bg.path;
        var bmpFrame = UIBuilder.get("BgLayer");
        var bmp: Bmp = UIBuilder.getAs("EditorBgBmp", Bmp);
        bmp.bitmapData = ResKeeper.loadLocalImage(bgPath, BG_MAX_AREA);
        bmp.smooth = true;
        bmp.scaleX = bmp.scaleY = screenWidth / bmp.bitmapData.width;
        bmp.top = (bmpFrame.h - bmp.bitmapData.height * bmp.scaleY) / 2;

        var ars: Array<ArData> = drawingData.ars;
//        trace("bmd="+bmp.bitmapData.width+","+bmp.bitmapData.height+",bmpFrame.h="+bmpFrame.h+bmp.top+",scale="+bmp.scaleX);
        if (ars != null) {
            for (ar in ars) {
                var path: String = ar.path;
                var compact: Bool = ar.compact;
                var descr: String = ar.description;
                var mv: Array<Float> = ar.matrix;
                var matrix = new Matrix(mv[0], mv[1], mv[3], mv[4], mv[2], mv[5]);
                var arbmd = ar.compact ? MyUtils.loadArImage(path) : ResKeeper.loadLocalImage(path, AR_MAX_AREA);
//                if (ar.compact) {
//                    var newarbmd = ResKeeper.createArImage(arbmd);
//                    arbmd.dispose();
//                    arbmd = newarbmd;
//                } else {
//                    if (arbmd.width * arbmd.height > AR_MAX_AREA) { // too large
//                        var ratio = Math.sqrt(AR_MAX_AREA / (arbmd.width * arbmd.height));
//                        var newbmd = new BitmapData(Std.int(arbmd.width * ratio), Std.int(arbmd.height * ratio), true, 0);
//                        newbmd.draw(arbmd, new Matrix(ratio, 0, 0, ratio), true);
//                        arbmd.dispose();
//                        arbmd = newbmd;
//                    }
//                }
                addAr(null, path, arbmd, matrix, parseDescr(null, null, path, compact, descr));
            }
        }
        bmp.refresh();
    }

    private function showFolder(cid: Int) {
        trace("showFolder, cid=" + cid);
        var cachefile = cid == -1 ? "arfolders.json" : "arlist_" + cid + ".json";
        var data = restoreCache(cachefile);
        if (data == null) {
            trace("showFolder error, cid=" + cid); // should not happen
        }
        if (cid == -1) {
            UiUtil.delay(folderLoaded.bind(data));
        } else {
            UiUtil.delay(arLoaded.bind(data));
        }
    }

    override public function onDestroy() {
        trace("onDestroy");
        var editor = UIBuilder.get("MagicEditor");
        if (editor != null) editor.free(true);
    }

    override public function onBackKey() {
        if (currentCid >= 0) {
            currentCid = -1;
            showFolder(-1);
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
                var bmd = MyUtils.loadArImage(MyUtils.arCachePath(c.icon));
                folder.ico.bitmapData = BmdUtil.transform(bmd, "resize", [ (132).dp(), (132).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
            }, function(folder) {
                folder.addEventListener(MouseEvent.CLICK, function(_) {
                    currentCid = c.id;
                    showFolder(currentCid);
                });
                folder.refresh();
            }));

            folderList.addChild(folder);
        }

        var scroll: Scroll = cast folderList.parent;
        scroll.tweenStop();
        scroll.scrollX = 0;
    }

    private function arLoaded(data: Dynamic) {
        trace("arLoaded");

        var folderList: HBox = UIBuilder.getAs("folderList", HBox);
        if (folderList == null || folderList.destroyed) return; // screen freed
        folderList.rox_removeAll();
        var canvas = UIBuilder.get("CanvasLayer");

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
            btn.userData = parseDescr(c.id, c.image, MyUtils.arCachePath(c.image), true, descr);
            btn.ico = new Bmp();
            GameUtil.worker.addJob(new com.roxstudio.haxe.utils.SimpleJob(btn, function(btn) {
                var bmd = MyUtils.loadArImage(MyUtils.arCachePath(c.image));
                btn.ico.bitmapData = BmdUtil.transform(bmd, "resize", [ (132).dp(), (132).dp(), BmdUtil.RESIZE_USE_MARGIN ]);
            }, function(btn) {
                btn.addEventListener(MouseEvent.CLICK, addAr.bind(_, c.image, null, null, btn.userData));
                btn.refresh();
            }));

            folderList.addChild(btn);
        }

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

    private function parseDescr(id: String, url: String, path: String, compact: Bool, descr: String) : ArUserData {
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
        return { id: id, url: url, path: path, compact: compact, description: descr, goType: goType, goUrl: goUrl, tags: tags, bmd: null };
    }

    private function addAr(_, url: String, bmd: BitmapData, matrix: Matrix, userData: ArUserData) {
        if (bmd == null) {
            if (!MyUtils.arCacheExists(url)) return; // should not happens
            bmd = MyUtils.loadArImage(MyUtils.arCachePath(url));
        }

        var canvas = UIBuilder.get("CanvasLayer");

        if (matrix == null) { // newly added
            matrix = new Matrix();
            var area = bmd.width * bmd.height;
            var maxArea = canvas.w * canvas.h * 0.5;
            var r = 1.0;
            if (area > maxArea) {
                r = Math.sqrt(maxArea / area);
                matrix.scale(r, r);
            }
            matrix.translate((canvas.w - bmd.width * r) / 2, (canvas.h - bmd.height * r) / 2);
        }
        trace("addAr:url="+url+",bmd="+bmd.width+","+bmd.height+",mat="+matrix+",data="+userData);
        var sp = new Sprite();
        sp.graphics.rox_drawRegion(bmd, null, 0, 0);
        var mat = sp.transform.matrix;
        mat.a = matrix.a;
        mat.b = -matrix.b;
        mat.c = -matrix.c;
        mat.d = matrix.d;
        sp.transform.matrix = mat;
        trace("mat=" + sp.transform.matrix + ",sp.scaleX=" + sp.scaleX + ",sp.rotate=" + sp.rotation);

        var obj: Widget = UIBuilder.create(Widget, { defaults: "ArObject" });
        obj.addChild(sp);
        obj.top = matrix.ty;
        obj.left = matrix.tx;

        obj.userData = copyUserData(userData, bmd);
        var agent = new RoxGestureAgent(obj, RoxGestureAgent.GESTURE_CAPTURE);
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

    private static function copyUserData(d: ArUserData, bmd: BitmapData) : ArUserData {
        return { id: d.id, url: d.url, path: d.path, compact: d.compact,
            description: d.description, goType: d.goType, goUrl: d.goUrl, tags: d.tags,
            bmd: bmd
        }
    }

    private static function restoreCache(filename: String) : Dynamic {
        var cache = ResKeeper.get("cache:" + filename);
        if (cache != null) return cache;
        var path = MyUtils.AR_CACHE_DIR + "/" + filename;
        if (sys.FileSystem.exists(path)) {
            return Json.parse(File.getContent(path));
        }
        return null;
    }

    private static function storeCache(filename: String, data: Dynamic) {
        FileUtil.mkdirs(MyUtils.AR_CACHE_DIR);
        var path = MyUtils.AR_CACHE_DIR + "/" + filename;
        var jsonStr = Json.stringify(data);
        File.saveContent(path, jsonStr);
        ResKeeper.add("cache:" + filename, data, ResKeeper.DEFAULT_BUNDLE);
    }

    private function updateArBox() {
        var arbox: Widget = UIBuilder.getAs("ArBox", Widget);
        var obj: Sprite = cast currentAr.getChildAt(0);
        var rect = obj.getRect(UIBuilder.get("CanvasLayer"));
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
        parent.removeChild(currentAr);
        parent.removeChild(arbox);
        parent.addChild(currentAr);
        parent.addChild(arbox);
    }

    private function handleEvent(e: RoxGestureEvent, obj: Widget) {
        if (obj == null) obj = cast(e.target);
//        trace(">>>t=" + e.target+",e="+e+",def=" + obj.defaults);
        if (obj.defaults != "ArObject") return;
        var sp: Sprite = cast obj.getChildAt(0);

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
                sp.scaleX *= scale;
                sp.scaleY *= scale;
                obj.x = newpos.x;
                obj.y = newpos.y;
            case RoxGestureEvent.GESTURE_ROTATION:
                var angle: Float = e.extra;
                var dx = obj.x - e.stageX, dy = obj.y - e.stageY;
                var nowang = Math.atan2(dy, dx);
                var length = new Point(dx, dy).length;
                var newang = nowang + angle;
                var newpos = Point.polar(length, newang);
                newpos.offset(e.stageX, e.stageY);
                sp.rotation += 180 / Math.PI * angle;
                obj.x = newpos.x;
                obj.y = newpos.y;
        }
        updateArBox();
    }

    override public function drawBackground() { // suppress drawing default background
    }

    private function doSave(addWaterMark: Bool, nextAction: Void -> Void) {
        trace("doSave");

        var bmp: Bmp = UIBuilder.getAs("EditorBgBmp", Bmp);
        var origbmd = bmp.bitmapData;
        var scale = bmp.scaleX;
        var offy = bmp.top / scale;
        var canvas = UIBuilder.get("CanvasLayer");
        trace("bmd: scale="+scale);
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
        if (addWaterMark) drawWaterMark(bmd);

        var tagsArr: Array<String> = [];
        for (t in tags.keys()) tagsArr.push(t);

        MyUtils.showWaiting("保存中".i18n());
        // save to local album
        image = { path: null, bmd: bmd, tags: tagsArr };
        var path = ALBUM_DIR + "/HP_AR_" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
        var text = "成功保存在".i18n() + ALBUM_DIR;
#if cpp
        GameUtil.worker.addJob(new SimpleJob(image, function(imgInfo) {
            com.roxstudio.haxe.io.FileUtil.mkdirs(ALBUM_DIR);
            trace("MagicEditor: start saving image to " + path);
            cpp.vm.Gc.run(true);
            File.saveBytes(path, GameUtil.encodeJpeg(bmd));
            imgInfo.path = path;
//            trace("image saved, type=\"" + status.appData.type + "\"");
        }, function(imgInfo) {
            MyUtils.hideWaiting();
            nextAction();
            UiUtil.message(text);
        } ));
#else
        nextAction();
#end
        trace("end doSave");
    }

    private function drawWaterMark(bmd: BitmapData) {
        var s = (HpApi.instance.user != null ? HpApi.instance.user.name : "") + "@哈利波图";
        var scale = bmd.width / 640;
        var tf = UiUtil.staticText(s, 0xFFFFFF, 28 * scale);
        var glow = new GlowFilter(0); // black
        tf.filters = [ glow ];
        var mat = new Matrix(1, 0, 0, 1, 6 * scale, bmd.height - tf.height - 4 * scale);
        bmd.draw(tf, mat);
    }

    private function save() {
        doSave(true, function() {
            var appdata: AppData = status.appData;
            appdata.width = image.bmd.width;
            appdata.height = image.bmd.height;
            appdata.type = "image";
            trace("MagicEditor save");
            onNextStep();
        });
    }

    private function makeGame() {
        status.appData.type = "jigsaw";
        doSave(false, function() {
            startScreen(Type.getClassName(SimpleMaker), null, image);
        });
    }

    private function createDrawingData() : String {
        var bmp: Bmp = UIBuilder.getAs("EditorBgBmp", Bmp);
        var scale = bmp.scaleX;
        var canvas = UIBuilder.get("CanvasLayer");
        var data: { ars: Array<ArData> } = { ars: [] };
        for (i in 0...canvas.numChildren) {
            var arobj = cast(canvas.getChildAt(i), Widget);
            if (arobj.defaults != "ArObject") continue;
            var arData: ArUserData = arobj.userData;

            var arsp = arobj.getChildAt(0);
            var arbmd: BitmapData = arData.bmd;
            var arscalex = arsp.scaleX, arscaley = arsp.scaleY;
            var arangle = arscalex > 0 ? arsp.rotation : -arsp.rotation;
            var dx = arobj.left;
            var dy = arobj.top;
            var mat = new Matrix();
            mat.rotate(((arangle + 360) % 360) * Math.PI / 180);
            mat.translate(dx / arscalex, dy / arscaley);
            mat.scale(arscalex, arscaley);
            var matrix: Array<Float> = [ mat.a, -mat.b, mat.tx, -mat.c, mat.d, mat.ty ];
            data.ars.push({ path: arData.path, compact: arData.compact, description: arData.description, matrix: matrix });
        }
        trace("createDrawingData=" + data);
        return Json.stringify(data);
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
#if android
        var s = HaxeStub.getResult(requestCode);
        var json: Dynamic = haxe.Json.parse(s);
        if (untyped json.resultCode != "ok") {
            requestCode = -1;
            return;
        }
        var path = untyped json.intentDataPath;
        bmd = ResKeeper.loadLocalImage(path);
#else
        var path = "res/8.jpg";
        bmd = ResKeeper.loadLocalImage(path);
#end
        if (bmd.width * bmd.height > AR_MAX_AREA) { // too large
            var ratio = Math.sqrt(AR_MAX_AREA / (bmd.width * bmd.height));
            var newbmd = new BitmapData(Std.int(bmd.width * ratio), Std.int(bmd.height * ratio), true, 0);
            newbmd.draw(bmd, new Matrix(ratio, 0, 0, ratio), true);
            bmd.dispose();
            bmd = newbmd;
        }
        var tags: Array<String> = [];
        addAr(null, null, bmd, null, parseDescr(null, null, path, false, ""));
        requestCode = -1;
    }

    private function openBrowser(url: String) {
        trace("openBrowser: " + url);
#if android
        HaxeStub.startBrowser(10, url);
#end
    }

    private function resetCropBox() {
        var bmp: Bmp = UIBuilder.getAs("EditorBgBmp", Bmp);
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

    static public function updateAr() {
        if (updatingAr) {
            UiUtil.message("正在更新魔贴中".i18n());
            return;
        } else {
            UiUtil.message("已开始在后台更新魔贴，此过程可能需要几分钟".i18n());
        }
        trace("start updateAr");
        updatingAr = true;
        var folderCount = 0, arCount = 0, failCount = 0;
        var queue: List<{ url: String, type: Int }> = new List();
        queue.add({ url: null, type: 0 });
        var runner: Void -> Void = null;
        runner = function() {
            var q = queue.pop();
            if (q == null) { // all job done
                trace("updateAr over: folders="+folderCount+",ars="+arCount+",fails="+failCount);
                UiUtil.message("更新魔贴完成, 更新了".i18n() + folderCount + "个目录,".i18n() + arCount + "个魔贴,遇到".i18n() + failCount + "个错误".i18n());
                updatingAr = false;
                return;
            }
            switch (q.type) {
                case 0: // folder list
                    HpApi.instance.get("/ar/catalogs/list", { sinceId: 0, rows: 100 }, function(code: Int, data: Dynamic) {
                        if (code != 200) {
                            UiUtil.message("获取目录失败，更新已停止. code=".i18n() + code + ",message=" + data);
                            updatingAr = false;
                            return;
                        }
                        storeCache("arfolders.json", data);
                        for (c in cast(data.catalogs.records, Array<Dynamic>)) {
                            queue.add({ url: c.id, type: 1 });
                            if (!MyUtils.arCacheExists(c.icon)) {
                                queue.add({ url: c.icon, type: 2 });
                            };
                        }
                        runner();
                    });
                case 1: // a folder
                    HpApi.instance.get("/ar/goods/by_catalog/" + q.url, { sinceId: 0, rows: 100 }, function(code: Int, data: Dynamic) {
                        if (code == 200) {
                            storeCache("arlist_" + q.url + ".json", data);
                            for (c in cast(data.goods.records, Array<Dynamic>)) {
                                if (!MyUtils.arCacheExists(c.image)) {
                                    queue.add({ url: c.image, type: 3 });
                                }
                            }
                        } else { failCount++; }
                        runner();
                    });
                case 2, 3: // image
                    MyUtils.asyncArImage(q.url, function(isOk) {
                        if (isOk) {
                            if (q.type == 2) { folderCount++; } else { arCount++; }
                        } else { failCount++; }
                        runner();
                    });
            }
        };
        runner();
    }

}

private typedef ArUserData = {
    id: String,
    url: String,
    path: String,
    compact: Bool,
    description: String,
    goType: Int,
    goUrl: String,
    tags: Array<String>,
    bmd: BitmapData
};

private typedef ArData = {
    path: String,
    compact: Bool,
    description: String,
    matrix: Array<Float>
};