package com.weiplus.client;

using com.roxstudio.i18n.I18n;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.game.ResKeeper;
import com.eclecticdesignstudio.motion.easing.Linear;
import com.eclecticdesignstudio.motion.Actuate;
import com.roxstudio.haxe.ui.RoxApp;
import nme.display.Bitmap;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class Refresher extends Sprite {

    private var top: Bool;
    private var arrow: Sprite;
    private var updated = false;
    private var buttonFontSize: Float;

    public function new(name: String, top: Bool) {
        super();
        this.name = name;
        this.top = top;
        var d2rScale = RoxApp.screenWidth / 640;
        buttonFontSize = 36 * d2rScale;
        arrow = UiUtil.bitmap("res/refresh_arrow.png", UiUtil.CENTER);
        arrow.rox_scale(d2rScale);
        arrow.rotation = top ? 180 : 0;
        var spacing = 40 * d2rScale;
        var arrowwrap = new Sprite();
        arrowwrap.addChild(arrow);
        var label = UiUtil.staticText(top ? "下拉可以刷新".i18n() : "上拉可以刷新".i18n(), 0, buttonFontSize * 0.8);
        var w = arrowwrap.width + spacing + label.width;
        graphics.rox_fillRect(0x01FFFFFF, 0, 0, RoxApp.screenWidth, 80);
        addChild(arrowwrap.rox_move((this.width - w) / 2 + arrow.width / 2, (80 - arrowwrap.height) / 2 + arrow.height / 2));
        addChild(label.rox_move(arrowwrap.x + arrowwrap.width + spacing, (80 - label.height) / 2));
    }

    public function updateText() {
        if (updated) return;
        updated = true;
        var oldLabel = getChildAt(numChildren - 1);
        var label = UiUtil.staticText("松开立即刷新".i18n(), 0, buttonFontSize * 0.8);
        removeChild(oldLabel);
        addChild(label.rox_move(oldLabel.x, oldLabel.y));
        Actuate.tween(arrow, 0.2, { rotation: this.top ? 0 : 180}).ease(Linear.easeNone);
    }
}
