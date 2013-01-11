package com.weiplus.apps.swappuzzle;

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
* Swap Puzzle App
**/
class App extends PlayScreen {

    public var map: Array<Array<Tile>>;
    public var columns: Int;
    public var rows: Int;
    public var shape: BitmapData;
    public var image: BitmapData;
    public var sideLen: Float;
    private var victory: Bool;
    private var board: Sprite;
    private var boardw: Float;
    private var boardh: Float;
    private var visibleHeight: Float;

    override public function onNewRequest(data: Dynamic) {
        if (data == null) data = getTestData();
        shape = ResKeeper.getAssetImage("res/shape184.png");
        image = data.image;
        sideLen = data.sideLen;

        columns = Std.int(image.width / sideLen);
        rows = Std.int(image.height / sideLen);
        victory = false;

        boardw = columns * sideLen;
        boardh = rows * sideLen;
        var hscale = screenWidth / boardw;
        var vscale = visibleHeight / boardh;
        board.scaleX = board.scaleY = hscale < vscale ? hscale : vscale;
        board.x = (screenWidth - boardw * board.scaleX) / 2;
        board.y = (visibleHeight - boardh * board.scaleY) / 2;

        var set: Array<Int> = [];
        for (i in 0...(columns * rows)) {
            set.push(i);
        }
        GameUtil.shuffle(set);
        map = [];
        for (i in 0...rows) {
            map[i] = [];
            for (j in 0...columns) {
                var idx = set[i * columns + j];
                var t = new Tile(this, idx % columns, Std.int(idx / columns));

                t.rox_move(sideLen / 2 + j * sideLen, sideLen / 2 + i * sideLen);
                var agent = new RoxGestureAgent(t, RoxGestureAgent.GESTURE);
                agent.swipeTimeout = 0;
                t.addEventListener(RoxGestureEvent.GESTURE_PAN, onTouch);
                t.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onTouch);
                board.addChild(t);
                map[i][j] = t;
            }
        }
    }

    override public function createContent(designHeight: Float) : Sprite {
        visibleHeight = designHeight * d2rScale;
        var content = new Sprite();
        board = new Sprite();
        content.addChild(board);
        return content;
    }

    private function onTouch(e: RoxGestureEvent) : Void {
        if (victory) return;
        var tile = cast(e.target, Tile);
        if (e.type == RoxGestureEvent.GESTURE_PAN) {
            //trace(">>released<<=" + tile);
            board.swapChildren(tile, board.getChildAt(board.numChildren - 1));
            var nx = UiUtil.rangeValue(e.extra.x + tile.x, sideLen / 2, boardw - sideLen / 2);
            var ny = UiUtil.rangeValue(e.extra.y + tile.y, sideLen / 2, boardh - sideLen / 2);
            tile.rox_move(nx, ny);
        } else if (e.type == RoxGestureEvent.GESTURE_SWIPE) {
            var ncol = Std.int(tile.x / sideLen), nrow = Std.int(tile.y / sideLen);
            var nx = sideLen / 2 + ncol * sideLen, ny = sideLen / 2 + nrow * sideLen;
            Actuate.tween(tile, 0.5, { x: nx, y: ny });
            var t = map[nrow][ncol];
            var idx = 0;
            var ocol: Int = 0, orow: Int = 0;
            for (idx in 0...rows * columns) {
                if (map[orow = Std.int(idx / columns)][ocol = idx % columns] == tile) break;
            }
            var ox = sideLen / 2 + ocol * sideLen, oy = sideLen / 2 + orow * sideLen;
            Actuate.tween(t, 0.5, { x: ox, y: oy });
            map[nrow][ncol] = tile;
            map[orow][ocol] = t;
            victory = true;
            for (idx in 0...rows * columns) {
                var c = idx % columns, r = Std.int(idx / columns), t = map[r][c];
                if (t.colIndex != c || t.rowIndex != r) {
                    victory = false;
                    break;
                }
            }
            if (victory) {
//                trace("--victory!!--");
                var tip = UiUtil.bitmap("res/bg_play_tip.png").rox_move(0, -130).rox_scale(d2rScale);
                content.addChild(tip);
                Actuate.tween(tip, 1.0, { y: -10 }).ease(Elastic.easeOut);
            }
        }
    }

    static public function getTestData() : Dynamic {
        return {
            image: ResKeeper.getAssetImage("res/content1.jpg"),
            sideLen: 150 };
    }

}
