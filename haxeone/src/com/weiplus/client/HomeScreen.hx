package com.weiplus.client;

import com.weiplus.client.model.PageModel;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class HomeScreen extends TimelineScreen {

    private var append: Bool;
    private var refreshing: Bool = false;

    public function new() {
        super();
        this.screenTabIndex = 0;
    }

    override public function onCreate() {
        hasBack = false;
        super.onCreate();
    }

    override private function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;

//#if android
//        HpManager.getHomeTimeline(nextPage, 20, 0, this);
//#else
        var param = { sinceId: 0, rows: 20 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get("/statuses/home_timeline/" + HpApi.instance.uid, param, onComplete);
//        var ldr = new RoxURLLoader("http://s-56378.gotocdn.com/harryphoto/statuses/home_timeline/" + uid + ".json?" +
//            "sinceId=0&rows=20&refreshToken=&format=json&" +
//            (this.append ? "maxId=" + Std.int(page.oldestId - 1) + "&" : "")  +
//            "accessToken=" + accessToken, RoxURLLoader.TEXT);
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
