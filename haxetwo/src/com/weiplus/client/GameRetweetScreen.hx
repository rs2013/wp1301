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

        var path = null;
#if cpp
        var tmppath = MyUtils.IMAGE_CACHE_DIR + "/" + StringTools.urlEncode(status.appData.image);
        trace("GameRetweetScreen: path=" + tmppath + ",exists=" + sys.FileSystem.exists(tmppath));
        if (sys.FileSystem.exists(tmppath)) path = tmppath;
#end
        MyUtils.asyncImage(status.appData.image, function(bmd: BitmapData) {
            var tags: Array<String> = [];
            startScreen(Type.getClassName(RetweetScreen), PARENT, {
                status: status,
                image: { bmd: bmd, path: path, tags: tags },
                data: { size: size, image: image }
            });
        });
    }

}
