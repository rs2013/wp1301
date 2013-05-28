package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxFlowPane;
import com.weiplus.client.model.PageModel;
import nme.events.Event;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class HomeScreen extends TimelineScreen {

    private var append: Bool;
    private var refreshing: Bool = false;
    private var btnPlaza: RoxFlowPane;
    private var btnHome: RoxFlowPane;
    private var timelineUrl: String;
    private var isPublic: Bool = false;

    public function new() {
        super();
        this.disposeAtFinish = false;
        this.screenTabIndex = 0;
        btnPlaza = UiUtil.button(UiUtil.TOP_LEFT, null, "广场", 0xFFFFFF, titleFontSize, "res/btn_common.9.png", doSwitch);
        btnHome = UiUtil.button(UiUtil.TOP_LEFT, null, "个人", 0xFFFFFF, titleFontSize, "res/btn_common.9.png", doSwitch);
    }

    override public function onCreate() {
        hasBack = false;
        super.onCreate();
        doSwitch(null);
    }

    override private function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;

        var param = { sinceId: 0, rows: 10 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get(timelineUrl, param, onComplete);
        refreshing = true;
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

    private function doSwitch(e: Dynamic) {
        isPublic = !isPublic;
        if (isPublic) {
            timelineUrl = "/statuses/public_timeline";
            removeTitleButton(btnPlaza);
            addTitleButton(btnHome, UiUtil.LEFT);
        } else {
            timelineUrl = "/statuses/home_timeline/" + HpApi.instance.uid;
            removeTitleButton(btnHome);
            addTitleButton(btnPlaza, UiUtil.LEFT);
        }
        page = null;
        if (e != null) refresh(false);
    }

}
