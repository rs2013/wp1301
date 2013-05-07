package com.weiplus.client;

import com.roxstudio.haxe.ui.UiUtil;
import com.roxstudio.haxe.ui.RoxScreen;
import nme.geom.Point;
import com.roxstudio.haxe.ui.RoxAnimate;
import nme.geom.Rectangle;
import nme.display.Sprite;
import com.weiplus.client.model.PageModel;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class PublicScreen extends TimelineScreen {

    private var append: Bool;
    private var refreshing: Bool = false;
    private var btnLogin: Sprite;

    public function new() {
        super();
        this.screenTabIndex = 1;
    }

    override public function onCreate() {
        hasBack = false;
        super.onCreate();
        removeTitleButton(btnCol);
    }

    override private function buttonPanel() : Sprite {
        var btnpanel = new Sprite();
        var h = 100 * d2rScale;
        btnpanel.graphics.rox_fillRect(0xAA000000, 0, -h, screenWidth, h);
        var btnBg = UiUtil.bitmap("res/btn_login.png").rox_scale(d2rScale);
        btnpanel.addChild(btnBg.rox_move((screenWidth - btnBg.width) / 2, (h - btnBg.height * d2rScale) / 2 - h));
        btnLogin = UiUtil.button(UiUtil.TOP_LEFT, null, "登录哈利波图", 0xFFFFFF, 40 * d2rScale, null, doLogin);
        btnpanel.addChild(btnLogin.rox_move((screenWidth - btnLogin.width) / 2, (h - btnLogin.height) / 2  - h));
        return btnpanel;
    }

//    private function doLogin1(_) {
//        HaxeStub.startInputDialog(this);
//    }
//
//    private function onApiCallback(apiName: String, resultCode: String, str: String) {
//        trace("onApiCallback: name="+apiName+",result="+resultCode+",str="+str);
//    }

    private function doLogin(_) {
        var p = btnLogin.localToGlobal(new Point(0, 0));
        var fromRect = new Rectangle(p.x, p.y, btnLogin.width, btnLogin.height);
        startScreen(Type.getClassName(LoginScreen), new RoxAnimate(RoxAnimate.ZOOM_IN, fromRect), 12345);
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
//        ldr.addEventListener(Event.COMPLETE, onComplete);
        refreshing = true;
//#end
    }

    private function onComplete(code: Int, data: Dynamic) {
//#if android
//        sys.io.File.saveContent("/sdcard/.harryphoto/publicscreen.json", jsonStr);
//#end
        refreshing = false;
        if (code != 200) return;
        var pageInfo = data.statuses;
        if (page == null) page = new PageModel();
        page.rows = pageInfo.rows;
        page.totalPages = pageInfo.totalPages;
        page.totalRows = pageInfo.totalRows;
        updateList(pageInfo.records, append);
    }

    override public function onScreenResult(requestCode: Int, resultCode: Int, resultData: Dynamic) {
        trace("publicscreen.onScreenResult:request=" + requestCode + ",result=" + resultCode + ",data=" + resultData);
        if (requestCode == 12345 && resultCode == RoxScreen.OK) {
            UiUtil.delay(function() { startScreen(Type.getClassName(HomeScreen), PARENT); });
        }
    }

}
