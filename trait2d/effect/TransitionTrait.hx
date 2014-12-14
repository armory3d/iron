package fox.trait2d.effect;

import fox.core.Object;
import fox.core.Trait;
import fox.core.IRenderable2D;
import fox.Root;

class TransitionTrait extends Trait implements IRenderable2D {

    var scene:Class<Dynamic>;
    var args:Array<Dynamic>;
    var op:Float = 0;

    public function new(scene:Class<Dynamic>, args:Array<Dynamic> = null) {
        super();

        if (args == null) args = [];

        this.scene = scene;
        this.args = args;

        motion.Actuate.tween(this, 0.1, {op:1}).onComplete(onFade).ease(motion.easing.Linear.easeNone);
    }

    function onFade() {
        Root.reset();

        if (scene != null) Type.createInstance(scene, args);

        motion.Actuate.tween(this, 0.1, {op:0}).onComplete(onComplete).ease(motion.easing.Linear.easeNone);

        if (owner.parent != null) owner.remove();
        Root.addChild(owner);
    }

    function onComplete() {
        owner.remove();
    }

    public function render(g:kha.graphics2.Graphics) {

        var col = kha.Color.fromBytes(0, 0, 0, Std.int(op * 255));
        g.color = col;
        g.fillRect(0, 0, Root.w, Root.h);
    }
}
