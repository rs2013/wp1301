package com.weiplus.client;

import com.weiplus.client.model.PageModel;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class SelectedScreen extends TimelineScreen {

    private var append: Bool;
    private var page: PageModel;
    private var refreshing: Bool = false;

    public function new() {
        super();
        this.screenTabIndex = 1;
    }

    override private function refresh(append: Bool) {
//        trace("HpManager.check=" + HpManager.check());
//        super.refresh(top);
//        if (HpManager.check()) {
//            startScreen(Type.getClassName(HomeScreen));
//            return;
//        }
        this.append = append && page != null;
        if (refreshing || append && page != null && page.page == page.totalPages) return;
        var nextPage = append && page != null ? UiUtil.rangeValue(page.page + 1, 1, page.totalPages) : 1;

#if android
        HpManager.getPublicTimeline(nextPage, 20, 0, this);
#else
        var ldr = new RoxURLLoader("http://s-56378.gotocdn.com:8080/harryphoto/statuses/public_timeline.json?page=" +
                nextPage + "&rows=20&accessToken=&refreshToken=&format=json", RoxURLLoader.TEXT);
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
