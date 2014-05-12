package wings.w2d.physics;

import wings.w2d.Object2D;
import wings.wxd.event.UpdateEvent;
import wings.wxd.Time;
import nape.geom.Vec2;

class Space extends Object2D {

	public var space:nape.space.Space;

	public function new(gravityX:Float = 0, gravityY:Float = 600) {
		super();
		
		space = new nape.space.Space(new Vec2(gravityX, gravityY));

		addEvent(new UpdateEvent(onUpdate));
	}

	function onUpdate() {
		space.step(Time.delta / 1000);

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
