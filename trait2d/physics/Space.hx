package fox.trait2d.physics;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.sys.Time;

class Space extends Trait implements IUpdateable {

	public var space:nape.space.Space;

	public function new(gravityX:Float = 0, gravityY:Float = 500) {
		super();
		
		space = new nape.space.Space(new nape.geom.Vec2(gravityX, gravityY));
	}

	public function update() {
		if (Time.delta <= 0) return;
		
		space.step(Time.delta);

		for (i in 0...space.bodies.length) {
		    var obj:nape.phys.Body = space.bodies.at(i);

		    var t = obj.userData.item;
		    t.x = obj.position.x - t.w / 2;
			t.y = obj.position.y - t.h / 2;
			t.rotation.angle = obj.rotation;
		}
	}
}
