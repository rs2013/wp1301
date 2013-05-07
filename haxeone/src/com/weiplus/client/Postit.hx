package com.weiplus.client;

import com.weiplus.client.HpApi;
import nme.display.DisplayObjectContainer;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.events.Event;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.net.RoxURLLoader;
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

class Postit extends Sprite {

    public static inline var COMPACT = 1;
    public static inline var NORMAL = 2;
    public static inline var FULL = 3;

    public var status: Status;

    private static inline var MARGIN_RATIO = 1 / 40;

    private static inline var FONT_SIZE_RATIO = 24 / 600;
    private static inline var MIN_FONT_SIZE = 16.0;

    public var imgLdr: RoxURLLoader;
    private var playButton: RoxFlowPane;
    private var imageLabel: RoxFlowPane;

    private var userAvatar: RoxFlowPane;
    private var userLabel: TextField;
    private var dateLabel: RoxFlowPane;
    private var infoLabel: RoxFlowPane; // numRetweets, numComments, numLikes etc.
    private var imageScale: Float;
    private var imageOffset: Float;
    private var placeholder: DisplayObject;
    private var w: Float;
    private var mode: Int;

    public function new(inStatus: Status, width: Float, mode: Int) {
        super();
        status = inStatus;
        setWidth(width, mode);
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
        var h = 0.0, liney = -1.0;
        var layout: RoxNinePatchData = null;
        if (appdata != null) {
            var imw = appdata.width;
            imageScale = imw > width ? width / imw : 1.0;
            imageOffset = imw > width ? 0 : (width - imw) / 2;
            h = appdata.height * imageScale;
        } else {
            imageScale = 1;
            imageOffset = 0;
        }

        if (mode != COMPACT) {
            h += margin;
            var bub = UiUtil.bitmap("res/icon_bubble.png");
            layout = new RoxNinePatchData(new Rectangle(margin, 0, 20, 20), null, null, new Rectangle(0, 0, 20 + 2 * margin, 20 + margin));
            var txt = status.user.id == HpApi.instance.uid || status.mark <= 100 ? status.text : "此条微博已经被设置为私有";
            var text = UiUtil.staticText(txt, 0, fontsize, true, width - bub.width - 4 - 2 * layout.contentGrid.x);
            imageLabel = new RoxFlowPane([ bub, text ], new RoxNinePatch(layout), UiUtil.TOP, [ 4 ]);
            addChild(imageLabel.rox_move(0, h));
            h += imageLabel.height;
            liney = h;
            h += 2 + margin;

//        var head: DisplayObject = UiUtil.asyncBitmap(status.user.profileImage, 60, 60);
//        if (head.width == 0 || head.height == 0) head = UiUtil.bitmap("res/no_avatar.png");
            var head: Sprite = new Sprite();
            head.graphics.rox_fillRect(0xFFFFFFFF, 0, 0, 60, 60);
            UiUtil.asyncImage(status.user.profileImage, function(img: BitmapData) {
                if (img == null || img.width == 0) img = ResKeeper.getAssetImage("res/no_avatar.png");
                head.graphics.clear();
                head.graphics.rox_drawRegion(img, 0, 0, 60, 60);
            });
            var avbg = UiUtil.ninePatch("res/avatar_bg.9.png");
            userAvatar = new RoxFlowPane([ head ], avbg, function(_) {
                parentScreen().startScreen(Type.getClassName(UserScreen), status.user.id);
            });
            userLabel = UiUtil.staticText(status.user.name, 0xFF0000, fontsize + 4, w - userAvatar.width - 2 * margin);
            var clock = UiUtil.bitmap("res/icon_time.png");
            var time = UiUtil.staticText(MyUtils.timeStr(status.createdAt), 0, fontsize);
            var compact = new RoxNinePatchData(new Rectangle(0, 0, 20, 20));
            dateLabel = new RoxFlowPane([ clock, time ], new RoxNinePatch(compact));
            var tmp = new RoxFlowPane([ userLabel, dateLabel ], new RoxNinePatch(compact), UiUtil.LEFT);
            var hlayout = new RoxFlowPane([ userAvatar, tmp ], new RoxNinePatch(layout), [ margin ]);
            addChild(hlayout.rox_move(0, h));
            h += hlayout.height;
        }

        if (mode == FULL) {
            var praisebtn = UiUtil.button(UiUtil.TOP_LEFT, status.praised ? "res/icon_praised.png" : "res/icon_praise.png",
                    "赞(" + status.praiseCount + ")", 0, fontsize + 2, "res/btn_grey.9.png", onButton);
            praisebtn.name = "praise_" + status.id;
            var commentbtn = UiUtil.button(UiUtil.TOP_LEFT, "res/icon_comment.png",
                    "评论(" + status.commentCount + ")", 0, fontsize + 2, "res/btn_grey.9.png", onButton);
            commentbtn.name = "comment_" + status.id;
//            var morebtn = UiUtil.button(UiUtil.TOP_LEFT, "res/icon_more.png",
//                    null, "res/btn_grey.9.png", onButton);
//            morebtn.name = "more_" + status.id;
            infoLabel = new RoxFlowPane([ praisebtn, commentbtn/*, morebtn*/ ], new RoxNinePatch(layout));
            addChild(infoLabel.rox_move(0, h));
            h += infoLabel.height;
        }

        GfxUtil.rox_fillRoundRect(graphics, 0xFFFFFFFF, 0, 0, width, h, 6);
        if (liney > 0) GfxUtil.rox_line(graphics, 2, 0xFFE6E6E6, 10, liney, width - 10, liney);
        if (appdata != null && appdata.width > 0 && appdata.height > 0 && appdata.image != null) {
            imgLdr = ResKeeper.get(appdata.image);
            if (imgLdr == null) {
                imgLdr = new RoxURLLoader(appdata.image, RoxURLLoader.IMAGE);
                ResKeeper.add(appdata.image, imgLdr);
            }
            if (imgLdr.status == RoxURLLoader.LOADING) {
                imgLdr.addEventListener(Event.COMPLETE, update);
            }
        }

        update(null);
    }

    private function onPlay(e) {
        this.dispatchEvent(new Event(Event.SELECT));
    }

    private function update(_) {
        if (imgLdr == null) return;
        var appdata = status.appData;
        var imw = w, imh = appdata.height * imageScale;
        if (placeholder != null && contains(placeholder)) removeChild(placeholder);
        switch (imgLdr.status) {
            case RoxURLLoader.OK:
                var bmd = new BitmapData(Std.int(imw), Std.int(imh), true, 0);
//                trace(">>>>>>>>>>>>>>>>>data="+imgLdr.data);
                bmd.draw(imgLdr.data, new Matrix(imageScale, 0, 0, imageScale, imageOffset, 0), true);
                var r = 6;
                if (mode == COMPACT) {
                    graphics.rox_drawRegionRound(bmd, 0, 0, imw, imh, r);
                } else {
                    graphics.beginBitmapFill(bmd, false, false);
                    graphics.moveTo(0, r);
                    graphics.curveTo(0, 0, r, 0);
                    graphics.lineTo(imw - r, 0);
                    graphics.curveTo(imw, 0, imw, r);
                    graphics.lineTo(imw, imh);
                    graphics.lineTo(0, imh);
                    graphics.lineTo(0, r);
                    graphics.endFill();
                }
                if (appdata.type != null && appdata.type != "" && appdata.type != AppData.IMAGE) {
                    playButton = UiUtil.button("res/btn_play.png", onPlay);
//                    trace("imw=" + imw + ",appdata.w="+appdata.width+",scale="+(imw/640));
                    playButton.rox_scale(imw / 640);
                    playButton.rox_move((imw - playButton.width) / 2, (imh - playButton.height) / 2);
                    addChild(playButton);
                }
//                trace("im="+imw+","+imh+",scale="+imageScale+",offset="+imageOffset);
            case RoxURLLoader.ERROR:
                placeholder = UiUtil.staticText("载入失败");
                addChild(placeholder.rox_move((imw - placeholder.width) / 2, (imh - placeholder.height) / 2));
            case RoxURLLoader.LOADING:
                placeholder = MyUtils.getLoadingAnim("");
                addChild(placeholder.rox_move(imw / 2, imh / 2));
        }
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
                            UiUtil.message(status.praised ? "赞 +1" : "赞已取消");
                        case 19:
                            UiUtil.message("已经赞过了");
//                            UiUtil.message
                        default:
                            UiUtil.message("网络错误，ex=" + data);
                    }
                });
            case "comment":
                parentScreen().startScreen(Type.getClassName(CommentsScreen), id);
            case "more":
        }

//#end
    }

    private inline function parentScreen() : RoxScreen {
        var screen: DisplayObjectContainer = this;
        do {
            screen = screen.parent;
        } while (screen != null && !Std.is(screen, RoxScreen));
        return cast screen;
    }

}
