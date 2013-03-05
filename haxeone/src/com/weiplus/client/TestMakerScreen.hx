package com.weiplus.client;

import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Sprite;

using com.roxstudio.haxe.game.GfxUtil;

class TestMakerScreen extends MakerScreen {

    override public function createContent(height: Float) : Sprite {
        var content = super.createContent(height);
        trace("createContent");
        image = ResKeeper.getAssetImage("res/data/3.jpg");
        data.image1 = image;
        data.image2 = ResKeeper.getAssetImage("res/icon_jigsaw_maker.png");
        data.image3 = ResKeeper.getAssetImage("res/data/head4.png");
        data.number = 133.5;
        data.name = "测试图片";
        content.graphics.rox_drawImage(image, 0, 0, screenWidth, height);
        return content;
    }
}
