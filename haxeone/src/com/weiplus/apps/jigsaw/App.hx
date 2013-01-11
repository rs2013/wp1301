package com.weiplus.apps.jigsaw;

import flash.geom.Rectangle;
import com.roxstudio.haxe.game.GfxUtil;
import com.weiplus.client.PlayScreen;
import com.eclecticdesignstudio.motion.easing.Elastic;
import com.eclecticdesignstudio.motion.Actuate;
import com.roxstudio.haxe.ui.RoxScreen;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.ui.RoxApp;
import com.roxstudio.haxe.ui.RoxAnimate;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.geom.Point;

using com.roxstudio.haxe.ui.UiUtil;

/**
* Jigsaw App
**/
class App extends PlayScreen {

    public var groups: IntHash<TileGroup>;
    public var columns: Int;
    public var rows: Int;
    public var shape: BitmapData;
    public var shapeSideLen: Float;
    public var image: BitmapData;
    public var sideLen: Float;
    private var victory: Bool;
    private var board: Sprite;

    override public function onNewRequest(data: Dynamic) {
        if (data == null) data = getTestData();
        shape = ResKeeper.getAssetImage("res/shape_new.png");
        shapeSideLen = 184;
        image = data.image;
        sideLen = data.sideLen;

        columns = Std.int(image.width / sideLen);
        rows = Std.int(image.height / sideLen);
        victory = false;

        groups = new IntHash<TileGroup>();
        var top = 1, left: Int;
        for (i in 0...rows) {
            var bottom = i == rows - 1 ? 1 : Std.random(2) + 2;
            left = 1;
            for (j in 0...columns) {
                var right = j == columns - 1 ? 1 : Std.random(2) + 2;
                var t = new Tile(this, j, i, [ top, right, bottom, left ], 0);

                t.rox_move(sideLen / 2 +  Math.random() * (screenWidth - sideLen),
                        sideLen / 2 + Math.random() * (screenHeight - titleBar.height - sideLen));
                var agent = new RoxGestureAgent(t.hitarea, RoxGestureAgent.GESTURE_CAPTURE);
                agent.swipeTimeout = 0;
                t.hitarea.addEventListener(RoxGestureEvent.GESTURE_PAN, onTouch);
                t.hitarea.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onTouch);
                board.addChild(t);
                var tg = new TileGroup();
                tg.set(t.id, t);
                groups.set(t.id, tg);
                left = 3 - (right - 2);
            }
            top = 3 - (bottom - 2);
        }
    }

    override public function createContent(designHeight: Float) : Sprite {
        var content = new Sprite();
        board = new Sprite();
        GfxUtil.rox_fillRect(board.graphics, 0x01FFFFFF, -500, -500, 1000 + screenWidth, 1000 + designHeight * d2rScale);

        var agent = new RoxGestureAgent(board);
        board.addEventListener(RoxGestureEvent.GESTURE_PAN, agent.getHandler());
        board.addEventListener(RoxGestureEvent.GESTURE_PINCH, agent.getHandler());
        content.addChild(board);
        return content;
    }

    private function onTouch(e: RoxGestureEvent) : Void {
        var tile = cast(e.target.parent, Tile);
        if (e.type == RoxGestureEvent.GESTURE_PAN) {
            //trace(">>released<<=" + tile);
            moveGroup(tile, e.extra.x, e.extra.y);
        } else if (e.type == RoxGestureEvent.GESTURE_SWIPE) {
            var mygroup = groups.get(tile.id);
            for (t in mygroup.iterator()) {
                var tid: Int;
                var neighbours: Array<Int> = [];
                if (t.rowIndex > 0 && !mygroup.exists(tid = Tile.toId(t.colIndex, t.rowIndex - 1))) neighbours.push(tid);
                if (t.rowIndex < rows - 1 && !mygroup.exists(tid = Tile.toId(t.colIndex, t.rowIndex + 1))) neighbours.push(tid);
                if (t.colIndex < columns - 1 && !mygroup.exists(tid = Tile.toId(t.colIndex + 1, t.rowIndex))) neighbours.push(tid);
                if (t.colIndex > 0 && !mygroup.exists(tid = Tile.toId(t.colIndex - 1, t.rowIndex))) neighbours.push(tid);
                for (nid in neighbours) {
                    var group: TileGroup = groups.get(nid);
                    var tt = group.get(nid);
                    var destx = t.x, desty = t.y;
                    if (tt.id == t.id + 0x10000) destx += sideLen;
                    if (tt.id == t.id - 0x10000) destx -= sideLen;
                    if (tt.id == t.id + 1) desty += sideLen;
                    if (tt.id == t.id - 1) desty -= sideLen;
                    if (GameUtil.distanceFF(destx, desty, tt.x, tt.y) < sideLen * 0.16) { // close enough, do stick
                        moveGroup(tt, destx - tt.x, desty - tt.y);
                        for (i in group.keys()) {
                            mygroup.set(i, group.get(i));
                            groups.set(i, mygroup);
                        }
                    }
                }
            }
            if (!victory && Lambda.count(mygroup) == columns * rows) { // complete
                victory = true;
//                trace("--victory!!--");
                if (content.getChildByName("tipsbar") == null) {
                    var tip = UiUtil.bitmap("res/bg_play_tip.png").rox_move(0, -130).rox_scale(d2rScale);
                    content.addChild(tip);
                    Actuate.tween(tip, 1.0, { y: -10 }).ease(Elastic.easeOut);
                }
            }
        }
    }

    private inline function moveGroup(tile: Tile, dx: Float, dy: Float) {
        //trace("movegroup,tile=" + tileId + ",dx=" +dx + ",dy=" + dy + ",group=" + groups.get(tileId));
        for (t in groups.get(tile.id).iterator()) {
            t.rox_move(t.x + dx, t.y + dy);
            board.removeChild(t);
            board.addChild(t);
        }
    }

    static public function getTestData() : Dynamic {
        return {
            shape: ResKeeper.getAssetImage("res/shape.png"),
            image: ResKeeper.getAssetImage("res/content1.jpg"),
            shapeSideLen: 200,
            sideLen: 120 };
    }

}

private typedef TileGroup = IntHash<Tile>;