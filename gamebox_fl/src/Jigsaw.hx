import flambe.math.Point;
import flambe.display.PatternSprite;
import flambe.display.Sprite;
import flambe.math.Rectangle;
import flambe.display.Texture;
import flambe.System;
import flambe.Entity;

class Jigsaw extends Game {

    public var groups: Map<Int, TileGroup>;
    public var columns: Int;
    public var rows: Int;
    public var image: Texture;
    private var board: Entity;
    public var tiles: Texture;
    public var hold: Entity = null;
    public var holdPt: Point;

    public function new(data: Dynamic, image: Texture, tiles: Texture) {
        super();
        this.image = image;
        var sideLen = Std.int(Reflect.hasField(data, "size") ? image.width / data.size : data.sideLen);
        this.tiles = tiles;
        columns = Std.int(image.width / sideLen);
        rows = Std.int(image.height / sideLen);
        holdPt = new Point(0, 0);
    }

    override public function onAdded() {

        var w = System.stage.width, h = System.stage.height;
        var xscale: Float = w * 0.9 / image.width, yscale: Float = h * 0.9 / image.height;
        var sc: Float = Math.min(xscale, yscale);
        if (sc > 1) sc = 1;
        var offx = (w - image.width * sc) / 2, offy = (h - image.height * sc) / 2;

        var tileLen = Std.int(tiles.width / columns);
        var sideLen = Std.int(image.width * sc / columns);
        var maxLen = Std.int(tiles.width * sc / columns);
//        var maxLen = Math.min(w * 0.9, h * 0.9) / (image.width / sideLen);
//        if (maxLen > tileLen) maxLen = tileLen;
//        trace("sc="+sc+",xsc="+xscale+",ysc="+yscale+",w="+w+",h="+h+",offx="+offx+",offy="+offy+"tileL="+tileLen+",sideL="+sideLen+",maxL="+maxLen);
        var bg = new Entity();
        bg.add(new PatternSprite(Main.pack.getTexture("bg_play")));
        bg.get(PatternSprite).setSize(System.stage.width, System.stage.height);
        this.owner.addChild(bg);

        board = new Entity().add(new Sprite());

        groups = new Map();
        for (i in 0...rows) {
            for (j in 0...columns) {

                var tile = new RegionSprite(tiles, new Rectangle(tileLen * j, tileLen * i, tileLen, tileLen), maxLen, maxLen);
                tile.setAnchor(maxLen / 2, maxLen / 2);
                tile.setXY(w * 0.1 + Math.random() * w * 0.8, h * 0.1 + Math.random() * h * 0.65);
//                tile.setXY((maxLen + 5) * j, (maxLen + 5) * i);
                var data = new DataComponent();
                data.id = toId(j, i);
                data.colIndex = j;
                data.rowIndex = i;
                var t = new Entity().add(tile).add(data);

                board.addChild(t);
                var tg = new TileGroup();
                tg.set(toId(j, i), t);
                groups.set(toId(j, i), tg);
            }
        }

        this.owner.addChild(board);
        System.pointer.down.connect(function(event) {
            var tile = Sprite.hitTest(this.owner, event.viewX, event.viewY);
//            trace("tile=" + tile);
            if (tile != null && Std.is(tile, RegionSprite)) {
                hold = tile.owner;
                holdPt.x = event.viewX;
                holdPt.y = event.viewY;
                board.removeChild(hold);
                board.addChild(hold);
            }
        });
        System.pointer.up.connect(function(event) {
            if (hold == null) return;
            var mygroup = groups.get(hold.get(DataComponent).id);
//            trace("mygroup="+mygroup);
            for (t in mygroup.iterator()) {
                var tid: Int;
                var td = t.get(DataComponent);
//                trace("td=" + td);
                var neighbours: Array<Int> = [];
                if (td.rowIndex > 0 && !mygroup.exists(tid = toId(td.colIndex, td.rowIndex - 1))) neighbours.push(tid);
                if (td.rowIndex < rows - 1 && !mygroup.exists(tid = toId(td.colIndex, td.rowIndex + 1))) neighbours.push(tid);
                if (td.colIndex < columns - 1 && !mygroup.exists(tid = toId(td.colIndex + 1, td.rowIndex))) neighbours.push(tid);
                if (td.colIndex > 0 && !mygroup.exists(tid = toId(td.colIndex - 1, td.rowIndex))) neighbours.push(tid);
                for (nid in neighbours) {
                    var group: TileGroup = groups.get(nid);
                    var tt = group.get(nid), ttd = tt.get(DataComponent), tts = tt.get(Sprite);
                    var destx = t.get(Sprite).x._, desty = t.get(Sprite).y._;
                    if (ttd.id == td.id + 1) destx += sideLen;
                    if (ttd.id == td.id - 1) destx -= sideLen;
                    if (ttd.id == td.id + 0x10000) desty += sideLen;
                    if (ttd.id == td.id - 0x10000) desty -= sideLen;
//                    trace("ttd=" + ttd+"dest="+destx+","+desty+",tt="+tt.get(Sprite).x._+","+tt.get(Sprite).y._);
//                    trace("dist="+(new Point(destx, desty).distanceTo(tt.get(Sprite).x._, tt.get(Sprite).y._))+",v="+(sideLen*0.16));
                    if (new Point(destx, desty).distanceTo(tts.x._, tts.y._) < sideLen * 0.16) { // close enough, do stick
                        moveGroup(tt, destx - tts.x._, desty - tts.y._);
                        for (i in group.keys()) {
                            mygroup.set(i, group.get(i));
                            groups.set(i, mygroup);
                        }
                    }
                }
            }
            if (!victory && Lambda.count(mygroup) == columns * rows) setVictory();
            hold = null;
        });
        System.pointer.move.connect(function(event) {
            if (hold == null) return;
            moveGroup(hold, event.viewX - holdPt.x, event.viewY - holdPt.y);
            holdPt.x = event.viewX;
            holdPt.y = event.viewY;
        });

        super.onAdded();
    }

    private inline function moveGroup(tile: Entity, dx: Float, dy: Float) {
        for (t in groups.get(tile.get(DataComponent).id).iterator()) {
            t.get(Sprite).x._ += dx;
            t.get(Sprite).y._ += dy;
            board.removeChild(t);
            board.addChild(t);
        }
    }

    inline static public function toId(colIdx: Int, rowIdx: Int) : Int {
        return (rowIdx << 16) + colIdx;
    }

}

private typedef TileGroup = Map<Int, Entity>;
