package com.weiplus.apps.jigsaw;

using com.roxstudio.i18n.I18n;
import com.roxstudio.haxe.ui.UiUtil;
import haxe.Json;
import flash.geom.Rectangle;
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
    private var board: Sprite;
    private var preview: Sprite;

    override public function onStart(saved: Dynamic) {
        super.onStart(saved);
//        trace("jigsaw.onstart: \nsaved=" + saved + "\nstatus=" + status);
        if (status.makerData != null) {
            image = status.makerData.image;
            sideLen = image.width / status.makerData.size;
        } else {
            var datastr: String = cast(getFileData("data.json"));
            var data: Dynamic = Json.parse(datastr);
            image = cast(getFileData(data.image));
            sideLen = Reflect.hasField(data, "size") ? image.width / data.size : data.sideLen;
        }

        shape = ResKeeper.getAssetImage("res/shape_new.png");
        shapeSideLen = 184;

        columns = Std.int(image.width / sideLen);
        rows = Std.int(image.height / sideLen);
        var xscale: Float = viewWidth / image.width, yscale: Float = viewHeight / image.height;
        var sc: Float = GameUtil.min(xscale, yscale);
        var origw = viewWidth / sc, origh = viewHeight / sc;

        groups = new IntHash<TileGroup>();
        var isNew = saved == null || saved.tiles == null;
        var savedTiles: IntHash<Array<Int>> = null;
        if (!isNew) {
            savedTiles = new IntHash<Array<Int>>();
            var all: Array<Array<Int>> = cast(saved.tiles);
            for (ti in all) {
                savedTiles.set(ti[0], ti);
            }
            var gg: Array<Array<Int>> = cast(saved.groups);
            for (g in gg) {
                var group = new TileGroup();
                for (i in g) {
                    groups.set(i, group);
                }
            }
        }
        var bottoms: Array<Int> = [];
        for (i in 0...rows) {
            var left = 1;
            for (j in 0...columns) {
                var top = i == 0 ? 1 : 3 - (bottoms[j] - 2);
                var bottom = i == rows - 1 ? 1 : Std.random(2) + 2;
                bottoms[j] = bottom;
                var right = j == columns - 1 ? 1 : Std.random(2) + 2;
                var sides: Array<Int>, x: Float, y: Float;
                if (isNew) {
                    sides = [ top, right, bottom, left ];
                    x = sideLen / 2 +  Math.random() * (origw - sideLen);
                    y = sideLen / 2 + Math.random() * (origh - sideLen);
                } else {
                    var st = savedTiles.get(Tile.toId(j, i));
                    sides = [ st[1], st[2], st[3], st[4] ];
                    x = st[5];
                    y = st[6];
                }
                var t = new Tile(this, j, i, sides, 0);

                t.rox_move(x, y);
                var agent = new RoxGestureAgent(t.hitarea, RoxGestureAgent.GESTURE_CAPTURE);
                agent.swipeTimeout = 0;
                t.hitarea.addEventListener(RoxGestureEvent.GESTURE_PAN, onTouch);
                t.hitarea.addEventListener(RoxGestureEvent.GESTURE_SWIPE, onTouch);
                board.addChild(t);
                if (isNew) {
                    var tg = new TileGroup();
                    tg.set(t.id, t);
                    groups.set(t.id, tg);
                } else {
                    groups.get(t.id).set(t.id, t);
                }
                left = 3 - (right - 2);
            }
        }
        board.rox_scale(sc);

        var btnView = UiUtil.button(UiUtil.TOP_LEFT, null, "预览".i18n(), 0xFFFFFF, 36, "res/btn_dark.9.png", onView);
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
        if (victory || groups == null) return;
        var all: Array<Array<Int>> = [];
        var gg: Array<Array<Int>> = [];
        var set = new IntHash<Int>();
        for (g in groups) {
            var aa: Array<Int> = [];
            gg.push(aa);
            for (t in g) {
                aa.push(t.id);
                if (set.exists(t.id)) continue;
                all.push([ t.id, t.sides[0], t.sides[1], t.sides[2], t.sides[3], Std.int(t.x), Std.int(t.y) ]);
                set.set(t.id, 1);
            }
        }
        saved.tiles = all;
        saved.groups = gg;
    }

    override public function createContent(height: Float) : Sprite {
        var content = super.createContent(height);
        board = new Sprite();
        board.graphics.rox_fillRect(0x01FFFFFF, -500, -500, 1000 + viewWidth, 1000 + designHeight * d2rScale);

        var agent = new RoxGestureAgent(board);
        board.addEventListener(RoxGestureEvent.GESTURE_PAN, agent.getHandler());
        board.addEventListener(RoxGestureEvent.GESTURE_PINCH, agent.getHandler());
        content.addChild(board);
        return content;
    }

    private function onTouch(e: RoxGestureEvent) : Void {
        var tile = cast(e.target.parent, Tile);
//        trace("tile="+tile);
        if (e.type == RoxGestureEvent.GESTURE_PAN) {
            //trace(">>released<<=" + tile);
            var lpt = RoxGestureAgent.localOffset(tile, e.extra);
            moveGroup(tile, lpt.x, lpt.y);
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
            if (!victory && Lambda.count(mygroup) == columns * rows) setVictory();
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