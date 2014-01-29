import flambe.animation.Ease;
import flambe.math.Rectangle;
import flambe.math.Point;
import flambe.display.PatternSprite;
import flambe.display.Sprite;
import flambe.math.Rectangle;
import flambe.display.Texture;
import flambe.System;
import flambe.Entity;

class SlidePuzzle extends Game {

    public var columns: Int;
    public var rows: Int;
    public var image: Texture;
    private var board: Entity;
    public var tiles: Texture;
    public var sideLen: Float;

    public function new(data: Dynamic, image: Texture, tiles: Texture) {
        super();
        this.image = image;
        var sideLen = Std.int(Reflect.hasField(data, "size") ? image.width / data.size : data.sideLen);
        this.tiles = tiles;
        columns = Std.int(image.width / sideLen);
        rows = Std.int(image.height / sideLen);
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
        for (i in 0...(columns * rows - 1)) {
            set.push(i);
        }
        set.push(-1);
        shuffle(set, columns, rows);
        for (i in 0...rows) {
            map[i] = [];
            for (j in 0...columns) {
                var idx = set[i * columns + j];
                if (idx == -1) continue;
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
        System.pointer.up.connect(function(event) {
            var tile = Sprite.hitTest(this.owner, event.viewX, event.viewY);
//            trace("tile=" + tile);
            if (tile == null || !Std.is(tile, RegionSprite)) return;

            var col = Std.int(tile.x._ / sideLen), row = Std.int(tile.y._ / sideLen);
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
            tile.x.animateTo(nx, 0.5, Ease.quadOut);
            tile.y.animateTo(ny, 0.5, Ease.quadOut);
            map[row][col] = null;
            map[nrow][ncol] = tile.owner;
            var victory = true;
            for (idx in 0...rows * columns) {
                var c = idx % columns, r = Std.int(idx / columns), t = map[r][c];
                if ((t == null && (c != columns - 1 || r != rows - 1))
                || (t != null && (t.get(DataComponent).colIndex != c || t.get(DataComponent).rowIndex != r))) {
                    victory = false;
                    break;
                }
            }
            if (victory) setVictory();
        });

        super.onAdded();
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

}
