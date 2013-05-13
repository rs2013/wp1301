package com.weiplus.apps.slidepuzzle;

import haxe.Json;
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
import nme.events.MouseEvent;
import nme.geom.Matrix;
import nme.geom.Point;

using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

/**
* Swap Puzzle App
**/
class App extends PlayScreen {

    public var map: Array<Array<Tile>>;
    public var columns: Int;
    public var rows: Int;
    public var shape: BitmapData;
    public var sideLen: Float;
    private var board: Sprite;
    private var boardw: Float;
    private var boardh: Float;
    private var preview: Sprite;

    override public function onStart(saved: Dynamic) {
        super.onStart(saved);
//        trace("slidepuzzle.onstart: \nsaved=" + saved + "\nstatus=" + status);
        if (status.makerData != null) {
            image = status.makerData.image;
            sideLen = Std.int(image.width / status.makerData.size);
        } else {
            var datastr: String = cast(getFileData("data.json"));
            var data: Dynamic = Json.parse(datastr);
            image = cast(getFileData(data.image));
            sideLen = Std.int(Reflect.hasField(data, "size") ? image.width / data.size : data.sideLen);
        }

        shape = ResKeeper.getAssetImage("res/shape184.png");
        columns = Std.int(image.width / sideLen);
        rows = Std.int(image.height / sideLen);

        boardw = columns * sideLen;
        boardh = rows * sideLen;
        var hscale = viewWidth / boardw;
        var vscale = viewHeight / boardh;
        board.scaleX = board.scaleY = hscale < vscale ? hscale : vscale;
        board.x = (viewWidth - boardw * board.scaleX) / 2;
        board.y = (viewHeight - boardh * board.scaleY) / 2;

        map = [];
        var set: Array<Int>;
        if (saved != null && saved.map != null) {
            set = saved.map;
        } else {
            set = [];
            for (i in 0...(columns * rows - 1)) {
                set.push(i);
            }
            set.push(-1);
            shuffle(set, columns, rows);
        }
        for (i in 0...rows) {
            map[i] = [];
            for (j in 0...columns) {
                var idx = set[i * columns + j];
                if (idx == -1) continue;
                var t = new Tile(this, idx % columns, Std.int(idx / columns));

                t.rox_move(sideLen / 2 + j * sideLen, sideLen / 2 + i * sideLen);
                var agent = new RoxGestureAgent(t, RoxGestureAgent.GESTURE);
                agent.swipeTimeout = 0;
                t.addEventListener(RoxGestureEvent.GESTURE_TAP, onTouch);
                board.addChild(t);
                map[i][j] = t;
            }
        }
        var btnView = UiUtil.button(UiUtil.TOP_LEFT, null, "预览", 0xFFFFFF, buttonFontSize, "res/btn_dark.9.png", onView);
        addTitleButton(btnView, UiUtil.RIGHT);
    }

    private function onView(_) {
        if (preview == null) {
            var scale: Float = GameUtil.min(viewWidth / image.width, viewHeight / image.height);
            var imgw = image.width * scale, imgh = image.height * scale;
            preview = new Sprite();
            var bmd = ResKeeper.getAssetImage("res/bg_play.jpg");
            var scalex = viewWidth / bmd.width, scaley = viewHeight / bmd.height;
            preview.graphics.rox_drawImage(bmd, new Matrix(scalex, 0, 0, scaley, 0, 0), false, true, 0, 0, viewWidth, viewHeight);
            preview.graphics.rox_drawRegion(image, (viewWidth - imgw) / 2, (viewHeight - imgh) / 2, imgw, imgh);
            preview.graphics.rox_fillRect(0x77FFFFFF, 0, 0, viewWidth, viewHeight);
            preview.addEventListener(MouseEvent.CLICK, onView);
        }
        if (content.contains(preview)) {
            content.removeChild(preview);
        } else {
            content.addChild(preview);
        }
    }


    override public function onSave(saved: Dynamic) {
        if (map != null && !victory) saved.map = map2set();
    }

    private function map2set() {
        var set: Array<Int> = [];
        for (i in 0...rows) {
            for (j in 0...columns) {
                var t = map[i][j];
                set.push(t != null ? t.rowIndex * columns + t.colIndex : -1);
            }
        }
        return set;
    }

    override public function createContent(height: Float) : Sprite {
        var content = super.createContent(height);
        board = new Sprite();
        content.addChild(board);
        return content;
    }

    private function onTouch(e: RoxGestureEvent) : Void {
        if (victory) return;
        var tile = cast(e.target, Tile);
        if (e.type == RoxGestureEvent.GESTURE_TAP) {
            var col = Std.int(tile.x / sideLen), row = Std.int(tile.y / sideLen);
            var ncol = col, nrow = row;
            if (col > 0 && map[row][col - 1] == null) {
                ncol -= 1;
            } else if (col < columns - 1 && map[row][col + 1] == null) {
                ncol += 1;
            } else if (row > 0 && map[row - 1][col] == null) {
                nrow -= 1;
            } else if (row < rows - 1 && map[row + 1][col] == null) {
                nrow += 1;
            }
            if (ncol == col && nrow == row) return;
            var nx = sideLen / 2 + ncol * sideLen, ny = sideLen / 2 + nrow * sideLen;
            Actuate.tween(tile, 0.5, { x: nx, y: ny });
            map[row][col] = null;
            map[nrow][ncol] = tile;
            var victory = true;
            for (idx in 0...rows * columns) {
                var c = idx % columns, r = Std.int(idx / columns), t = map[r][c];
                if ((t == null && (c != columns - 1 || r != rows - 1))
                        || (t != null && (t.colIndex != c || t.rowIndex != r))) {
                    victory = false;
                    break;
                }
            }
            if (victory) setVictory();
        }
    }

    public static function shuffle(a: Array<Int>, columns: Int, rows: Int) : Array<Int> {
        var idx = a.length - 1;
        for (i in 0...a.length * 3) { // just count, i is not used
            var y = Std.int(idx / columns), x = idx % columns;
            var dirs: Array<Int> = [];
            if (y > 0) dirs.push(1);
            if (x < columns - 1) dirs.push(2);
            if (y < rows - 1) dirs.push(3);
            if (x > 0) dirs.push(4);
            var d = dirs[Std.random(dirs.length)];
            switch (d) {
                case 1: { a[idx] = a[idx - columns]; idx -= columns; }
                case 2: { a[idx] = a[idx + 1]; idx++; }
                case 3: { a[idx] = a[idx + columns]; idx += columns; }
                case 4: { a[idx] = a[idx - 1]; idx--; }
            }
            a[idx] = -1;
        }
        return a;
    }

    static public function getTestData() : Dynamic {
        return {
            image: ResKeeper.getAssetImage("res/content1.jpg"),
            sideLen: 150 };
    }

}
