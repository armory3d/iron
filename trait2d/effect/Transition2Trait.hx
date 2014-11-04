package fox.trait2d.effect;

import fox.core.Object;
import fox.core.Trait;
import fox.core.IRenderable2D;
import fox.Root;
import fox.trait.DaeScene;
import fox.sys.Assets;

class Transition2Trait extends Trait implements IRenderable2D {

    var target:String;
	var op:Float = 0;

    public function new(target:String) {
        super();

        this.target = target;

        motion.Actuate.tween(this, 0.1, {op:1}).onComplete(onFade).ease(motion.easing.Linear.easeNone);
    }

    function onFade() {
    	Root.reset();

    	var scene = new Object();
        Root.addChild(scene);
        scene.addTrait(new DaeScene(Assets.getString(target)));

        motion.Actuate.tween(this, 0.1, {op:0}).onComplete(onComplete).ease(motion.easing.Linear.easeNone);

        if (parent.parent != null) parent.remove();
        Root.addChild(parent);
    }

    function onComplete() {
    	parent.remove();
    }

    public function render(g:kha.graphics2.Graphics) {

    	var col = kha.Color.fromBytes(0, 0, 0, Std.int(op * 255));
    	g.color = col;
		g.fillRect(0, 0, Root.w, Root.h);
    }
}
