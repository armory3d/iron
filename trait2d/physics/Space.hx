package wings.trait2d.physics;

import wings.core.IUpdateable;
import wings.core.Trait;

class Space extends Trait implements IUpdateable {

	var space:nape.space.Space;

	public function new(gravityX:Float = 0, gravityY:Float = 600) {
		super();
		
		space = new nape.space.Space(new nape.geom.Vec2(gravityX, gravityY));
	}

	function update() {
		space.step(Time.delta);

		for (i in 0...space.bodies.length) {
		    var obj:nape.phys.Body = space.bodies.at(i);

		    obj.userData.item.x = obj.position.x;
			obj.userData.item.y = obj.position.y;
		}
	}

	public function addBody(body:Body) {
		space.bodies.add(body.body);
	}
}
