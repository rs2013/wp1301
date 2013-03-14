package com.weiplus.client;

import com.weiplus.client.TimelineScreen;
import com.roxstudio.haxe.ui.RoxFlowPane;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import nme.geom.Rectangle;
import com.roxstudio.haxe.ui.RoxNinePatch;
import nme.display.BitmapData;
import nme.display.Shape;
import nme.display.Sprite;
import com.weiplus.client.model.PageModel;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class UserScreen extends TimelineScreen {

    private var append: Bool;
    private var page: PageModel;
    private var refreshing: Bool = false;

    public function new() {
        super();
        this.screenTabIndex = 4;
    }

    override private function getHeadPanel() : Sprite {
        var shape = new Shape();
        shape.graphics.rox_fillRoundRect(0xFFEEEEEE, 0, 0, 32, 32);
        var bgbmd = new BitmapData(32, 32, true, 0);
        bgbmd.draw(shape);
        var spacing = screenWidth * TimelineScreen.SPACING_RATIO;
        var bg = new RoxNinePatch(new RoxNinePatchData(new Rectangle(6, 6, 20, 20), new Rectangle(12, 12, 8, 8), bgbmd));
        var panel = new RoxFlowPane(screenWidth - 2 * spacing, 100,
                [ UiUtil.bitmap("res/data/head11.png"), UiUtil.staticText("Leody", 0, 30) ], bg, [ 100 ]);
        var sp = new Sprite();
        sp.graphics.rox_fillRect(0x01FFFFFF, 0, 0, screenWidth, panel.height + spacing);
        var pshadow = UiUtil.ninePatch("res/shadow6.9.png");
        pshadow.setDimension(panel.width + 3, panel.height + 6);
        panel.rox_move(spacing, spacing);
        pshadow.rox_move(panel.x - 2, panel.y);
        sp.addChild(pshadow);
        sp.addChild(panel);
        return sp;
    }

    override private function refresh(append: Bool) {
        this.append = append && page != null;
        if (refreshing || append && page != null && page.page == page.totalPages) return;
        var nextPage = append && page != null ? UiUtil.rangeValue(page.page + 1, 1, page.totalPages) : 1;

#if android
        HpManager.getUserTimeline("", nextPage, 20, 0, this);
#else
        var ldr = new RoxURLLoader("http://s-56378.gotocdn.com/harryphoto/statuses/user_timeline/2.json?page=" +
        nextPage + "&rows=20&accessToken=bb019119a014cfe275e1d34f39dd5a9e&refreshToken=&format=json", RoxURLLoader.TEXT);
        trace("refreshUrl="+ldr.url);
        ldr.addEventListener(Event.COMPLETE, function(_) { onApiCallback(null, "ok", ldr.data); } );
        refreshing = true;
#end
    }

    private function onApiCallback(apiName: String, resultCode: String, jsonStr: String) {
//        jsonStr = StringTools.replace(jsonStr, "http://s-56378.gotocdn.com/", "http://s-56378.gotocdn.com:8080/");
        trace("onApiCallback: name="+apiName+",result="+resultCode);//+",text="+jsonStr);
        refreshing = false;
        if (resultCode != "ok") return;
        var pageInfo = Json.parse(jsonStr).statuses;
        if (page == null) page = new PageModel();
        page.page = pageInfo.page;
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;
        updateList(pageInfo.records, append);
    }

}
