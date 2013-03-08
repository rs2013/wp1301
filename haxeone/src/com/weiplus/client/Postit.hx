package com.weiplus.client;

import nme.events.Event;
import nme.events.Event;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.game.GfxUtil;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.net.RoxURLLoader;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.RoxAsyncBitmap;
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

using com.roxstudio.haxe.ui.UiUtil;

class Postit extends Sprite {

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

    public function new(inStatus: Status, width: Float, fullMode: Bool = false) {
        super();
        status = inStatus;
        setWidth(width, fullMode);
    }

    public function setWidth(width: Float, fullMode: Bool = false) {
        this.rox_removeAll();
        this.graphics.clear();
        var margin = width * MARGIN_RATIO;
        var fontsize = width * FONT_SIZE_RATIO;
        if (fontsize < MIN_FONT_SIZE) fontsize = MIN_FONT_SIZE;
        var appdata = status.appData;
        var h = 0.0;
        if (appdata != null) {
            var imw = appdata.width;
            imageScale = imw > width ? width / imw : 1.0;
            imageOffset = imw > width ? 0 : (width - imw) / 2;
            h = appdata.height * imageScale + margin;
        } else {
            imageScale = 1;
            imageOffset = 0;
        }

        var bub = UiUtil.bitmap("res/icon_bubble.png");
        var layout = new RoxNinePatchData(new Rectangle(margin, 0, 20, 20), null, null, new Rectangle(0, 0, 20 + 2 * margin, 20 + margin));
        var text = UiUtil.staticText(status.text, 0, fontsize, true, width - bub.width - 4 - 2 * layout.contentGrid.x);
        imageLabel = new RoxFlowPane([ bub, text ], new RoxNinePatch(layout), UiUtil.TOP, [ 4 ]);
        addChild(imageLabel.rox_move(0, h));
        h += imageLabel.height;
        var liney = h;
        h += 2 + margin;
        var head = UiUtil.asyncBitmap(status.user.profileImage, 60, 60);
        var avbg = UiUtil.ninePatch("res/avatar_bg.9.png");
        userAvatar = new RoxFlowPane([ head ], avbg);
        userLabel = UiUtil.staticText(status.user.name, 0xFF0000, fontsize + 4);
        var clock = UiUtil.bitmap("res/icon_time.png");
        var time = UiUtil.staticText(timeStr(status.createdAt), 0, fontsize);
        var compact = new RoxNinePatchData(new Rectangle(0, 0, 20, 20));
        dateLabel = new RoxFlowPane([ clock, time ], new RoxNinePatch(compact));
        var tmp = new RoxFlowPane([ userLabel, dateLabel ], new RoxNinePatch(compact), UiUtil.LEFT);
        var hlayout = new RoxFlowPane([ userAvatar, tmp ], new RoxNinePatch(layout), [ margin ]);
        addChild(hlayout.rox_move(0, h));
        h += hlayout.height;
        if (fullMode) {
            var praisebtn = UiUtil.button(UiUtil.TOP_LEFT, null, "赞(" + status.praiseCount + ")", 0, fontsize + 2, "res/btn_common.9.png");
            var commentbtn = UiUtil.button(UiUtil.TOP_LEFT, null, "评论(" + status.commentCount + ")", 0, fontsize + 2, "res/btn_common.9.png");
            var morebtn = UiUtil.button(UiUtil.TOP_LEFT, null, " ... ", 0, fontsize + 2, "res/btn_common.9.png");
            infoLabel = new RoxFlowPane([ praisebtn, commentbtn, morebtn ], new RoxNinePatch(layout));
            addChild(infoLabel.rox_move(0, h));
            h += infoLabel.height;
        }
        GfxUtil.rox_fillRoundRect(graphics, 0xFFFFFFFF, 0, 0, width, h, 6);
        GfxUtil.rox_line(graphics, 2, 0xFFE6E6E6, 10, liney, width - 10, liney);
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

    private function timeStr(date: Date) : String {
        var now = Date.now().getTime() / 1000;
        var time = date.getTime() / 1000;
        var dt = now - time;
        if (dt <= 60) {
            return "刚刚";
        } else if (dt <= 3600) {
            return "" + Std.int(dt / 60) + "分钟前";
        } else if (dt <= 86400) {
            return "" + Std.int(dt / 3600) + "小时前";
        } else {
            return "" + (date.getMonth() + 1) + "-" + date.getDate() + " " + date.getHours() + ":" + date.getMinutes();
        }

    }

    private function onPlay(e) {
        this.dispatchEvent(new Event(Event.SELECT));
    }

    private function update(_) {
        if (imgLdr == null) return;
        var appdata = status.appData;
        var imw = width, imh = appdata.height * imageScale;
        if (placeholder != null && contains(placeholder)) removeChild(placeholder);
        switch (imgLdr.status) {
            case RoxURLLoader.OK:
                var bmd = new BitmapData(Std.int(imw), Std.int(imh), true, 0);
                trace(">>>>>>>>>>>>>>>>>data="+imgLdr.data);
                bmd.draw(imgLdr.data, new Matrix(imageScale, 0, 0, imageScale, imageOffset, 0), true);
                graphics.beginBitmapFill(bmd, false, false);
                var r = 6;
                graphics.moveTo(0, r);
                graphics.curveTo(0, 0, r, 0);
                graphics.lineTo(imw - r, 0);
                graphics.curveTo(imw, 0, imw, r);
                graphics.lineTo(imw, imh);
                graphics.lineTo(0, imh);
                graphics.lineTo(0, r);
                graphics.endFill();
                if (appdata.type != null && appdata.type != "" && appdata.type != AppData.IMAGE) {
                    playButton = UiUtil.button("res/btn_play.png", onPlay);
                    playButton.rox_scale(imw / 640);
                    playButton.rox_anchor(UiUtil.CENTER).rox_move(imw / 2, imh / 2);
                    addChild(playButton);
                }
//                trace("im="+imw+","+imh+",scale="+imageScale+",offset="+imageOffset);
            case RoxURLLoader.ERROR:
                placeholder = UiUtil.staticText("载入失败");
                addChild(placeholder.rox_move((imw - placeholder.width) / 2, (imh - placeholder.height) / 2));
            case RoxURLLoader.LOADING:
                placeholder = UiUtil.staticText("载入中...");
                addChild(placeholder.rox_move((imw - placeholder.width) / 2, (imh - placeholder.height) / 2));
        }
    }

}
