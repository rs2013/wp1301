package com.weiplus.client;

import com.roxstudio.haxe.ui.RoxScreen.FinishToScreen;
import haxe.Json;
import flash.display.BitmapData;
import com.weiplus.client.PostScreen;
import com.weiplus.client.MyUtils;
import com.weiplus.client.PlayScreen;

using com.roxstudio.i18n.I18n;

class GameRetweetScreen extends PlayScreen {

    public function new() {
        super();
        hasTitleBar = false;
        hasBack = false;
    }

    override public function onStart(saved: Dynamic) {
        super.onStart(saved);
        var datastr: String = cast(getFileData("data.json"));
        var data: Dynamic = Json.parse(datastr);
        image = cast(getFileData(data.image));
        var size = Reflect.hasField(data, "size") ? data.size : Std.int(image.width / data.sideLen);

        var path: String = null;
#if cpp
        if (MyUtils.localCacheExists(status.appData.image)) {
            path = MyUtils.localCachePath(status.appData.image);
        }
#end
        MyUtils.asyncImage(status.appData.image, function(bmd: BitmapData) {
            var tags: Array<String> = [];
            startScreen(Type.getClassName(RetweetScreen), FinishToScreen.PARENT, {
                status: status,
                image: { bmd: bmd, path: path, tags: tags },
                data: { size: size, image: image }
            });
        });
    }

}
