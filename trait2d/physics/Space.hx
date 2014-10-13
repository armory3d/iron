package wings.trait2d.physics;

import wings.core.IUpdateable;
import wings.core.Trait;

class Space extends Trait implements IUpdateable {

	public var space:nape.space.Space;

	public function new(gravityX:Float = 0, gravityY:Float = 2000) {
		super();
		
		space = new nape.space.Space(new nape.geom.Vec2(gravityX, gravityY));
	}

	public function update() {
		space.step(wings.sys.Time.delta);

		for (i in 0...space.bodies.length) {
		    var obj:nape.phys.Body = space.bodies.at(i);

		    var t = obj.userData.item;
		    t.x = obj.position.x - t.w / 2;
			t.y = obj.position.y - t.h / 2;
			t.rotation.angle = obj.rotation;
		}
	}
}
