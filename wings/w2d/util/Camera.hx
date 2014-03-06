package wings.w2d.util;

import wings.wxd.Pos;

class Camera extends Item {

	var world:Object2D;
	var lookAt:Object2D;

	public function new(world:Object2D, lookAt:Object2D, rectW:Int = 0, rectH:Int = 0) {
		super();

		this.world = world;
		this.lookAt = lookAt;
	}

	public override function update() {
		world.x = x;
		world.y = y;

		lookAt.x = Pos.w / 2;
		lookAt.y = Pos.h / 2;
	}
}
