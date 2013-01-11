package com.weiplus.client;

import com.eclecticdesignstudio.motion.Actuate;
import nme.display.Bitmap;
import nme.display.BitmapData;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.RoxAnimate;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.ui.UiUtil;
import com.weiplus.client.model.User;
import com.weiplus.client.model.AppData;
import com.weiplus.client.model.Status;
import nme.display.DisplayObject;
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
#if !html5
import com.weiplus.apps.jigsaw.App;
#end
import com.weiplus.apps.slidepuzzle.App;
import com.weiplus.apps.swappuzzle.App;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class HomeScreen extends BaseScreen {

    private static inline var SPACING_RATIO = 1 / 40;

    var btnSingleCol: RoxFlowPane;
    var btnDoubleCol: RoxFlowPane;
    var btnCol: RoxFlowPane;
    var main: Sprite;
    var mainh: Float;
    var viewh: Float;
    var agent: RoxGestureAgent;
    var numCol: Int = 2;
    var postits: Array<Postit>;
    var animating: Bool = false;

    override public function onCreate() {
        title = UiUtil.bitmap("res/icon_logo.png");
        hasBack = false;
        super.onCreate();
        btnCol = btnSingleCol = UiUtil.button("res/icon_single_column.png", null, "res/btn_common.9.png", onButton);
        addTitleButton(btnCol, UiUtil.RIGHT);
        btnDoubleCol = UiUtil.button("res/icon_double_column.png", null, "res/btn_common.9.png", onButton);
        agent = new RoxGestureAgent(content, RoxGestureAgent.GESTURE);
        content.addEventListener(RoxGestureEvent.GESTURE_PAN, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_TAP, onGesture);
        content.addEventListener(RoxGestureEvent.GESTURE_PINCH, onGesture);
    }

    override public function createContent(height: Float) : Sprite {
        var sp = new Sprite();

        main = new Sprite();
        update(2);
        sp.addChild(main);

        var btnNames = [ "icon_home", "icon_selected", "icon_maker", "icon_message", "icon_account" ];
        var btns: Array<DisplayObject> = [];
        for (b in btnNames) {
            var w = 126, h = 89;
            if (b == "icon_maker") w = 128;
            var button = new RoxFlowPane(w, h, [ UiUtil.bitmap("res/" + b + ".png") ], onButton);
            button.name = b;
            btns.push(button);
        }
        var bmd = ResKeeper.getAssetImage("res/bg_main_bottom.png");
        var npdata = new RoxNinePatchData(new Rectangle(0, 0, bmd.width, bmd.height), bmd);
        var btnpanel = new RoxFlowPane(null, null, UiUtil.LEFT | UiUtil.BOTTOM, btns,
                new RoxNinePatch(npdata), UiUtil.BOTTOM, [ 2 ]);
        sp.addChild(btnpanel.rox_scale(d2rScale).rox_move(0, height));
//        trace("btnpanel="+btnpanel.x+","+btnpanel.y+","+btnpanel.width+","+btnpanel.height);
        viewh = height - 95 * d2rScale;
        return sp;
    }

    private function update(numCol: Int) {
        if (agent != null) agent.stopTween();
        var bmd1: BitmapData = null, sp1: Sprite = null;
        if (postits != null) {
            bmd1 = new BitmapData(Std.int(screenWidth), Std.int(viewh), true, 0);
            bmd1.draw(main, new Matrix(1, 0, 0, 1, 0, main.y));
            sp1 = new Sprite();
            sp1.addChild(new Bitmap(bmd1).rox_move(-bmd1.width / 2, -bmd1.height / 2));
        }
        this.numCol = numCol;
        var idx = 0;
        if (postits != null) {
            for (i in 0...postits.length) {
                var p = postits[i];
                if (p.y + main.y > 0) {
                    idx = i;
                    break;
                }
            }
        }
        main.rox_removeAll();
        main.graphics.clear();
        var colh: Array<Float> = [];
        for (i in 0...numCol) colh.push(0);
        var spacing = screenWidth * SPACING_RATIO;
        var postitw = (screenWidth - (numCol + 1) * spacing) / numCol;
        var resetwidth = postits != null;
        if (postits == null) {
            postits = [];
            for (ss in statuses) {
                var status = new Status();
                status.user = new User();
                status.appData = new AppData();
                status.user.name = ss[0];
                status.user.profileImage = ss[1];
                status.appData.image = ss[3];
                status.appData.type = ss[4];
                status.appData.label = ss[5];
//                var bmd = ResKeeper.loadAssetImage(ss[3]);
                status.appData.width = Std.parseInt(ss[6]);
                status.appData.height = Std.parseInt(ss[7]);
                status.text = ss[2];
                status.createdAt = Date.fromTime(Date.now().getTime() - Std.random(3600));
                var postit = new Postit(status, postitw, numCol == 1);
                postit.addEventListener(Event.SELECT, onPlay);
                postits.push(postit);
            }
        }
        var postity = 0.0;
        for (i in 0...postits.length) {
            var postit = postits[i];
            if (resetwidth) postit.setWidth(postitw, numCol == 1);
            var shadow = UiUtil.ninePatch("res/shadow6.9.png");
            shadow.setDimension(postitw + 3, postit.height + 6);

            var minh: Float = GameUtil.IMAX, colidx = 0;
            for (i in 0...colh.length) {
                if (colh[i] < minh) { minh = colh[i]; colidx = i; }
            }
            postit.rox_move(spacing + colidx * (postitw + spacing), minh + spacing);
            shadow.rox_move(postit.x - 2, postit.y);
            main.addChild(shadow);
            main.addChild(postit);
            colh[colidx] += postit.height + spacing;
            if (i == idx) {
                postity = postit.y;
            }
        }
        mainh = 0;
        for (i in 0...colh.length) {
            if (colh[i] > mainh) { mainh = colh[i]; }
        }
        mainh += spacing;
        main.graphics.rox_fillRect(0x01FFFFFF, 0, 0, main.width, main.height);

        main.y = spacing - postity;
        main.y = UiUtil.rangeValue(main.y, viewh - mainh, 0);

        if (sp1 != null) {
            animating = true;
            content.addChild(sp1.rox_move(bmd1.width / 2, bmd1.height / 2));
            if (numCol == 1) { // zoom in
                Actuate.tween(sp1, 0.4, { scaleX: 4, scaleY: 4, alpha: 0 }).onComplete(animDone, [ sp1 ]);
            } else {
                sp1.rox_scale(4);
                Actuate.tween(sp1, 0.4, { scaleX: 1, scaleY: 1, alpha: 0 }).onComplete(animDone, [ sp1 ]);
            }
        }
    }

    private function onPlay(e: Dynamic) {
//        trace("HomeScreen.onPlay: e.target=" + e.target);
        var postit: Postit = cast(e.target);
        var status = postit.status;
        var classname = "com.weiplus.apps." + status.appData.type + ".App";
        startScreen(classname, { image: postit.image.data, sideLen: Std.parseInt(status.appData.label) });
    }

    private inline function animDone(sp: DisplayObject) {
        content.removeChild(sp);
        animating = false;
    }

    private function onGesture(e: RoxGestureEvent) {
        if (animating) return;
        trace(">>>t=" + e.target+",e="+e);
        switch (e.type) {
            case RoxGestureEvent.GESTURE_TAP:
                for (i in 0...main.numChildren) {
                    var sp = main.getChildAt(i);
                    if (Std.is(sp, Postit)) {
//                        trace("e=" + e + ",sp=("+sp.x+","+sp.y+","+sp.width+","+sp.height+")");
// TODO: in gestureagent, handle bubbled mouse/touch event, use currentTarget as owner?
                        var pt = main.localToGlobal(new Point(sp.x, sp.y));
                        if (GameUtil.pointInRect(e.stageX, e.stageY, pt.x, pt.y, sp.width, sp.height)) {
                            var postit: Postit = cast(sp);
                            var r = new Rectangle(pt.x, pt.y, sp.width, sp.height);
//                            startScreen(Type.getClassName(PostitScreen), new RoxAnimate(RoxAnimate.ZOOM_IN, r), postit.status);
                            return;
                        }
                    }
                }
            case RoxGestureEvent.GESTURE_PAN:
                var pt = RoxGestureAgent.localOffset(main, cast(e.extra));
                main.y = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh, GameUtil.IMIN, 0), 0);
            case RoxGestureEvent.GESTURE_SWIPE:
                var pt = RoxGestureAgent.localOffset(main, cast(new Point(e.extra.x * 2.0, e.extra.y * 2.0)));
                var desty = UiUtil.rangeValue(main.y + pt.y, UiUtil.rangeValue(viewh - mainh, GameUtil.IMIN, 0), 0);
                agent.startTween(main, 2.0, { y: desty });
            case RoxGestureEvent.GESTURE_PINCH:
//                trace("pinch:numCol=" + numCol + ",extra=" + e.extra);
                if (numCol > 1 && e.extra > 1) {
                    removeTitleButton(btnCol);
                    addTitleButton(btnCol = btnDoubleCol, UiUtil.RIGHT);
                    update(1);
                } else if (numCol == 1 && e.extra < 1) {
                    removeTitleButton(btnCol);
                    addTitleButton(btnCol = btnSingleCol, UiUtil.RIGHT);
                    update(2);
                }
        }
    }

    private function onButton(e: Event) {
        if (animating) return;
        trace("button " + e.target.name + " clicked");
        switch (e.target.name) {
            case "icon_single_column":
                removeTitleButton(btnCol);
                addTitleButton(btnCol = btnDoubleCol, UiUtil.RIGHT);
                update(1);
            case "icon_double_column":
                removeTitleButton(btnCol);
                addTitleButton(btnCol = btnSingleCol, UiUtil.RIGHT);
                update(2);
            case "icon_home":
//                startScreen(Type.getClassName(com.weiplus.client.TestGesture), new RoxAnimate(RoxAnimate.ZOOM_IN, new Rectangle(80, 80, 200, 300)));
            case "icon_selected":
                startScreen(Type.getClassName(SelectedScreen));
            case "icon_maker":
                startScreen(Type.getClassName(MakerList));
            case "icon_account":
                startScreen(Type.getClassName(UserScreen));
        }
    }

    private static var statuses = [
    [ "趣图集锦", "http://rox.local/res/data/head5.png", "这人民币折纸无敌了！", "http://rox.local/res/data/17.jpg", "slidepuzzle", "120", "389", "409" ],
    [ "王磊", "http://rox.local/res/data/head2.png", "这网站的有些家伙，只能用这幅图形容了", "http://rox.local/res/data/14.jpg", "image", "", "264", "163" ],
    [ "中兴手机", "http://rox.local/res/data/head6.png", "你能认出几个美国超人？", "http://rox.local/res/data/16.jpg", "swappuzzle", "110", "448", "387" ],
    [ "趣图集锦", "http://rox.local/res/data/head5.png", "鸡蛋中的异类", "http://rox.local/res/data/15.jpg", "image", "", "349", "342" ],
    [ "王磊", "http://rox.local/res/data/head2.png", "haXe才是移动平台的王者", "http://rox.local/res/data/4.jpg", "jigsaw", "120", "600", "375" ],
    [ "伏英娜", "http://rox.local/res/data/head1.png", "晴朗的天空", "http://rox.local/res/data/9.jpg", "jigsaw", "120", "640", "480" ],
    [ "徐野", "http://rox.local/res/data/head5.png", "转个搞笑图，等短信的表情", "http://rox.local/res/data/7.jpg", "image", "", "338", "720" ],
    [ "超级红裤衩", "http://rox.local/res/data/head3.png", "兔子的征途是星辰大海！", "http://rox.local/res/data/11.jpg", "slidepuzzle", "140", "445", "617" ],
    [ "周鸿祎", "http://rox.local/res/data/head4.png", "强敌环伺的360", "http://rox.local/res/data/1.jpg", "jigsaw", "130", "770", "556" ],
    [ "尤成", "http://rox.local/res/data/head6.png", "猜猜谁是真正的凶手？", "http://rox.local/res/data/12.jpg", "image", "", "600", "673" ],
    [ "Christina", "http://rox.local/res/data/head1.png", "This's my friend, is she beautiful?", "http://rox.local/res/data/8.jpg", "jigsaw", "110", "580", "580" ],
    [ "郝晓伟", "http://rox.local/res/data/head7.png", "斑马的由来", "http://rox.local/res/data/10.jpg", "image", "", "440", "1980" ],
    [ "姚卫峰", "http://rox.local/res/data/head3.png", "我心目中的巨人，拼出来你就知道是谁了", "http://rox.local/res/data/3.jpg", "swappuzzle", "110", "350", "443" ]
    ];

}
