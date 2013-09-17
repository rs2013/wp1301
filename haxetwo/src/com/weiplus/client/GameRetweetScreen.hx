package com.weiplus.client;

import haxe.Json;
import flash.display.BitmapData;
import com.weiplus.client.PostScreen;
import com.weiplus.client.MyUtils;
using com.roxstudio.i18n.I18n;
import com.weiplus.client.PlayScreen;

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

        MyUtils.asyncImage(status.appData.image, function(bmd: BitmapData) {
            startScreen(Type.getClassName(RetweetScreen), PARENT, {
                status: status,
                image: { bmd: bmd, path: null },
                data: { size: size, image: image }
            });
        });
    }

}
