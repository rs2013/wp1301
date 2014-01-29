import flambe.script.Parallel;
import flambe.script.CallFunction;
import flambe.script.Delay;
import flambe.display.ImageSprite;
import flambe.Entity;
import flambe.util.Random;
import flambe.animation.Ease;
import flambe.script.AnimateTo;
import flambe.script.Sequence;
import flambe.script.Script;
import flambe.display.FillSprite;
import flambe.display.PatternSprite;
import flambe.display.ImageSprite;
import flambe.display.Font;
import flambe.display.TextSprite;
import haxe.Timer;
import flambe.math.Point;
import flambe.display.PatternSprite;
import flambe.display.Sprite;
import flambe.math.Rectangle;
import flambe.display.Texture;
import flambe.System;
import flambe.Entity;
import flambe.Component;

class Game extends Component {

    public static var PId2 = Math.PI / 2;
    public static var PI = Math.PI;
    public static var PI3d2 = Math.PI * 3 / 2;
    public static var PIm2 = Math.PI * 2;
    public static var R2D = 180 / Math.PI;
    public static var D2R = Math.PI / 180;

    private var victory: Bool = false;
    private var frontLayer: Entity;
    private var timer: Entity;

    public function new() {
        victory = false;
    }

    override public function onAdded() {
        frontLayer = new Entity().add(new Sprite());
        var clock = new Entity().add(new ImageSprite(Main.pack.getTexture("icon_time")).setXY(System.stage.width / 2 - 50, 5));
        frontLayer.addChild(clock);
        var font = new Font(Main.pack, "tinyfont");
        timer = new Entity().add(new TextSprite(font).setXY(System.stage.width / 2 - 25, 5)).add(new TimeDisplay());
        frontLayer.addChild(timer);
        this.owner.addChild(frontLayer);
    }

    public function setVictory() {
        if (victory) return;
        victory = true;
        timer.get(TimeDisplay).stop();

        var frontMask = new Entity().add(new FillSprite(0xFFFFFFFF, System.stage.width, System.stage.height));
        frontMask.get(Sprite).alpha._ = 0;
        var script = new Script();
        script.run(new Sequence([
            new AnimateTo(frontMask.get(Sprite).alpha, 0.7, 0.1, Ease.quadOut),
            new AnimateTo(frontMask.get(Sprite).alpha, 0, 0.1, Ease.quadIn)
        ]));
        frontMask.add(script);
        frontLayer.addChild(frontMask);

        var texTip = Main.pack.getTexture("bg_play_tip");
        var ps = new PatternSprite(texTip, System.stage.width, texTip.height);
        var tip = new Entity().add(ps);
        ps.y._ = -tip.get(Sprite).getNaturalHeight();
        ps.y.animateTo(0, 0.8, Ease.bounceOut);
        var ts: TextSprite = new TextSprite(new Font(Main.pack, "tinyfont"));
        var text = new Entity().add(ts);
        ts.text = "Congratulations!";
        ts.centerAnchor().setXY(System.stage.width / 2, 45).setScale(2.5 * System.stage.width / 600);
        tip.addChild(text);
        frontLayer.addChild(tip);

        var arr = [ Main.pack.getTexture("img_star"), Main.pack.getTexture("img_heart"), Main.pack.getTexture("img_flower") ];
        var wd2 = System.stage.width / 2, hd2 = System.stage.height / 2;
        var r = new Point(wd2, hd2).magnitude();
        var idx: Array<Float> = [];
        for (i in 0...20) idx.push(i * 18 * D2R);
        shuffle(idx);
        var interval = 0.03;
        for (i in 0...idx.length) {
            var sp = new ImageSprite(arr[Std.random(3)]).centerAnchor().setXY(wd2, hd2).setScale(0.2);
            sp.visible = false;
            sp.rotation._ = Std.random(360);
            var scr = new Script();
            var ent = new Entity().add(sp).add(scr);
            scr.run(new Sequence([
                new Delay(i * interval),
                new CallFunction(function() { sp.visible = true; }),
                new Parallel([
                    new AnimateTo(sp.x, wd2 + r * Math.cos(idx[i]), 1.5, Ease.quadOut),
                    new AnimateTo(sp.y, hd2 + r * Math.sin(idx[i]), 1.5, Ease.quadOut),
                    new AnimateTo(sp.scaleX, 1, 1.5, Ease.quadOut),
                    new AnimateTo(sp.scaleY, 1, 1.5, Ease.quadOut),
                    new AnimateTo(sp.alpha, 0, 1.5),
                    new AnimateTo(sp.rotation, 720, 1.5)
                ])
            ]));
           frontLayer.addChild(ent);
        }
    }

    public static function shuffle<T>(array: Array<T>) : Array<T> {
        var rand = new Random();
        var len = array.length;
        for (i in 0...len - 1) {
            var i1 = len - i - 1;
            var i2 = Std.int(rand.nextFloat() * (i1 + 1));
            var tmp: T = array[i1];
            array[i1] = array[i2];
            array[i2] = tmp;
        }
        return array;
    }

}

private class TimeDisplay extends Component {

    private var stopTime: Float;
    private var elapsedTime: Float = 0;

    private static inline function timestr(tm: Float) {
        var minutes = Std.int(tm / 60);
        var seconds = Std.int(tm % 60);
        return (minutes <= 10 ? "0" + minutes : "" + minutes) + ":" + (seconds <= 10 ? "0" + seconds : "" + seconds);
    }

    public function new() {
        elapsedTime = 0;
        stopTime = 0;
    }

    public function stop() {
        stopTime = elapsedTime;
    }

    override public function onUpdate(dt :Float) {
        if (stopTime > 0) return;
        elapsedTime += dt;
        owner.get(TextSprite).text = timestr(elapsedTime);
    }

}
