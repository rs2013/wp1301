package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.ui.RoxScreenManager;
import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.game.GameUtil;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFormatAlign;
#if cpp
import sys.io.File;
#end

/**
 * ...
 * @author Rocks Wang
 */

class ImageEditor extends RoxScreen {
	
	inline static var FILTER_TOP_OFFSET = 12;
	inline static var FILTER_WIDTH = 80;
	inline static var FILTER_IMG_WIDTH = 72;
	inline static var FILTER_SPACING = 15;
	
	static inline var BG_COLOR = 0xDDDDDD;
	
	var btnLocal: Sprite;
	var btnCamera: Sprite;
	var btnPicWall: Sprite;
	var btnOk: Sprite;
	var btnCancel: Sprite;
	
	var filterPane: Sprite;
	var filterBtns: Array<Sprite>;
#if cpp
	var imageChooser: ImageChooser;
#end
	var originBmd: BitmapData;
	var image: Sprite;
	var workspaceHeight: Float;
	
	var clickPoint: Point;

    public function new() {
        super();
		var bg = new Sprite();
		var scale = screenWidth / 480;
		bg.scaleX = scale;
		bg.scaleY = scale;
		var bgbmd = GameUtil.loadBitmapData("res/btnbg.png");
		bg.addChild(new Bitmap(bgbmd));
		
		bg.mouseEnabled = false;
		bg.y = screenHeight - 213 * scale;
		this.addChild(bg);
		
		btnLocal = new Sprite();
		btnLocal.addChild(new Bitmap(GameUtil.loadBitmapData("res/btnLocal.png")));
		btnLocal.mouseChildren = false;
		btnLocal.mouseEnabled = true;
		btnLocal.x = 400;
		btnLocal.y = 140;
		btnLocal.addEventListener(MouseEvent.CLICK, onLocalClicked);
		bg.addChild(btnLocal);
		
		btnPicWall = new Sprite();
		btnPicWall.addChild(new Bitmap(GameUtil.loadBitmapData("res/btnPicWall.png")));
		btnPicWall.mouseChildren = false;
		btnPicWall.mouseEnabled = true;
		btnPicWall.x = 320;
		btnPicWall.y = 140;
		btnPicWall.addEventListener(MouseEvent.CLICK, onPicWallClicked);
		bg.addChild(btnPicWall);
		
		btnCamera = new Sprite();
		btnCamera.addChild(new Bitmap(GameUtil.loadBitmapData("res/btnCamera.png")));
		btnCamera.mouseChildren = false;
		btnCamera.mouseEnabled = true;
		btnCamera.x = 200;
		btnCamera.y = 140;
		btnCamera.addEventListener(MouseEvent.CLICK, onCameraClicked);
		bg.addChild(btnCamera);
		
		btnOk = new Sprite();
		btnOk.addChild(new Bitmap(GameUtil.loadBitmapData("res/btnOk.png")));
		btnOk.mouseChildren = false;
		btnOk.mouseEnabled = true;
		btnOk.x = 80;
		btnOk.y = 140;
		btnOk.addEventListener(MouseEvent.CLICK, onOkClicked);
		bg.addChild(btnOk);
		
		btnCancel = new Sprite();
		btnCancel.addChild(new Bitmap(GameUtil.loadBitmapData("res/btnCancel.png")));
		btnCancel.mouseChildren = false;
		btnCancel.mouseEnabled = true;
		btnCancel.x = 0;
		btnCancel.y = 140;
		btnCancel.addEventListener(MouseEvent.CLICK, onCancelClicked);
		bg.addChild(btnCancel);
		
		filterPane = new ScrollPane(new Rectangle(0, 0, 480, 132), true, false);
		filterBtns = [];
#if android
		var format = new TextFormat(new nme.text.Font("/system/fonts/DroidSansFallback.ttf").fontName);
#else
		var format = new TextFormat();
#end
		format.color = 0xFFFFFF;
		format.size = 20;
		format.align = TextFormatAlign.CENTER;
		for (i in 0...Filters.FILTER_NAMES.length) {
			var name = Filters.FILTER_NAMES[i];
			var filterBtn = new Sprite();
			filterBtn.x = FILTER_SPACING + (FILTER_WIDTH + FILTER_SPACING) * i;
			filterBtn.y = FILTER_TOP_OFFSET;
			var filterBmp = new Bitmap(new BitmapData(FILTER_IMG_WIDTH, FILTER_IMG_WIDTH, true, 0));
			filterBmp.x = filterBmp.y = 4;
			filterBmp.smoothing = true;
			filterBtn.addChild(filterBmp);
			filterBtn.name = name;
			filterBtn.addEventListener(MouseEvent.MOUSE_DOWN, onFilterSelected);
			filterBtn.addEventListener(MouseEvent.MOUSE_UP, onFilterSelected);
			filterBtn.mouseEnabled = true;
			filterPane.addChild(filterBtn);
			filterBtns.push(filterBtn);
			var filterTxt = new TextField();
			filterTxt.defaultTextFormat = format;
			filterTxt.wordWrap = false;
			filterTxt.width = FILTER_WIDTH;
			filterTxt.height = 28;
			filterTxt.selectable = false;
			filterTxt.mouseEnabled = false;
			filterTxt.x = filterBtn.x;
			filterTxt.y = FILTER_TOP_OFFSET + FILTER_WIDTH + 4;
			filterTxt.text = name;
			filterPane.addChild(filterTxt);
		}
		bg.addChild(filterPane);
		
		workspaceHeight = screenHeight - bgbmd.height * scale;
		var wallpaper = new Bitmap(new BitmapData(Std.int(screenWidth), Std.int(workspaceHeight), false, BG_COLOR));
		this.addChild(wallpaper);
		
		image = new Sprite();
		this.addChild(image);
	}
	
	private function onFilterSelected(e: MouseEvent) {
		if (e.type == MouseEvent.MOUSE_DOWN) {
			clickPoint = new Point(e.stageX, e.stageY);
			return;
		}
		if (e.type != MouseEvent.MOUSE_UP || clickPoint == null || clickPoint.x != e.stageX || clickPoint.y != e.stageY) return;
		if (image.numChildren == 0) return;
		trace("filter " + cast(e.target, Sprite).name + " selected");
		var bmd = cast(image.getChildAt(0), Bitmap).bitmapData;
		bmd.copyPixels(originBmd, new Rectangle(0, 0, bmd.width, bmd.height), new Point(0, 0));
		var mat = Filters.getMatrixByName(cast(e.target, Sprite).name);
		applyFilter(bmd, mat);
		clickPoint = null;
	}
	
	private static function applyFilter(bmd: BitmapData, f: Array<Float>) {
		if (f == null) return;
		var bb = bmd.getPixels(new Rectangle(0, 0, bmd.width, bmd.height));
		bb.position = 0;
		for (i in 0...(bb.length >> 2)) {
			var idx = i << 2;
			var alphaV = bb[idx], redV = bb[idx + 1], greenV = bb[idx + 2], blueV = bb[idx + 3];
			
			var red = Std.int(f[0] * redV + f[1] * greenV + f[2] * blueV + f[3] * alphaV + f[4]);
			var green = Std.int(f[5] * redV + f[6] * greenV + f[7] * blueV + f[8] * alphaV + f[9]);
			var blue = Std.int(f[10] * redV + f[11] * greenV + f[12] * blueV + f[13] * alphaV + f[14]);
			var alpha = Std.int(f[15] * redV + f[16] * greenV + f[17] * blueV + f[18] * alphaV + f[19]);
			
			bb[idx] = alpha < 0 ? 0 : alpha > 255 ? 255 : alpha;
			bb[idx + 1] = red < 0 ? 0 : red > 255 ? 255 : red;
			bb[idx + 2] = green < 0 ? 0 : green > 255 ? 255 : green;
			bb[idx + 3] = blue < 0 ? 0 : blue > 255 ? 255 : blue;
		}
		bmd.setPixels(new Rectangle(0, 0, bmd.width, bmd.height), bb);
	}
	
	private function onLocalClicked(e: MouseEvent) {
		trace("local clicked, e=" + e);
#if cpp
        startScreen("com.weiplus.client.ImageChooser");
#end
	}

#if cpp
	private function imageSelected(e: Event) {
		var arr = imageChooser.getSelected();
		var big: BitmapData = BitmapData.loadFromHaxeBytes(File.getBytes(arr[0]));
		var screenRatio = screenWidth / workspaceHeight;
		var imageRatio = big.width / big.height;
		var scale: Float, xoff: Float = 0, yoff: Float = 0;
		if (imageRatio > screenRatio) {
			scale = screenWidth / big.width;
			image.x = 0;
			image.y = (workspaceHeight - scale * big.height) / 2;
		} else {
			scale = workspaceHeight / big.height;
			image.x = (screenWidth - scale * big.width) / 2;
			image.y = 0;
		}
		trace("image=" + arr[0] + " (" + big.width + "*" + big.height + "),scale=" + scale + ",x=" + image.x + ",y=" + image.y);
		var bmd = new BitmapData(Std.int(big.width * scale), Std.int(big.height * scale), true, 0);
		bmd.draw(big, new Matrix(scale, 0, 0, scale, 0, 0), true);
		
		if (image.numChildren == 0) {
			image.addChild(new Bitmap(bmd));
		} else {
			var bitmap = cast(image.getChildAt(0), Bitmap);
			bitmap.bitmapData.dispose();
			bitmap.bitmapData = bmd;
		}
		if (originBmd != null) originBmd.dispose();
		originBmd = new BitmapData(bmd.width, bmd.height, true, 0);
		originBmd.copyPixels(bmd, new Rectangle(0, 0, bmd.width, bmd.height), new Point(0, 0));
		
		// refresh all filter buttons
		xoff = yoff = 0;
		if (bmd.width > bmd.height) {
			scale = FILTER_IMG_WIDTH / bmd.height;
			xoff = (FILTER_IMG_WIDTH - bmd.width * scale) / 2;
		} else {
			scale = FILTER_IMG_WIDTH / bmd.width;
			yoff = (FILTER_IMG_WIDTH - bmd.height * scale) / 2;
		}
		var small = new BitmapData(FILTER_IMG_WIDTH, FILTER_IMG_WIDTH, true, 0);
		small.draw(bmd, new Matrix(scale, 0, 0, scale, xoff, yoff), true);
		for (i in 0...filterBtns.length) {
			var bmd = cast(filterBtns[i].getChildAt(0), Bitmap).bitmapData;
			bmd.copyPixels(small, new Rectangle(0, 0, FILTER_IMG_WIDTH, FILTER_IMG_WIDTH), new Point(0, 0));
			applyFilter(bmd, Filters.getMatrixByName(Filters.FILTER_NAMES[i]));
		}
		small.dispose();
	}
#end

	private function onPicWallClicked(e: MouseEvent) {
		trace("picwall clicked, e=" + e);
        //AndroidHelper.toJavaMap({a: 1, bb: "test" });
	}
	
	private function onCameraClicked(e: MouseEvent) {
		trace("camera clicked, e=" + e);
	}
	
	private function onOkClicked(e: MouseEvent) {
		trace("ok clicked, e=" + e);
        //var finishFunc: Dynamic = nme.JNI.createStaticMethod("com/weiplus/client/MainActivity", "finish", "(Ljava/lang/String;)V");
        //finishFunc("This is from haXe!!");
        finish(RoxScreen.OK);
	}
	
	private function onCancelClicked(e: MouseEvent) {
		trace("cancel clicked, e=" + e);
        finish(RoxScreen.CANCELED);
	}
	
}