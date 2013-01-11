package com.weiplus.client;

import com.weiplus.client.model.User;
import com.weiplus.client.model.AppData;
import com.weiplus.client.model.Status;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxScreenManager;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.filters.DropShadowFilter;
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

/**
 * ...
 * @author Rocks Wang
 */

class OldHomeScreen extends RoxScreen {

    static inline var BG_COLOR = 0xDDDDDD;

    var btnRefresh: Sprite;
    var btnHome: Sprite;
    var btnSelected: Sprite;
    var btnWrite: Sprite;
    var btnMessage: Sprite;
    var btnAccount: Sprite;

    var clickPoint: Point;

    public function new(manager: RoxScreenManager) {
        super(manager);
        var container = new Sprite();
//        this.cacheAsBitmap = true;
        screenWidth = 640;
        var scale = RoxApp.screenWidth / screenWidth;
        screenHeight = RoxApp.screenHeight / scale;
        trace("screen=" + RoxApp.screenWidth +"," + RoxApp.screenHeight +",my=" + screenWidth + "," + screenHeight + ",sc=" + scale);
        container.scaleX = container.scaleY = scale;
        container.graphics.beginFill(BG_COLOR);
        container.graphics.drawRect(0, 0, screenWidth, screenHeight);
        container.graphics.endFill();
        addChild(container);

        var titlebar = Utils.smoothBmp(GameUtil.loadBitmapData("res/titlebar.jpg"));

        var contentPane = new ScrollPane(new Rectangle(0, 0, screenWidth, screenHeight - titlebar.height), false, true);
        contentPane.y = titlebar.height;
        var yoffset = 8.0;
#if android
        var format = new TextFormat(new nme.text.Font("/system/fonts/DroidSansFallback.ttf").fontName);
#else
        var format = new TextFormat();
#end
        format.color = 0x0;
        format.size = 32;
        for (i in 0...10) {
            var avatar = Utils.smoothBmp(GameUtil.loadBitmapData("res/avatar1.png"));
            avatar.x = 16;
            avatar.y = yoffset;
            contentPane.addChild(avatar);
            var label = new TextField();
            label.defaultTextFormat = format;
            label.wordWrap = false;
            label.multiline = false;
            label.width = 400;
            label.height = 42;
            label.x = 90;
            label.y = yoffset + 6;
            label.selectable = false;
            label.mouseEnabled = false;
            label.text = "天使宝贝1991";
            contentPane.addChild(label);
            var imgbg = new Sprite();
            imgbg.graphics.beginFill(0xFFFFFF);
            imgbg.graphics.drawRect(0, 0, 606, 606);
            imgbg.graphics.endFill();
            imgbg.filters = [ new DropShadowFilter() ];
            imgbg.x = 16;
            imgbg.y = yoffset + avatar.height + 10;
            var bmd = GameUtil.loadBitmapData("res/content1.jpg");
            var img = Utils.smoothBmp(bmd);
            img.x = (imgbg.width - bmd.width) / 2;
            img.y = (imgbg.height - bmd.height) / 2;
            imgbg.addChild(img);
            contentPane.addChild(imgbg);
            var msg = new TextField();
            msg.defaultTextFormat = format;
            msg.wordWrap = true;
            msg.multiline = true;
            msg.width = 580;
            msg.height = 200;
            msg.addEventListener(Event.ADDED_TO_STAGE, function(e) { trace(e.target); } );
            msg.x = 56;
            msg.y = yoffset + avatar.height + 10 + imgbg.height + 10;
            msg.selectable = false;
            msg.mouseEnabled = false;
            msg.text = "为某杂志最新拍摄的封面，大家看如何啊？";
            contentPane.addChild(msg);
            var topic = Utils.smoothBmp(GameUtil.loadBitmapData("res/ico_topic.png"));
            topic.x = 16;
            topic.y = msg.y + 5;
            contentPane.addChild(topic);
            yoffset += avatar.height + 10 + imgbg.height + 10 + msg.textHeight + 10;

        }
        container.addChild(contentPane);

        container.addChild(titlebar);

        var xoffset = 0.0;
        btnHome = new Sprite();
        var bmd = GameUtil.loadBitmapData("res/btnHome.png");
        btnHome.addChild(Utils.smoothBmp(bmd));
        btnHome.mouseChildren = false;
        btnHome.mouseEnabled = true;
        btnHome.x = xoffset;
        xoffset += bmd.width;
        btnHome.y = screenHeight - bmd.height;
        btnHome.addEventListener(MouseEvent.CLICK, onHomeClicked);
        container.addChild(btnHome);

        btnSelected = new Sprite();
        bmd = GameUtil.loadBitmapData("res/btnSelected.png");
        btnSelected.addChild(Utils.smoothBmp(bmd));
        btnSelected.mouseChildren = false;
        btnSelected.mouseEnabled = true;
        btnSelected.x = xoffset;
        xoffset += bmd.width;
        btnSelected.y = screenHeight - bmd.height;
        btnSelected.addEventListener(MouseEvent.CLICK, onSelectedClicked);
        container.addChild(btnSelected);

        btnWrite = new Sprite();
        bmd = GameUtil.loadBitmapData("res/btnWrite.png");
        btnWrite.addChild(Utils.smoothBmp(bmd));
        btnWrite.mouseChildren = false;
        btnWrite.mouseEnabled = true;
        btnWrite.x = xoffset;
        xoffset += bmd.width;
        btnWrite.y = screenHeight - bmd.height;
        btnWrite.addEventListener(MouseEvent.CLICK, onWriteClicked);
        container.addChild(btnWrite);

        btnMessage = new Sprite();
        bmd = GameUtil.loadBitmapData("res/btnMessage.png");
        btnMessage.addChild(Utils.smoothBmp(bmd));
        btnMessage.mouseChildren = false;
        btnMessage.mouseEnabled = true;
        btnMessage.x = xoffset;
        xoffset += bmd.width;
        btnMessage.y = screenHeight - bmd.height;
        btnMessage.addEventListener(MouseEvent.CLICK, onMessageClicked);
        container.addChild(btnMessage);

        btnAccount = new Sprite();
        bmd = GameUtil.loadBitmapData("res/btnAccount.png");
        btnAccount.addChild(Utils.smoothBmp(bmd));
        btnAccount.mouseChildren = false;
        btnAccount.mouseEnabled = true;
        btnAccount.x = xoffset;
        btnAccount.y = screenHeight - bmd.height;
        btnAccount.addEventListener(MouseEvent.CLICK, onAccountClicked);
        container.addChild(btnAccount);

    }

    private function onHomeClicked(e: MouseEvent) {
        trace("home clicked, e=" + e);
    }

    private function onSelectedClicked(e: MouseEvent) {
        trace("selected clicked, e=" + e);
        var status = new Status();
        status.text = "从java代码中操作DOM：最简单的办法是使用WebView.loadUrl()，用这个方法可以方便的对DOM进行修改，可以使用JQuery。这个方法的缺点是没法读取DOM，而只能修改，或调用js方法。";
        var appdata: AppData = status.appData = new AppData();
        appdata.label = "记录我的心情点滴";
        appdata.image = "res/content1.jpg";
        var user: User = status.user = new User();
        user.name = "中国haXe爱好者";
        user.profileImage = "res/avatar1.png";
        startScreen("com.weiplus.client.PostitScreen", status);
    }

    private function onWriteClicked(e: MouseEvent) {
        trace("write clicked, e=" + e);
        startScreen(Type.getClassName(com.weiplus.client.RichEditor));
    }

    private function onMessageClicked(e: MouseEvent) {
        trace("message clicked, e=" + e);
    }

    private function onAccountClicked(e: MouseEvent) {
        trace("account clicked, e=" + e);
    }

}