import flambe.animation.Ease;
import flambe.math.Rectangle;
import flambe.math.Point;
import flambe.display.PatternSprite;
import flambe.display.Sprite;
import flambe.math.Rectangle;
import flambe.display.Texture;
import flambe.System;
import flambe.Entity;

class SwapPuzzle extends Game {

    public var columns: Int;
    public var rows: Int;
    public var image: Texture;
    private var board: Entity;
    public var tiles: Texture;
    public var sideLen: Float;
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
        sideLen = Std.int(image.width * sc / columns);
//        trace("sc="+sc+",xsc="+xscale+",ysc="+yscale+",w="+w+",h="+h+",offx="+offx+",offy="+offy+"tileL="+tileLen+",sideL="+sideLen+",maxL="+maxLen);
        var bg = new Entity();
        bg.add(new PatternSprite(Main.pack.getTexture("bg_play")));
        bg.get(PatternSprite).setSize(System.stage.width, System.stage.height);
        this.owner.addChild(bg);

        board = new Entity().add(new Sprite());
        board.get(Sprite).setXY(offx, offy);

        var map: Array<Array<Entity>> = [];
        var set: Array<Int> = [];
        for (i in 0...(columns * rows)) {
            set.push(i);
        }
        Game.shuffle(set);
        for (i in 0...rows) {
            map[i] = [];
            for (j in 0...columns) {
                var idx = set[i * columns + j];
                var data = new DataComponent();
                data.colIndex = idx % columns;
                data.rowIndex = Std.int(idx / columns);
                var tile = new RegionSprite(tiles, new Rectangle(tileLen * data.colIndex, tileLen * data.rowIndex, tileLen, tileLen), sideLen, sideLen);
                tile.centerAnchor();
                tile.setXY(sideLen / 2 + j * sideLen, sideLen / 2 + i * sideLen);
                var t = new Entity().add(tile).add(data);
                board.addChild(t);
                map[i][j] = t;
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
            var tile: Sprite = hold.get(Sprite);
            var ncol = Std.int(tile.x._ / sideLen), nrow = Std.int(tile.y._ / sideLen);
            var nx = sideLen / 2 + ncol * sideLen, ny = sideLen / 2 + nrow * sideLen;
            tile.x.animateTo(nx, 0.5, Ease.quadOut);
            tile.y.animateTo(ny, 0.5, Ease.quadOut);
            var t = map[nrow][ncol];
            var idx = 0;
            var ocol: Int = 0, orow: Int = 0;
            for (idx in 0...rows * columns) {
                if (map[orow = Std.int(idx / columns)][ocol = idx % columns].get(Sprite) == tile) break;
            }
            var ox = sideLen / 2 + ocol * sideLen, oy = sideLen / 2 + orow * sideLen;
            t.get(Sprite).x.animateTo(ox, 0.5, Ease.quadOut);
            t.get(Sprite).y.animateTo(oy, 0.5, Ease.quadOut);
            map[nrow][ncol] = hold;
            map[orow][ocol] = t;
            var victory = true;
            for (idx in 0...rows * columns) {
                var c = idx % columns, r = Std.int(idx / columns), t = map[r][c];
                if (t.get(DataComponent).colIndex != c || t.get(DataComponent).rowIndex != r) {
                    victory = false;
                    break;
                }
            }
            if (victory) setVictory();
            hold = null;
        });
        System.pointer.move.connect(function(event) {
            if (hold == null) return;
            hold.get(Sprite).x._ += event.viewX - holdPt.x;
            hold.get(Sprite).y._ += event.viewY - holdPt.y;
            holdPt.x = event.viewX;
            holdPt.y = event.viewY;
        });

        super.onAdded();
    }

}
