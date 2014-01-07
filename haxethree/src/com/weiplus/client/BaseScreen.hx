package com.weiplus.client;

import ru.stablex.ui.widgets.Floating;
import ru.stablex.ui.UIBuilder;
import com.roxstudio.haxe.ui.RoxScreenManager;
import nme.events.MouseEvent;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.geom.Rectangle;
import nme.display.Sprite;

using com.roxstudio.haxe.ui.DipUtil;
using com.roxstudio.i18n.I18n;
using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class BaseScreen extends RoxScreen {

    private static inline var DESIGN_WIDTH = 640;
    private static inline var TOP_HEIGHT = 86;
    private static inline var BTN_SPACING = 12;

    public var designWidth: Float; // always 640
    public var designHeight: Float;
    public var hasTitleBar: Bool = true;
    public var titleBar: Sprite;
    public var buttonFontSize: Float = 36;
    public var titleFontSize: Float = 36;
    public var d2rScale: Float;
    public var content: Sprite;
    public var title: Sprite;
    public var btnBack: RoxFlowPane;
    public var hasBack: Bool = true;
    private var titleBtnOffsetL: Float;
    private var titleBtnOffsetR: Float;

    private var exitDialog: Floating = null;

    override public function init(inManager: RoxScreenManager, inWidth: Float, inHeight: Float) {
        super.init(inManager, inWidth, inHeight);
        designWidth = DESIGN_WIDTH;
        d2rScale = screenWidth / designWidth;
        designHeight = screenHeight / d2rScale;
        buttonFontSize = 32 * d2rScale;
        titleFontSize = 32;
    }

    override public function onCreate() {
        super.onCreate();
        var hideButton = null;
        if (hasTitleBar) {
            titleBar = UiUtil.bitmap("res/bg_main_top.png");
            hideButton = new Sprite();
            hideButton.graphics.rox_fillRect(0x01FFFFFF, 0, 0, 160, TOP_HEIGHT);
            hideButton.mouseEnabled = true;
            hideButton.addEventListener(MouseEvent.CLICK, function(_) {
                onTitleClicked();
            });
            hideButton.rox_scale(d2rScale);
            titleBtnOffsetL = BTN_SPACING;
            titleBtnOffsetR = titleBar.width - BTN_SPACING;
            if (title != null) {
                title.mouseEnabled = false;
                titleBar.addChild(title.rox_anchor(UiUtil.CENTER).rox_move(titleBar.width / 2, titleBar.height / 2));
            }
            titleBar.rox_scale(d2rScale);
            btnBack = UiUtil.button(UiUtil.TOP_LEFT, null, "返回".i18n(), 0xFFFFFF, titleFontSize, "res/btn_back.9.png", function(e) { finish(RoxScreen.CANCELED); } );
            if (hasBack) {
                addTitleButton(btnBack, UiUtil.LEFT);
            }
        }
        var conth = (designHeight - (hasTitleBar ? TOP_HEIGHT : 0)) * d2rScale;
        content = createContent(conth);
        content.rox_move(0, screenHeight - conth);
        addChild(content);
        drawBackground();
        if (hasTitleBar) {
            addChild(titleBar);
            addChild(hideButton.rox_move((screenWidth - hideButton.width) / 2, 0));
        }
    }

    override public function onBackKey() {
//        trace("stacksize="+manager.stackSize());
        var hideDialog = function(exit: Bool) {
            exitDialog.free();
            exitDialog = null;
            if (exit) Sys.exit(0);
        };
        if (exitDialog != null) {
            hideDialog(false);
            return false;
        } else if (manager.stackSize() == 1) {
            exitDialog = cast UIBuilder.buildFn("ui/confirm_dialog.xml")( {
                title: "退出".i18n(),
                message: "是否退出哈利波图？".i18n(),
                onOk: hideDialog.bind(true),
                onCancel: hideDialog.bind(false)
            } );
            exitDialog.show();
            return false;
        }
        return true;
    }

    public function onTitleClicked() {
//        trace("onTitleClicked");
    }

    public function drawBackground() {
        graphics.rox_drawImage(ResKeeper.getAssetImage("res/bg_main.jpg"), 0, 0, screenWidth, screenHeight);
    }

    public function addTitleButton(btn: RoxFlowPane, align: Int) {
        if (!hasTitleBar || titleBar.contains(btn)) return;
        if (align == UiUtil.RIGHT) {
            btn.anchor = UiUtil.RIGHT | UiUtil.VCENTER;
            titleBar.addChild(btn.rox_move(titleBtnOffsetR, TOP_HEIGHT / 2));
            titleBtnOffsetR -= btn.width + BTN_SPACING;
        } else {
            btn.anchor = UiUtil.LEFT | UiUtil.VCENTER;
            titleBar.addChild(btn.rox_move(titleBtnOffsetL, TOP_HEIGHT / 2));
            titleBtnOffsetL += btn.width + BTN_SPACING;
        }
    }

    public function removeTitleButton(btn: RoxFlowPane) {
        if (!hasTitleBar || btn == null || !titleBar.contains(btn)) return;
        titleBar.removeChild(btn);
        if (btn.anchor == UiUtil.RIGHT | UiUtil.VCENTER) {
            titleBtnOffsetR += btn.width + BTN_SPACING;
        } else {
            titleBtnOffsetL -= btn.width + BTN_SPACING;
        }
    }

    public function createContent(height: Float) : Sprite {
        return new Sprite();
    }

}
