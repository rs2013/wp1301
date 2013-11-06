package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import flash.display.Sprite;
using com.roxstudio.i18n.I18n;
import Reflect;
import nme.net.SharedObject;
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
    private var isPublic: Bool;
    private var so: SharedObject;

    public function new() {
        super();
        this.disposeAtFinish = false;
        this.screenTabIndex = 0;
        btnPlaza = UiUtil.button("res/icon_plaza.png", null, "res/btn_common.9.png", doSwitch);
        btnHome = UiUtil.button("res/icon_personal.png", null, "res/btn_common.9.png", doSwitch);
        so = SharedObject.getLocal("harryphoto.HomeScreen");
        isPublic = Reflect.hasField(so.data, "isPublic") ? so.data.isPublic : true;
    }

    override public function onCreate() {
        hasBack = false;
        title = new Sprite();
        title.addChild(UiUtil.staticText("哈利波图(Beta)".i18n(), 0xFFFFFF, titleFontSize * 1.2));
        super.onCreate();
        doSwitch(null);
        if (HpApi.instance.isDefault()) {
            UiUtil.delay(function() {
                startScreen(Type.getClassName(SelectedScreen), null);
            });
        }
    }

    override public function refresh(append: Bool) {
        if (refreshing) return;
        this.append = append && page != null;

        var param = { sinceId: 0, rows: 10 };
        if (this.append) untyped param.maxId = Std.int(page.oldestId - 1);
        HpApi.instance.get(timelineUrl, param, onComplete);
        refreshing = true;
    }

    private function onComplete(code: Int, data: Dynamic) {
        refreshing = false;
        if (code != 200) {
            UiUtil.rox_removeByName(this, MyUtils.LOADING_ANIM_NAME);
            UiUtil.message("发生错误: ".i18n() + "code=" + code + ",error=" + data);
            return;
        }
        var pageInfo = data.statuses;
        if (page == null) page = new PageModel();
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;
        updateList(pageInfo.records, append);
    }

    private function doSwitch(e: Dynamic) {
        if (refreshing) return;
        if (e != null) isPublic = !isPublic;
        so.data.isPublic = isPublic;
        so.flush();
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
