package com.weiplus.client;

import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxScreenManager;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.display.Graphics;
import nme.text.TextFieldType;
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

/**
 * ...
 * @author Rocks Wang
 */

class RichEditor extends RoxScreen {

    static inline var BG_COLOR = 0xDDDDDD;
    static inline var TABLE_SPACING: Float = 12;

    var btnPost: Sprite;

    var btnImage: Sprite;
    var btnRecord: Sprite;
    var btnLocation: Sprite;
    var btnMagic: Sprite;
    var btnGift: Sprite;
    var btnRandom: Sprite;

    var btnWeibo: Sprite;
    var btnTencent: Sprite;
    var btnSohu: Sprite;
    var btnRenren: Sprite;
    var btnQQSpace: Sprite;
    var btnTwitter: Sprite;

    var clickPoint: Point;
    var designWidth: Float;
    var designHeight: Float;

    override public function onCreate() {
        super.onCreate();
        var container = new Sprite();
        designWidth = 640;
        var scale = screenWidth / designWidth;
        designHeight = screenHeight / scale;
//        trace("design="+designWidth+","+designHeight);
        container.scaleX = container.scaleY = scale;
        container.graphics.beginFill(BG_COLOR);
        container.graphics.drawRect(0, 0, designWidth, designHeight);
        container.graphics.endFill();
        addChild(container);

        var titlebar = Utils.smoothBmp(GameUtil.loadBitmapData("res/titlebar.png"));
        container.addChild(titlebar);

        btnPost = new Sprite();
        var bmd = GameUtil.loadBitmapData("res/btnPost.png");
        btnPost.addChild(Utils.smoothBmp(bmd));
        btnPost.mouseChildren = false;
        btnPost.mouseEnabled = true;
        btnPost.x = 470;
        btnPost.y = 14;
        btnPost.addEventListener(MouseEvent.CLICK, onPostClicked);
        container.addChild(btnPost);

        var inputHeight = designHeight - (267 + TABLE_SPACING) * 2 - 100 - 8 - 75;

        var input = new Sprite();
        bmd = GameUtil.loadBitmapData("res/input_bg.jpg");
        var gfx = input.graphics;
        gfx.beginBitmapFill(bmd);
        gfx.drawRect(0, 0, 614, 8);
        gfx.endFill();
        var scale = inputHeight / 160;
        gfx.beginBitmapFill(bmd, new Matrix(1, 0, 0, scale, 0, 8 - 8 * scale));
        gfx.drawRect(0, 8, 614, inputHeight);
        gfx.endFill();
        gfx.beginBitmapFill(bmd, new Matrix(1, 0, 0, 1, 0, inputHeight - 160));
        gfx.drawRect(0, inputHeight + 8, 614, 75);
        gfx.endFill();

#if android
        var format = new TextFormat(new nme.text.Font("/system/fonts/DroidSansFallback.ttf").fontName);
#else
        var format = new TextFormat();
#end
        format.color = 0x0;
        format.size = 32;
        var inputTxt = new TextField();
        inputTxt.defaultTextFormat = format;
        inputTxt.wordWrap = true;
        inputTxt.multiline = true;
        inputTxt.width = 610;
        inputTxt.x = 2;
        inputTxt.height = inputHeight;
        inputTxt.y = 8;
        inputTxt.selectable = true;
        inputTxt.mouseEnabled = true;
        inputTxt.type = TextFieldType.INPUT;
        inputTxt.text = "说点什么吧...";
        input.addChild(inputTxt);
        input.x = 13;
        input.y = 100;
        container.addChild(input);

        var tools = new Sprite();
        bmd = GameUtil.loadBitmapData("res/table_bg.jpg");
        tools.addChild(Utils.smoothBmp(bmd));
        tools.x = 13;
        tools.y = designHeight - 2 * 267 - TABLE_SPACING;

        var arrowBmd = GameUtil.loadBitmapData("res/ico_arrow.png");
        tools.addChild(btnImage = createButton("ico_pic", "照片", 0, 0, onToolClicked, arrowBmd));
        tools.addChild(btnRecord = createButton("ico_rec", "录音", 307, 0, onToolClicked, arrowBmd));
        tools.addChild(btnLocation = createButton("ico_loc", "位置", 0, 89, onToolClicked, arrowBmd));
        tools.addChild(btnMagic = createButton("ico_magic", "魔法", 307, 89, onToolClicked, arrowBmd));
        tools.addChild(btnGift = createButton("ico_gift", "礼物", 0, 178, onToolClicked, arrowBmd));
        tools.addChild(btnRandom = createButton("ico_rand", "随便发发", 307, 178, onToolClicked, arrowBmd));
        container.addChild(tools);

        var sites = new Sprite();
        sites.addChild(Utils.smoothBmp(bmd));
        sites.x = 13;
        sites.y = designHeight - 267;

        sites.addChild(btnWeibo = createButton("ico_sina", "新浪微博", 0, 0, onSiteClicked));
        sites.addChild(btnTencent = createButton("ico_tencent", "腾讯微博", 307, 0, onSiteClicked));
        sites.addChild(btnSohu = createButton("ico_sohu_g", "搜狐微博", 0, 89, onSiteClicked));
        sites.addChild(btnRenren = createButton("ico_renren", "人人网", 307, 89, onSiteClicked));
        sites.addChild(btnQQSpace = createButton("ico_qqspace_g", "QQ空间", 0, 178, onSiteClicked));
        sites.addChild(btnTwitter = createButton("ico_twit_g", "Twitter", 307, 178, onSiteClicked));
        container.addChild(sites);

    }

    private function createButton(iconName: String, labelTxt: String, x: Float, y: Float, listener: Dynamic -> Void, ?arrowBmd: BitmapData) : Sprite {
        var btn = new Sprite();
        btn.name = labelTxt;
        btn.mouseChildren = false;
        btn.mouseEnabled = true;
        btn.x = x;
        btn.y = y;
        var gfx = btn.graphics;
        gfx.beginFill(0xFFFFFF, 0.005); // accept mouse click
        gfx.drawRect(0, 0, 307, 89);
        gfx.endFill();
        var icon = Utils.smoothBmp(GameUtil.loadBitmapData("res/" + iconName + ".png"));
        icon.x = 33;
        icon.y = 12;
        btn.addChild(icon);
#if android
        var format = new TextFormat(new nme.text.Font("/system/fonts/DroidSansFallback.ttf").fontName);
#else
        var format = new TextFormat();
#end
        format.color = 0x0;
        format.size = 32;
        var label = new TextField();
        label.defaultTextFormat = format;
        label.wordWrap = false;
        label.multiline = false;
        label.width = 140;
        label.height = 64;
        label.x = 112;
        label.y = 22;
        trace("textHeight=" + label.textHeight);
        label.selectable = false;
        label.mouseEnabled = false;
        label.text = labelTxt;
        btn.addChild(label);
        if (arrowBmd != null) {
            var arrow = Utils.smoothBmp(arrowBmd);
            arrow.x = 260;
            arrow.y = 12;
            btn.addChild(arrow);
        }
        btn.addEventListener(MouseEvent.CLICK, listener);
        return btn;
    }

    private function onPostClicked(e: MouseEvent) {
        trace("post clicked, e=" + e);
        finish(RoxScreen.OK);
    }

    private function onToolClicked(e: MouseEvent) {
        trace("tool " + e.target.name + " clicked, e=" + e);
        switch (e.target.name) {
        case "照片":
            startScreen("com.weiplus.client.ImageEditor");
        case "录音":
#if android
            AndroidHelper.startImageCapture(101, "/sdcard/a123456.jpg");
#end
        }

    }

    private function onSiteClicked(e: MouseEvent) {
        trace("site " + e.target.name + " clicked, e=" + e);
    }

}