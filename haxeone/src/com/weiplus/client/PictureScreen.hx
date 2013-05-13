package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.BitmapData;

using com.roxstudio.haxe.ui.UiUtil;

class PictureScreen extends BaseScreen {

    public static inline var IMAGE_SAVE_DIR =
#if android
        "/sdcard/DCIM/HarryPhoto";
#else
        "DCIM";
#end

    private var bitmapData: BitmapData;

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("查看原图", 0xFFFFFF, buttonFontSize * 1.2));
        super.onCreate();
        var btnSave = UiUtil.button(UiUtil.TOP_LEFT, null, "保存", 0xFFFFFF, buttonFontSize, "res/btn_common.9.png", function(_) {
#if cpp
            MyUtils.asyncOperation({}, function(_) {
                FileUtil.mkdirs(IMAGE_SAVE_DIR);
                var bytes = GameUtil.encodeJpeg(bitmapData);
                var name = "" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
                sys.io.File.saveBytes(IMAGE_SAVE_DIR + "/" + name, bytes);
            }, function(_) {
                UiUtil.message("保存成功");
            }, "保存中");
#end
        });
        addTitleButton(btnSave, UiUtil.RIGHT);
    }

    override public function onNewRequest(data: Dynamic) {
        bitmapData = cast data;
        var sc: Float = Math.min(screenWidth / bitmapData.width, (screenHeight - titleBar.height) / bitmapData.height);
        var offx = (screenWidth - bitmapData.width * sc) / 2, offy = (screenHeight - titleBar.height - bitmapData.height * sc) / 2;
        var sp = new Sprite();
        sp.addChild(new Bitmap(bitmapData).rox_smooth());
        sp.rox_scale(sc).rox_move(offx, offy);
        var agent = new RoxGestureAgent(sp);
        sp.addEventListener(RoxGestureEvent.GESTURE_PAN, agent.getHandler());
        sp.addEventListener(RoxGestureEvent.GESTURE_PINCH, agent.getHandler());
        content.addChild(sp);
    }

}
