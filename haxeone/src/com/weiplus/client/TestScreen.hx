package com.weiplus.client;

import nme.geom.Rectangle;
import nme.utils.ByteArray;
import com.roxstudio.haxe.game.Preloader;
import com.weiplus.client.model.User;
import com.weiplus.client.model.AppData;
import com.weiplus.client.model.Status;
import nme.geom.Point;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.UiUtil;
import nme.display.Shape;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.ui.RoxAsyncBitmap;
import nme.events.Event;
import com.eclecticdesignstudio.spritesheet.AnimatedSprite;
import com.eclecticdesignstudio.spritesheet.data.BehaviorData;
import com.eclecticdesignstudio.spritesheet.data.SpritesheetFrame;
import com.eclecticdesignstudio.spritesheet.Spritesheet;
import com.roxstudio.haxe.ui.UiUtil;
import nme.text.TextField;
import nme.text.TextFormat;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.geom.Matrix;
import nme.filters.DropShadowFilter;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.RoxNinePatch;
import nme.geom.Rectangle;
import nme.display.Sprite;
import com.roxstudio.haxe.ui.RoxScreen;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class TestScreen extends BaseScreen {

    private var prevTime: Int;
    private var prog: Array<AnimatedSprite>;

    public function new() {
        super();
        title = new Sprite();
//        title.addChild(new Bitmap(ImageUtil.getBitmapData("res/icon_logo.png")).rox_smooth());
        title.addChild(UiUtil.staticText("测试标题", 0xFF0000, 36));
    }

    override public function onCreate() {
        super.onCreate();
        addTitleButton(UiUtil.button("res/icon_single_column.png", null, "res/btn_common.9.png"), UiUtil.RIGHT);
    }

    override public function createContent(height: Float) : Sprite {
        var content = new Sprite();
//        var bmd = GameUtil.loadBitmapData("res/btn_red.png");
//        graphics.beginBitmapFill(bmd, new Matrix(0.5, 0, 0, 0.5, 20, 20), true, true);
//        graphics.drawRoundRect(0, 0, bmd.width, bmd.height, 20);
//        graphics.endFill();

//        var bmp = new Bitmap(bmd);
//        var s = new Sprite().rox_button("res/btn_red.png");
//        var nine = new RoxNinePatch(GameUtil.loadBitmapData("res/btn_play.png"), new Rectangle(48, 20, 214, 60));
//        var nine = RoxNinePatch.fromAndroidNinePng(GameUtil.loadBitmapData("res/shadow6.9.png"));
//        nine = new RoxNinePatch(GameUtil.loadBitmapData("res/shadow6_1.png"), nine.ninePatchGrid);
//        nine.setDimension(bmd.width + 2, bmp.height + 4);

//        nine.rox_move(99, 99);
//        addChild(nine);
//        bmp.rox_move(100, 100);
//        addChild(bmp);
//        var format = new TextFormat().rox_textFormat(0, 36);
//        var txt = new TextField().rox_label("测试按钮", format, false);
//        var bg = ImageUtil.getNinePatch("res/btn_common.9.png");
//        var sp = new RoxButton(null, null, UiUtil.CENTER, new Bitmap(ImageUtil.getBitmapData("res/icon_home.png")).rox_smooth(), txt, bg, UiUtil.VCENTER);
//        sp.rox_scale(2);
//        sp.rox_move(screenWidth / 2, height / 2);
//        content.addChild(sp);

        content.addChild(UiUtil.button("res/icon_message.png", function(e) {trace(e.target.name + " clicked");}).rox_move(100, 100));
        content.addChild(UiUtil.button("res/clock.png", "CLOCK", 0xFFFFFF, 32, UiUtil.HCENTER, function(e) {trace(e.target.name + " clicked");}).rox_move(100, 200));
        content.addChild(UiUtil.button("res/icon_time.png", "三分钟之前", 0, 20, function(e) {trace(e.target.name + " clicked");}).rox_move(100, 480));

        var tf = UiUtil.staticText("测试阴影", 0xFF0000, 50, false);
//        tf.filters = [ new DropShadowFilter(4.0, 45.0, 0, 0.3) ];
        content.addChild(tf.rox_move(100, 600));
        var shape = new Shape();
        shape.graphics.beginFill(0xFF0000);
        shape.graphics.drawRect(0, 0, 60, 40);
        shape.graphics.endFill();
        tf.mask = shape;
        content.addChild(shape.rox_move(100, 600));
//        var sheet = new Spritesheet(ImageUtil.getBitmapData("res/progress.png"));
//        var frames: Array<Int> = [];
//        for (i in 0...12) {
//            sheet.addFrame(new SpritesheetFrame(100 * i, 0, 100, 100));
//            frames.push(i);
//        }
//        sheet.addBehavior(new BehaviorData("loading", frames, true, 10, 50, 50));
//        prog = [];
//        var xx = [ 1, -1, 1, -1 ], yy = [ 1, 1, -0.8, -0.8 ];
//        for (i in 0...4) {
//            prog[i] = new AnimatedSprite(sheet);
//            prog[i].showBehavior("loading");
//            prog[i].transform.matrix = new Matrix(xx[i], 0, 0, yy[i], 0, 0);
//            content.addChild(prog[i].rox_move(200, 200 + 120 * i));
//        }
//        addEventListener(Event.ENTER_FRAME, update);
//        sp.addChild(new Bitmap(ImageUtil.getBitmapData("res/content2.jpg")));
//        trace("before scale: " + sp.width +","+sp.height);
//        sp.x = 100;
//        sp.y = 150;
//        sp.width = 200;
//        sp.height = 150;
//        addChild(sp);
//        trace("after scale: " + sp.width +","+sp.height);

//        this.filters = [ new DropShadowFilter(4.0, 45.0, 0, 0.3) ];

//        var remote = new RoxAsyncBitmap("http://img.my.csdn.net/uploads/201212/19/1355883342_4474.png", 500, 500,
//                UiUtil.rox_bitmap("res/clock.png"), UiUtil.rox_bitmap("res/bg_play_tip.png"));
//        content.addChild(remote.rox_move(20, 200));
//        var icon = UiUtil.bitmap("res/icon_bubble.png");
//        var text = UiUtil.staticText("我这里就是要测试一下文字是否能够平滑的放缩abc123ABC!", 0xFF0000, 36, true, 250);
//        var textscale = new RoxFlowPane([ icon, text ], UiUtil.buttonBackground(), UiUtil.TOP);
//        var ag = new RoxGestureAgent(textscale);
//        textscale.addEventListener(RoxGestureEvent.GESTURE_PINCH, ag.getHandler());
//        textscale.addEventListener(RoxGestureEvent.GESTURE_PAN, function(e) {
//            textscale.rox_scale(textscale.scaleX + (e.extra.x > 0 ? 0.1 : -0.1));
//
//        });
//        content.addChild(textscale.rox_move(50, 200));
//
//        var status = new Status();
//        status.text = "【苹果电视要来了?】";
//        status.createdAt = new Date(2012, 11, 29, 17, 49, 11);
//        var appdata: AppData = status.appData = new AppData();
//        appdata.label = "记录我的心情点滴";
//        appdata.type = "jigsaw";
//        appdata.image = "res/content1pot.jpg";
//        appdata.width = appdata.height = 512;
//        var user: User = status.user = new User();
//        user.name = "李开复";
//        user.profileImage = "res/avatar1.png";
//        var postit = new Postit(status, 480, false);
//
//        var shadow = UiUtil.ninePatch("res/shadow6.9.png");
//        shadow.setDimension(postit.width + 3, postit.height + 6);
//        content.addChild(shadow.rox_move(10, 11));
//        content.addChild(postit.rox_move(12, 12));
        var nn = [ 1, 3, 4, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17 ];
        var assets = [ ];
        for (i in nn) assets.push("assets://res/data/" + i + ".jpg");
//        for (i in nn) assets.push("file:///D:/work/ws_haxe/weiplus-github/haxeone/res/data/" + i + ".jpg");
//        for (i in nn) assets.push("http://rox.local/res/data/" + i + ".jpg");
//        assets.push("http://rox.local/res/data/data.zip");
        var ldr = new Preloader(assets, "mybundle", true);
        ldr.addEventListener(Event.COMPLETE, function(_) {
            var map = ResKeeper.getBundle("mybundle");
            trace("================ done ==================");
            for (id in map.keys()) {
                var val = map.get(id);
                if (Std.is(val, BitmapData)) {
                    trace(">>" + id + "=IMG(" + val.width + "," + val.height + ")");
                } else if (Std.is(val, String)) {
                    trace(">>" + id + "=STR(" + val + ")");
                } else if (Std.is(val, ByteArray)) {
                    trace(">>" + id + "=DATA[" + val.length + "]");
                }
            }
        });

//        var bb = ResKeeper.loadAssetData("res/data/1.jpg.dat");
//        var img = BitmapData.loadFromBytes(bb);
//        trace("img="+img.width+","+img.height);

        var img = ResKeeper.getAssetImage("res/shape.png");
        var rt = new Sprite();
//        rt.graphics.rox_drawImage(img, new Matrix(1, 0, 0, 1, 25, 25), 25, 25, 300, 300);
        rt.graphics.rox_drawRegion(img, new Rectangle(275, 25, 200, 200),  10, 10, 240, 160);
        content.addChild(rt);

        return content;
    }

    private function update(e) {
        var currTime = nme.Lib.getTimer();
        var deltaTime: Int = currTime - prevTime;
        for (i in 0...4) prog[i].update(deltaTime);
        prevTime = currTime;
    }

}
