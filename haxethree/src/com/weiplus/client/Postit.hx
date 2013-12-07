package com.weiplus.client;

import flash.geom.Point;
import com.weiplus.client.TimelineScreen;
import com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.i18n.I18n;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import nme.events.MouseEvent;
import com.weiplus.client.HpApi;
import nme.display.DisplayObjectContainer;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.events.Event;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.weiplus.client.model.AppData;
import com.weiplus.client.model.Status;
import com.weiplus.client.model.Comment;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.DisplayObject;
import nme.display.BitmapData;
import nme.geom.Matrix;
import nme.geom.Rectangle;
import nme.text.TextField;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;
using StringTools;

class Postit extends Sprite {

    public static inline var COMPACT = 1;
    public static inline var NORMAL = 2;
    public static inline var FULL = 3;

    public var status: Status;

    private static inline var MARGIN_RATIO = 1 / 40;

    private static inline var FONT_SIZE_RATIO = 32 / 600;
    private static inline var MIN_FONT_SIZE = 16.0;

    private var userAvatar: RoxFlowPane;
    private var userLabel: TextField;
    private var dateLabel: RoxFlowPane;
    private var infoLabel: RoxFlowPane; // numRetweets, numComments, numLikes etc.
    private var imageScale: Float;
    private var imageOffset: Float;
    private var w: Float;
    private var mode: Int;

    private var head: Sprite;
    private var imh: Float;
    private var imgLoaded: Bool = false;

    private var parentScreen: TimelineScreen;

    private static var ptnUrl = ~/http[s]?:\/\/[^ $]+/i;

    public var imageBounds(get_imageBounds, null): Point;

    private inline function get_imageBounds() {
        return new Point(w, imh);
    }

    public function new(parent: TimelineScreen, inStatus: Status, width: Float, mode: Int) {
        super();
        this.parentScreen = parent;
        this.status = inStatus;
        this.name = "postit_" + status.id;
        setWidth(width, mode);
//        trace(name + " created");
    }

    public function update() {
        var visible = !(this.y + this.height + parentScreen.main.y < 0 || this.y + parentScreen.main.y > parentScreen.viewh);
        if (imgLoaded || !visible) return;
//        trace("update postit "+this.name+":y="+this.y+",h="+this.height+",mainy="+parent.main.y+",viewh="+parent.viewh+",visible="+visible+",shown="+shown);
        if (head != null) {
            MyUtils.asyncImage(status.user.profileImage, function(img: BitmapData) {
                if (img == null || img.width == 0) img = ResKeeper.getAssetImage("res/no_avatar.png");
                var headSize = UiUtil.rangeValue(width * 0.12, 30, 60);
                head.graphics.clear();
                head.graphics.rox_drawRegion(img, 0, 0, headSize, headSize);
            }, false);
        }
        var appdata = status.appData;
        if (appdata != null && appdata.width > 0 && appdata.height > 0 && appdata.image != null) {
            MyUtils.asyncImage(appdata.image, function(image: BitmapData) {
                UiUtil.rox_removeByName(this, MyUtils.LOADING_ANIM_NAME);
                if (image != null && image.width > 0) {
//                    var bmd = new BitmapData(Std.int(w), Std.int(h), true, 0);
//                trace(">>>>>>>>>>>>>>>>>data="+imgLdr.data);
//                    bmd.draw(image, , true);
                    var r = 6;
                    if (mode == COMPACT) {
                        graphics.rox_drawRegionRound(image, 0, 0, w, imh, r);
                    } else if (imageScale == 1 && imageOffset > 0) {
                        graphics.rox_drawRegion(image, imageOffset, 0, w - 2 * imageOffset, imh);
                    } else {
                        var scale = this.w / image.width;
                        graphics.beginBitmapFill(image, new Matrix(scale, 0, 0, scale, imageOffset, 0), false, true);
                        graphics.moveTo(0, r);
                        graphics.curveTo(0, 0, r, 0);
                        graphics.lineTo(w - r, 0);
                        graphics.curveTo(w, 0, w, r);
                        graphics.lineTo(w, imh);
                        graphics.lineTo(0, imh);
                        graphics.lineTo(0, r);
                        graphics.endFill();
                    }
                    if (status.isGame()) {
                        var playButton = UiUtil.button("res/btn_play.png");
//                    trace("imw=" + imw + ",appdata.w="+appdata.width+",scale="+(imw/640));
                        playButton.rox_scale(w / 640);
                        playButton.rox_move((w - playButton.width) / 2, (imh - playButton.height) / 2);
                        addChild(playButton);
//                    } else {
//                        var button = new Sprite();
//                        button.graphics.rox_fillRect(0x01FFFFFF, 0, 0, w, imh);
//                        var agent = new RoxGestureAgent(button);
//                        agent.swipeTimeout = 0;
//                        button.addEventListener(RoxGestureEvent.GESTURE_TAP, function(_) {
//                            parentScreen.startScreen(Type.getClassName(PictureScreen), { status: status, image: image });
//                        });
//                        addChild(button);
                    }
//                trace("im="+imw+","+imh+",scale="+imageScale+",offset="+imageOffset);
                } else {
                    var placeholder = UiUtil.staticText("载入失败".i18n());
                    addChild(placeholder.rox_move((w - placeholder.width) / 2, (imh - placeholder.height) / 2));
                }
            }, false);
            var anim = MyUtils.getLoadingAnim("载入中".i18n());
            addChild(anim.rox_move(w / 2, imh / 2));
        }
        imgLoaded = true;
    }

    public function setWidth(width: Float, mode: Int) {
        this.w = width;
        this.mode = mode;
        this.rox_removeAll();
        this.graphics.clear();
        var margin = width * MARGIN_RATIO;
        var fontsize = width * FONT_SIZE_RATIO;
        if (fontsize < MIN_FONT_SIZE) fontsize = MIN_FONT_SIZE;
        var appdata = status.appData;
        imh = 0.0;
        var liney = -1.0;
        var layout: RoxNinePatchData = null;
        if (appdata != null) {
            var imw = appdata.width;
            imageScale = imw > width ? width / imw : 1.0;
            imageOffset = imw > width ? 0 : (width - imw) / 2;
            imh = appdata.height * imageScale;
        } else {
            imageScale = 1;
            imageOffset = 0;
        }
        var h = imh;

        if (mode != COMPACT) {
            h += margin;
            var bub = UiUtil.bitmap("res/icon_bubble.png");
            layout = new RoxNinePatchData(new Rectangle(margin, 0, 20, 20), null, null, new Rectangle(0, 0, 20 + 2 * margin, 20 + margin));
            var txt: String = status.user.id == HpApi.instance.uid || status.mark <= 100 ? status.text : "此条微博已经被设置为私有";
            if (ptnUrl.match(txt)) {
//                trace("remove before: " + txt);
                txt = ptnUrl.replace(txt, "");
//                trace("remove after: " + txt);
            }
            var texth: Null<Float> = mode == FULL ? null : fontsize * 2.8;
            var text = UiUtil.staticText(txt, 0, fontsize, true, width - bub.width - 4 - 2 * layout.contentGrid.x, texth);
            var imageLabel = new RoxFlowPane([ bub, text ], new RoxNinePatch(layout), UiUtil.TOP, [ 4 ]);
            addChild(imageLabel.rox_move(0, h));
            h += imageLabel.height;
            liney = h;
            h += 2 + margin;

            head = new Sprite();
            var headSize = UiUtil.rangeValue(width * 0.12, 30, 60);
            head.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, headSize, headSize);
//            MyUtils.asyncImage(status.user.profileImage, function(img: BitmapData) {
//                if (img == null || img.width == 0) img = ResKeeper.getAssetImage("res/no_avatar.png");
//                head.graphics.clear();
//                head.graphics.rox_drawRegion(img, 0, 0, headSize, headSize);
//            });
            var avbg = UiUtil.ninePatch("res/avatar_bg.9.png");
            userAvatar = new RoxFlowPane([ head ], avbg, function(_) {
                parentScreen.startScreen(Type.getClassName(UserScreen), "UserScreen_" + status.user.id, status.user.id);
            });
            userLabel = UiUtil.staticText(status.user.name, 0xFF0000, fontsize + 4, w - userAvatar.width - 2 * margin);
            var clock = UiUtil.bitmap("res/icon_time.png");
            var time = UiUtil.staticText(MyUtils.timeStr(status.createdAt), 0, fontsize);
            var compact = new RoxNinePatchData(new Rectangle(0, 0, headSize * 0.4, headSize * 0.4));
            dateLabel = new RoxFlowPane([ clock, time ], new RoxNinePatch(compact));
            var tmp = new RoxFlowPane([ userLabel, dateLabel ], new RoxNinePatch(compact), UiUtil.LEFT);
            var hlayout = new RoxFlowPane([ userAvatar, tmp ], new RoxNinePatch(layout), [ margin ]);
            addChild(hlayout.rox_move(0, h));
            h += hlayout.height;
        }

        if (mode == FULL && !HpApi.instance.isDefault()) {
            var arr: Array<DisplayObject> = [];
            var praisebtn = UiUtil.button(UiUtil.TOP_LEFT, status.praised ? "res/icon_praised.png" : "res/icon_praise.png",
                "赞(".i18n() + status.praiseCount + ")", 0, fontsize + 2, "res/btn_grey.9.png", onButton);
            praisebtn.name = "praise_" + status.id;
            arr.push(praisebtn);
            var commentbtn = UiUtil.button(UiUtil.TOP_LEFT, "res/icon_comment.png",
                "评论(".i18n() + status.commentCount + ")", 0, fontsize + 2, "res/btn_grey.9.png", onButton);
            commentbtn.name = "comment_" + status.id;
            arr.push(commentbtn);
//            var morebtn = UiUtil.button(UiUtil.TOP_LEFT, "res/icon_more.png",
//                    null, "res/btn_grey.9.png", onButton);
//            morebtn.name = "more_" + status.id;
            var repostbtn = UiUtil.button(UiUtil.TOP_LEFT, null, "转发".i18n(), 0, fontsize + 2, "res/btn_grey.9.png", onButton);
            repostbtn.name = "repost_" + status.id;
            arr.push(repostbtn);
            if (status.user.id == HpApi.instance.uid) {
                var deletebtn = UiUtil.button(UiUtil.TOP_LEFT, null,
                "删除".i18n(), 0, fontsize + 2, "res/btn_grey.9.png", onButton);
                deletebtn.name = "delete_" + status.id;
                arr.push(deletebtn);
            }
            infoLabel = new RoxFlowPane(arr, new RoxNinePatch(layout));
            addChild(infoLabel.rox_move(0, h));
            h += infoLabel.height;
        }

        GfxUtil.rox_fillRoundRect(graphics, 0xFFFFFFFF, 0, 0, width, h, 6);
        if (liney > 0) GfxUtil.rox_line(graphics, 2, 0xFFE6E6E6, 10, liney, width - 10, liney);

//        if (appdata != null && appdata.width > 0 && appdata.height > 0 && appdata.image != null) {
//            MyUtils.asyncImage(appdata.image, function(image: BitmapData) {
//                UiUtil.rox_removeByName(this, MyUtils.LOADING_ANIM_NAME);
//                if (image != null && image.width > 0) {
////                    var bmd = new BitmapData(Std.int(w), Std.int(h), true, 0);
////                trace(">>>>>>>>>>>>>>>>>data="+imgLdr.data);
////                    bmd.draw(image, , true);
//                    var r = 6;
//                    if (mode == COMPACT) {
//                        graphics.rox_drawRegionRound(image, 0, 0, w, imh, r);
//                    } else if (imageScale == 1 && imageOffset > 0) {
//                        var bmp = new Bitmap(image);
//                        addChild(bmp.rox_move(imageOffset, 0));
//                    } else {
//                        imageScale = this.w / image.width;
//                        graphics.beginBitmapFill(image, new Matrix(imageScale, 0, 0, imageScale, imageOffset, 0), false, true);
//                        graphics.moveTo(0, r);
//                        graphics.curveTo(0, 0, r, 0);
//                        graphics.lineTo(w - r, 0);
//                        graphics.curveTo(w, 0, w, r);
//                        graphics.lineTo(w, imh);
//                        graphics.lineTo(0, imh);
//                        graphics.lineTo(0, r);
//                        graphics.endFill();
//                    }
//                    if (appdata.type != null && appdata.type != "" && appdata.type != AppData.IMAGE) {
//                        var playButton = UiUtil.button("res/btn_play.png", onPlay);
////                    trace("imw=" + imw + ",appdata.w="+appdata.width+",scale="+(imw/640));
//                        playButton.rox_scale(w / 640);
//                        playButton.rox_move((w - playButton.width) / 2, (imh - playButton.height) / 2);
//                        addChild(playButton);
//                    } else {
//                        var button = new Sprite();
//                        button.graphics.rox_fillRect(0x01FFFFFF, 0, 0, w, imh);
//                        var agent = new RoxGestureAgent(button);
//                        agent.swipeTimeout = 0;
//                        button.addEventListener(RoxGestureEvent.GESTURE_TAP, function(_) {
//                            parent.startScreen(Type.getClassName(PictureScreen), image);
//                        });
//                        addChild(button);
//                    }
////                trace("im="+imw+","+imh+",scale="+imageScale+",offset="+imageOffset);
//                } else {
//                    var placeholder = UiUtil.staticText("载入失败".i18n());
//                    addChild(placeholder.rox_move((w - placeholder.width) / 2, (imh - placeholder.height) / 2));
//                }
//            });
//            var anim = MyUtils.getLoadingAnim("载入中".i18n());
//            addChild(anim.rox_move(w / 2, imh / 2));
//        }
        imgLoaded = false;
    }

    private function onPlay(e) {
        this.dispatchEvent(new Event(Event.SELECT));
    }

    private function onButton(e: Dynamic) {
        var name: String = e.target.name;
        var idx = name.indexOf("_");
        var id = name.substr(idx + 1);
        name = name.substr(0, idx);
//#if android
        switch (name) {
            case "praise":
                HpApi.instance.get("/statuses/praise/" + id, {}, function(code: Int, data: Dynamic) {
                    switch (code) {
                        case 200:
                            var stat = data.statuses[0];
                            status.praiseCount = stat.praiseCount;
                            status.praised = !status.praised;
                            setWidth(w, mode);
                            UiUtil.message(status.praised ? "赞 +1".i18n() : "赞已取消".i18n());
                        case 19:
                            UiUtil.message("已经赞过了".i18n());
//                            UiUtil.message
                        default:
                            UiUtil.message("网络错误，ex=".i18n() + data);
                    }
                });
            case "comment":
                parentScreen.startScreen(Type.getClassName(CommentsScreen), null, null, null, 1, id);
            case "delete":
                HpApi.instance.get("/statuses/delete/" + id, {}, function(code: Int, data: Dynamic) {
                    switch (code) {
                        case 200:
                            cast (parentScreen, TimelineScreen).refresh(false);
                            UiUtil.message("已删除".i18n());
                        default:
                            UiUtil.message("网络错误，ex=".i18n() + data);
                    }
                });
            case "repost":
                if (status.isGame()) {
                    parentScreen.startScreen(Type.getClassName(GameRetweetScreen), status);
                } else { // is image
                    var path: String = null;
#if cpp
                    if (MyUtils.localCacheExists(status.appData.image)) {
                        path = MyUtils.localCachePath(status.appData.image);
                    }
#end
                    var tags: Array<String> = [];
                    MyUtils.asyncImage(status.appData.image, function(image: BitmapData) {
                        parentScreen.startScreen(Type.getClassName(RetweetScreen), {
                        status: status,
                        image: { bmd: image, path: path, tags: tags },
                        data: null
                        });
                    });
                }
        }

//#end
    }

}
