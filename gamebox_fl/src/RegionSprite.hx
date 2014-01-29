import flambe.math.Rectangle;
import flambe.display.Graphics;
import flambe.display.Texture;
import flambe.display.Sprite;

class RegionSprite extends Sprite {
    public var texture: Texture;
    public var region: Rectangle;
    private var _w: Float;
    private var _h: Float;

    public function new (texture: Texture, ?region: Rectangle, ?width: Float = 0, ?height: Float = 0) {
        super();
        this.texture = texture;
        this.region = region == null ? new Rectangle(0, 0, texture.width, texture.height) : region;
        if (width <= 0 && height <= 0) {
            this._w = region.width;
            this._h = region.height;
        } else if (width <= 0) {
            this._w = height * region.width / region.height;
            this._h = height;
        } else if (height <= 0) {
            this._w = width;
            this._h = width * region.height / region.width;
        } else {
            this._w = width;
            this._h = height;
        }
//        trace("tex="+texture.width+","+texture.height+",rect="+region+",wh="+_w+","+_h);
    }

    override public function draw(g : Graphics) {
        g.save();
        g.scale(_w / region.width, _h / region.height);
        g.drawSubImage(texture, 0, 0, region.x, region.y, region.width, region.height);
        g.restore();
    }

    override public function getNaturalWidth(): Float {
        return _w;
    }

    override public function getNaturalHeight(): Float {
        return _h;
    }

}
