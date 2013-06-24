package com.weiplus.client;

using com.roxstudio.i18n.I18n;
import nme.display.Sprite;
import com.weiplus.client.model.PageModel;
import nme.events.Event;
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
        title.addChild(UiUtil.staticText("精选".i18n(), 0xFFFFFF, titleFontSize * 1.2));
        super.onCreate();
    }

    override private function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;

        var param = { sinceId: 0, rows: 10 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get("/statuses/select", param, onComplete);
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

}
