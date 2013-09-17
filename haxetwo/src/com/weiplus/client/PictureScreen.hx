package com.weiplus.client;

import com.roxstudio.haxe.ui.SxAdapter;
import com.weiplus.client.model.AppData;
import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.game.ResKeeper;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.ui.RoxFlowPane;
using com.roxstudio.haxe.ui.DipUtil;
import flash.display.DisplayObject;
import com.roxstudio.haxe.game.GfxUtil;
import com.weiplus.client.model.Status;
using com.roxstudio.i18n.I18n;
import com.roxstudio.haxe.io.FileUtil;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.BitmapData;

using com.roxstudio.haxe.ui.UiUtil;

class PictureScreen extends BaseScreen {

    public static inline var IMAGE_SAVE_DIR =
#if android
        "/sdcard/DCIM/HarryPhoto";
#else
        "DCIM";
#end

    private var status: Status;
    private var bitmapData: BitmapData;
    private var viewh: Float;

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("查看原图".i18n(), 0xFFFFFF, titleFontSize * 1.2));
        super.onCreate();
        var btnSave = UiUtil.button(UiUtil.TOP_LEFT, null, "保存".i18n(), 0xFFFFFF, titleFontSize, "res/btn_common.9.png", function(_) {
            var text1 = "保存成功".i18n();
            var text2 = "保存中".i18n();
#if cpp
            MyUtils.asyncOperation({}, function(_) {
                FileUtil.mkdirs(IMAGE_SAVE_DIR);
                var bytes = GameUtil.encodeJpeg(bitmapData);
                var name = "" + Std.int(Date.now().getTime() / 1000) + "_" + Std.random(10000) + ".jpg";
                sys.io.File.saveBytes(IMAGE_SAVE_DIR + "/" + name, bytes);
            }, function(_) {
                UiUtil.message(text1);
            }, text2);
#end
        });
        addTitleButton(btnSave, UiUtil.RIGHT);
    }

    override public function createContent(viewh: Float) : Sprite {
        this.viewh = viewh;
        return super.createContent(viewh);
    }

    override public function onNewRequest(data: Dynamic) {
        status = data.status;
        bitmapData = cast data.image;
        var sc: Float = Math.min(screenWidth / bitmapData.width, (screenHeight - titleBar.height) / bitmapData.height);
        var offx = (screenWidth - bitmapData.width * sc) / 2, offy = (screenHeight - titleBar.height - bitmapData.height * sc) / 2;
        var sp = new Sprite();
        sp.addChild(new Bitmap(bitmapData).rox_smooth());
        sp.rox_scale(sc).rox_move(offx, offy);
        var agent = new RoxGestureAgent(sp);
        sp.addEventListener(RoxGestureEvent.GESTURE_PAN, agent.getHandler());
        sp.addEventListener(RoxGestureEvent.GESTURE_PINCH, agent.getHandler());
        content.addChild(sp);
        if (!HpApi.instance.isDefault()) {
            content.addChild(bottomBar().rox_move(0, viewh - (89).dp()));
        }
    }

    private static inline var FONT_SIZE_RATIO = 32 / 600;
    private static inline var MIN_FONT_SIZE = 16.0;

    private function bottomBar() : Sprite {
        var fontsize = (28).dp();
        var arr: Array<DisplayObject> = [];
        var praisebtn = UiUtil.button(UiUtil.TOP_LEFT, status.praised ? "res/icon_praised.png" : "res/icon_praise.png",
        "赞".i18n(), 0, fontsize, "res/btn_grey.9.png", onButton);
        praisebtn.name = "praise_" + status.id;
        arr.push(praisebtn);
        var commentbtn = UiUtil.button(UiUtil.TOP_LEFT, "res/icon_comment.png",
        "评论".i18n(), 0, fontsize, "res/btn_grey.9.png", onButton);
        commentbtn.name = "comment_" + status.id;
        arr.push(commentbtn);
        var repostbtn = UiUtil.button(UiUtil.TOP_LEFT, null, "转发".i18n(), 0, fontsize, "res/btn_grey.9.png", onButton);
        repostbtn.name = "repost_" + status.id;
        arr.push(repostbtn);
        if (status.user.id == HpApi.instance.uid) {
            var deletebtn = UiUtil.button(UiUtil.TOP_LEFT, null,
            "删除".i18n(), 0, fontsize, "res/btn_grey.9.png", onButton);
            deletebtn.name = "delete_" + status.id;
            arr.push(deletebtn);
        }

        var layout = new RoxNinePatchData(new Rectangle(0, 0, (13).dp(), (89).dp()), SxAdapter.getBitmapWithArgs("res/bg_input_comment.png".dpScale()));
        var infoLabel = new RoxFlowPane(screenWidth, (89).dp(), arr, new RoxNinePatch(layout), [ (10).dp() ]);
        return infoLabel;
    }

    private function onButton(e: Dynamic) {
        var name: String = e.target.name;
        var idx = name.indexOf("_");
        var id = name.substr(idx + 1);
        name = name.substr(0, idx);

        switch (name) {
            case "praise":
                HpApi.instance.get("/statuses/praise/" + id, {}, function(code: Int, data: Dynamic) {
                    switch (code) {
                        case 200:
                            var stat = data.statuses[0];
                            status.praiseCount = stat.praiseCount;
                            status.praised = !status.praised;
//                            setWidth(w, mode);
                            UiUtil.message(status.praised ? "赞 +1".i18n() : "赞已取消".i18n());
                        case 19:
                            UiUtil.message("已经赞过了".i18n());
//                            UiUtil.message
                        default:
                            UiUtil.message("网络错误，ex=".i18n() + data);
                    }
                });
            case "comment":
                startScreen(Type.getClassName(CommentsScreen), id);
            case "delete":
                HpApi.instance.get("/statuses/delete/" + id, {}, function(code: Int, data: Dynamic) {
                    switch (code) {
                        case 200:
                            UiUtil.message("已删除".i18n());
                            finish(RoxScreen.OK);
                        default:
                            UiUtil.message("网络错误，ex=".i18n() + data);
                    }
                });
            case "repost":
                if (isGame()) {
                    startScreen(Type.getClassName(GameRetweetScreen), status);
                } else { // is image
                    MyUtils.asyncImage(status.appData.image, function(image: BitmapData) {
                        startScreen(Type.getClassName(RetweetScreen), {
                        status: status,
                        image: { bmd: image, path: null },
                        data: null
                        });
                    });
                }
        }

    }

    private inline function isGame() {
        var type = status.appData.type;
        return type != null && type != "" && type != AppData.IMAGE;
    }

}
