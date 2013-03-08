package com.weiplus.client;

import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import haxe.Json;

using com.roxstudio.haxe.ui.UiUtil;
using com.roxstudio.haxe.game.GfxUtil;

class SelectedScreen extends TimelineScreen {

    private var append: Bool;

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
        this.append = append;
//#if android
//        HpManager.getPublicTimeline(this);
//#else
        var ldr = new RoxURLLoader("http://s-56378.gotocdn.com:8080/harryphoto/statuses/public_timeline.json?page=1&rows=20&accessToken=&refreshToken=&format=json", RoxURLLoader.TEXT);
        ldr.addEventListener(Event.COMPLETE, function(_) { onApiCallback(null, "ok", ldr.data); } );
//#end
    }

    private function onApiCallback(apiName: String, resultCode: String, jsonStr: String) {
//        jsonStr = StringTools.replace(jsonStr, "http://s-56378.gotocdn.com/", "http://s-56378.gotocdn.com:8080/");
        trace("onApiCallback: name="+apiName+",result="+resultCode+",text="+jsonStr);
        if (resultCode == "ok") {
            updateList(jsonStr, append);
        }

    }

}
