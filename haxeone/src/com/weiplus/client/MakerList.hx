package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxNinePatch;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.display.Bitmap;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class MakerList extends BaseScreen {

    public var parentScreen: String;

    override public function onCreate() {
        hasTitleBar = false;
        hasBack = false;
        super.onCreate();
    }

    override public function onNewRequest(requestData: Dynamic) {
        super.onNewRequest(requestData);
        parentScreen = requestData;
    }

    override public function createContent(h: Float) : Sprite {
        var content = super.createContent(h);
        var btnClose = UiUtil.button(UiUtil.TOP | UiUtil.RIGHT, "res/icon_login_close.png", function(_) {
            finish(RoxScreen.CANCELED);
        });
        content.addChild(btnClose.rox_move(screenWidth - 10, 10));

        var makers = [
            "icon_jigsaw_maker", "奇幻拼图",
            "icon_swap_maker", "乾坤挪移",
            "icon_slide_maker", "移形换位",
            "icon_harry_camera", "魔法相机"
        ];
        var offy = 200 * d2rScale;
        for (i in 0...makers.length >> 1) {
            var bgbmd = ResKeeper.getAssetImage("res/" + makers[i << 1] + ".png");
            var bg = new RoxNinePatch(new RoxNinePatchData(new Rectangle(0, 0, bgbmd.width, bgbmd.height), bgbmd));
            var label = UiUtil.staticText(makers[(i << 1) + 1], 0xFFFFFF, 36);

            var btn = new RoxFlowPane(bgbmd.width * d2rScale, bgbmd.height * d2rScale, [ label ], bg, onButton);
            btn.name = makers[i << 1];
            btn.alpha = 0.7;
            content.addChild(btn.rox_move((screenWidth - btn.width) / 2, offy));
            offy += btn.height + 10;
        }
        return content;
    }

    override public function drawBackground() {
        var bg = ResKeeper.getAssetImage("res/bg_splash.jpg");
        var r = new Rectangle(0, bg.height - screenHeight / d2rScale, bg.width, screenHeight / d2rScale);
        graphics.rox_drawRegion(bg, r, 0, 0, screenWidth, screenHeight);
        var curtain = ResKeeper.getAssetImage("res/curtain.png");
        graphics.rox_drawRegion(curtain, null, 0, 0, screenWidth, curtain.height * screenWidth / curtain.width);
//        trace("x=" + ((w - logo.width) / 2) + ",y=" + (0.33 * h));
    }

//    override public function createContent(height: Float) : Sprite {
//        var margh = MARG_H * screenWidth;
//        var margv = MARG_V * screenWidth;
//        var txtsize = TXT_W * screenWidth;
//        var sp = new Sprite();
//        sp.graphics.rox_fillRect(BG_COLOR, 0, 0, screenWidth, height);
//
//        var makers = [
//                "icon_jigsaw_maker", "奇幻拼图",
//                "icon_slide_maker", "乾坤挪移",
//                "icon_swap_maker", "移形换位",
//                "icon_harry_camera", "魔法相机"
//        ];
//        var bgdata = new RoxNinePatchData(new Rectangle(margh, margv, 20, 20));
//        var offy = 0.0;
//        for (i in 0...makers.length >> 1) {
//            var icon = UiUtil.bitmap("res/" + makers[i << 1] + ".png");
//            var arrow = UiUtil.bitmap("res/icon_arrow.png");
//            var txtw = screenWidth - 2 * margh - icon.width - arrow.width;
//            var label = UiUtil.staticText(makers[(i << 1) + 1], 0xFFFFFF, txtsize, UiUtil.HCENTER, false, txtw);
//            var btn = new RoxFlowPane([ icon, label, arrow ], new RoxNinePatch(bgdata), [ 0 ], onButton);
//            btn.name = makers[i << 1];
//            sp.addChild(btn.rox_move(0, offy));
//            offy += btn.height;
//            sp.graphics.rox_line(2, 0xFF060606, 0, offy, screenWidth, offy);
//            sp.graphics.rox_line(2, 0xFF4D4D4D, 0, offy + 2, screenWidth, offy + 2);
//            offy += 4;
//        }
//        return sp;
//    }

    private function onButton(e: Dynamic) {
        trace("makerlist: name=" + e.target.name);
        switch (e.target.name) {
            case "icon_jigsaw_maker":
                startScreen(Type.getClassName(com.weiplus.apps.jigsaw.Maker));
            case "icon_slide_maker":
                startScreen(Type.getClassName(com.weiplus.apps.slidepuzzle.Maker));
            case "icon_swap_maker":
                startScreen(Type.getClassName(com.weiplus.apps.swappuzzle.Maker));
            case "icon_harry_camera":
                startScreen(Type.getClassName(com.weiplus.client.HarryCamera), RoxAnimate.NO_ANIMATE);
        }
    }

}
