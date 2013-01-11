package com.weiplus.client;

import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxScreenManager;
import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.utils.Job;
import com.roxstudio.haxe.utils.Worker;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.filters.DropShadowFilter;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author Rocks Wang
 */

class ImageChooser extends RoxScreen {
	
#if android
	//static inline var PATH = "/data/media";
	static inline var PATH = "/sdcard/DCIM";
#else
	static inline var PATH = "D:/tmp/weiplustest";
#end
	static inline var BG_COLOR = 0xDDDDDD;
	public static var tileWidth: Float = 100;

	var btnTopOk: Sprite;
	var btnTopBack: Sprite;
	var multiSelect: Bool;
	var imagePane: ScrollPane;
	var topOffset: Float;
	var items: Hash<Thumbnail>;
	var selected: Array<String>;
	var clockBmd: BitmapData;
	var worker: Worker;
	var clickPoint: Point;

    public function new() {
        super();
		multiSelect = false;
		tileWidth = (screenWidth - 40) / 4;
		
		var wallpaper = new Bitmap(new BitmapData(Std.int(screenWidth), Std.int(screenHeight), false, BG_COLOR));
		this.addChild(wallpaper);
		
		clockBmd = new BitmapData(Std.int(tileWidth), Std.int(tileWidth), false, 0xFFFFFF);
		var tmpbmd = GameUtil.loadBitmapData("res/clock.png");
		var tmpscale = tileWidth / tmpbmd.width;
		clockBmd.draw(tmpbmd, new Matrix(tmpscale, 0, 0, tmpscale, 0, 0), true);
		tmpbmd.dispose();
		
		var bg = new Sprite();
		var scale = screenWidth / 480;
		bg.scaleX = scale;
		bg.scaleY = scale;
		var bgbmd = GameUtil.loadBitmapData("res/topPane.png");
		bg.addChild(new Bitmap(bgbmd));
		bg.mouseEnabled = false;
		bg.y = 0;
		topOffset = bgbmd.height * scale + 4;
		
		imagePane = new ScrollPane(new Rectangle(0, 0, screenWidth, screenHeight - topOffset), false, true);
		this.addChild(imagePane);
		
		this.addChild(bg);
		
		btnTopOk = new Sprite();
		btnTopOk.addChild(new Bitmap(GameUtil.loadBitmapData("res/btnTopOk.png")));
		btnTopOk.mouseChildren = false;
		btnTopOk.mouseEnabled = true;
		btnTopOk.x = 370;
		btnTopOk.y = 3;
		btnTopOk.addEventListener(MouseEvent.CLICK, onOkClicked);
		bg.addChild(btnTopOk);
		
		btnTopBack = new Sprite();
		btnTopBack.addChild(new Bitmap(GameUtil.loadBitmapData("res/btnTopBack.png")));
		btnTopBack.mouseChildren = false;
		btnTopBack.mouseEnabled = true;
		btnTopBack.x = 10;
		btnTopBack.y = 3;
		btnTopBack.addEventListener(MouseEvent.CLICK, onBackClicked);
		bg.addChild(btnTopBack);
		
		selected = [];
		items = new Hash<Thumbnail>();
		
		worker = new Worker();
		clickPoint = null;
	}
	
	public static function listAll(path: String, extensions: Array<String>, ?outArray: Array<String>) : Array<String> {
		if (outArray == null) outArray = [];
		var arr = FileSystem.readDirectory(path);
		var all = extensions == null || extensions.length == 0;
		for (f in arr) {
			var fpath = path + "/" + f;
			if (FileSystem.isDirectory(fpath)) {
				listAll(fpath, extensions, outArray);
			} else { // is file
				if (all) {
					outArray.push(fpath);
				} else {
					var idx = f.lastIndexOf(".");
					if (idx >= 0) {
						var ext = f.substr(idx + 1).toLowerCase();
						if (contains(extensions, ext)) {
							outArray.push(fpath);
						}
					}
				}
			}
		}
		return outArray;
	}
	
	private static inline function contains(arr: Array<String>, str: String) : Bool {
		var ret = false;
		for (s in arr) { 
			if (str == s) {
				ret = true;
				break;
			}
		}
		return ret;
	}
	
	public function getSelected() : Array<String> {
		return selected;
	}

    override public function onNewRequest(requestData: Dynamic) {
        refresh();
    }
	
	public function refresh() {
		GameUtil.clear(selected);
		while (imagePane.numChildren > 0) imagePane.removeChildAt(0); // remove all

		var all = listAll(PATH, [ "jpg", "jpeg", "png", "gif" ] );
		trace("============ all image ===========\n" + all);
		
		for (i in 0...all.length) {
			var path = all[i];
			var spr: Thumbnail = items.get(path);
			if (spr == null) {
				spr = new Thumbnail(path);
				spr.name = path;
				worker.addJob(spr);
				spr.addChild(new Bitmap(clockBmd));
				spr.mouseChildren = false;
				spr.addEventListener(MouseEvent.MOUSE_DOWN, onItemClicked);
				spr.addEventListener(MouseEvent.MOUSE_UP, onItemClicked);
				spr.filters = [ new DropShadowFilter() ];
				items.set(path, spr);
			}
			spr.x = 8 + (i & 0x3) * (tileWidth + 8);
			spr.y = topOffset + (i >> 2) * (tileWidth + 8);
			imagePane.addChild(spr);
			//if (spr.y > screenHeight) break; // TODO this is for test only
		}
	}
	
	private function onOkClicked(e: MouseEvent) {
		trace("ok clicked, e=" + e);
		//dispatchEvent(new Event(Event.COMPLETE));
		parent.removeChild(this);
	}
	
	private function onBackClicked(e: MouseEvent) {
		trace("back clicked, e=" + e);
		GameUtil.clear(selected);
		dispatchEvent(new Event(Event.CANCEL));
		parent.removeChild(this);
	}
	
	private function onItemClicked(e: MouseEvent) {
		if (e.type == MouseEvent.MOUSE_DOWN) {
			clickPoint = new Point(e.stageX, e.stageY);
			return;
		}
		if (e.type != MouseEvent.MOUSE_UP || clickPoint == null || clickPoint.x != e.stageX || clickPoint.y != e.stageY) return;
		var spr: Thumbnail = e.target;
		if (spr.bmd != null) {
			selected.push(spr.name);
			trace("selected=" + selected);
			dispatchEvent(new Event(Event.COMPLETE));
			parent.removeChild(this);
		}
		clickPoint = null;
	}
	
}

private class Thumbnail extends Sprite, implements Job {
	
	var path: String;
	public var bmd: BitmapData;
	
	public function new(inPath: String) {
		super();
		path = inPath;
	}
	
	public function jobRun() : Void {
		var big: BitmapData = BitmapData.loadFromHaxeBytes(File.getBytes(path));
		var scale: Float, xoff: Float = 0, yoff: Float = 0;
		if (big.width > big.height) {
			scale = ImageChooser.tileWidth / big.height;
			xoff = (ImageChooser.tileWidth - big.width * scale) / 2;
		} else {
			scale = ImageChooser.tileWidth / big.width;
			yoff = (ImageChooser.tileWidth - big.height * scale) / 2;
		}
		trace("image=" + path + " (" + big.width + "*" + big.height + "),scale=" + scale + ",xoff=" + xoff + ",yoff=" + yoff);
		bmd = new BitmapData(Std.int(ImageChooser.tileWidth), Std.int(ImageChooser.tileWidth), true, 0);
		bmd.draw(big, new Matrix(scale, 0, 0, scale, xoff, yoff));
		big.dispose();
	}
	
	public function jobCompleted() : Void {
		cast(this.getChildAt(0), Bitmap).bitmapData = bmd;
	}
	
}