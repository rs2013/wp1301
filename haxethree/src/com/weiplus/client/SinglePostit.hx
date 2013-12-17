package com.weiplus.client;

using com.roxstudio.i18n.I18n;
import nme.display.Sprite;
import com.weiplus.client.model.PageModel;
import nme.events.Event;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class SinglePostit extends TimelineScreen {

    private var refreshing: Bool = false;

    var statusId: String;

    public function new() {
        super();
    }

    override public function onCreate() {
        title = new Sprite();
        title.addChild(UiUtil.staticText("查看贴子".i18n(), 0xFFFFFF, titleFontSize * 1.2));
        super.onCreate();
        addTitleButton(btnBack, UiUtil.LEFT);
        removeTitleButton(btnCol);
        UiUtil.rox_removeByName(this, "buttonPanel");
        viewh = screenHeight - titleBar.height;
        numCol = 1;
    }

    override public function onNewRequest(data: Dynamic) {
        statusId = cast data;
        refresh(false);
    }

    override public function refresh(append: Bool) {
        if (refreshing) return;

        refreshing = true;

        var param = { maxId: statusId, rows: 1 };
        HpApi.instance.get("/statuses/public_timeline", param, onComplete);
    }

    private function onComplete(code: Int, data: Dynamic) {
        if (code != 200) {
            UiUtil.rox_removeByName(this, MyUtils.LOADING_ANIM_NAME);
            UiUtil.message("发生错误: ".i18n() + "code=" + code + ",error=" + data);

            refreshing = false;
            return;
        }
        var pageInfo = data.statuses;
        if (page == null) page = new PageModel();
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;
        updateList(pageInfo.records, false);

        refreshing = false;
    }

}
