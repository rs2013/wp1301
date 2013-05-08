package com.weiplus.client;

import nme.display.Sprite;
import com.weiplus.client.model.PageModel;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class SelectedScreen extends TimelineScreen {

    private var append: Bool;
    private var refreshing: Bool = false;

    public function new() {
        super();
        this.disposeAtFinish = false;
        this.screenTabIndex = 1;
    }

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("精选", 0xFFFFFF, buttonFontSize * 1.2));
        super.onCreate();
    }

    override private function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;

//#if android
//        HpManager.getPublicTimeline(nextPage, 10, 0, this);
//#else
        var param = { sinceId: 0, rows: 20 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get("/statuses/public_timeline", param, onComplete);
//        var ldr = new RoxURLLoader("http://s-56378.gotocdn.com/harryphoto/statuses/public_timeline.json?" +
//            "sinceId=0&rows=20&refreshToken=&format=json&" +
//            (this.append ? "maxId=" + Std.int(page.oldestId - 1) + "&" : "")  +
//            "accessToken=", RoxURLLoader.TEXT);
//        trace("refreshUrl="+ldr.url);
//        ldr.addEventListener(Event.COMPLETE, onComplete);
        refreshing = true;
//#end
    }

    private function onComplete(code: Int, data: Dynamic) {
        refreshing = false;
        if (code != 200) return;
        var pageInfo = data.statuses;
        if (page == null) page = new PageModel();
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;
        updateList(pageInfo.records, append);
    }

}
