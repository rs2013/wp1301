package com.weiplus.client;

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
    private static inline var BG_COLOR = 0xFF383838;
    private static inline var MARG_H = 30 / 640;
    private static inline var MARG_V = 18 / 640;
    private static inline var TXT_W = 36 / 640;

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("施展魔法", 0xFF0000, 36));
        super.onCreate();
    }

    override public function createContent(height: Float) : Sprite {
        var margh = MARG_H * screenWidth;
        var margv = MARG_V * screenWidth;
        var txtsize = TXT_W * screenWidth;
        var sp = new Sprite();
        sp.graphics.rox_fillRect(BG_COLOR, 0, 0, screenWidth, height);

        var makers = [ "icon_jigsaw_maker", "制作锯齿拼图", "icon_slide_maker", "制作滑动拼图", "icon_swap_maker", "制作换位拼图" ];
        var bgdata = new RoxNinePatchData(new Rectangle(margh, margv, 20, 20));
        var offy = 0.0;
        for (i in 0...makers.length >> 1) {
            var icon = UiUtil.bitmap("res/" + makers[i << 1] + ".png");
            var arrow = UiUtil.bitmap("res/icon_arrow.png");
            var txtw = screenWidth - 2 * margh - icon.width - arrow.width;
            var label = UiUtil.staticText(makers[(i << 1) + 1], 0xFFFFFF, txtsize, UiUtil.HCENTER, false, txtw);
            var btn = new RoxFlowPane([ icon, label, arrow ], new RoxNinePatch(bgdata), [ 0 ], onButton);
            btn.name = makers[i << 1];
            sp.addChild(btn.rox_move(0, offy));
            offy += btn.height;
            sp.graphics.rox_line(2, 0xFF060606, 0, offy, screenWidth, offy);
            sp.graphics.rox_line(2, 0xFF4D4D4D, 0, offy + 2, screenWidth, offy + 2);
            offy += 4;
        }
        return sp;
    }

    private function onButton(e: Dynamic) {
        trace("makerlist: name=" + e.target.name);
        switch (e.target.name) {
            case "icon_jigsaw_maker":
                startScreen(Type.getClassName(com.weiplus.apps.jigsaw.Maker));
            case "icon_slide_maker":
                startScreen(Type.getClassName(com.weiplus.apps.slidepuzzle.Maker));
            case "icon_swap_maker":
                startScreen(Type.getClassName(com.weiplus.apps.swappuzzle.Maker));
        }
    }

}
