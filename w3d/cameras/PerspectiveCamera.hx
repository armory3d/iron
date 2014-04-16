package wings.w3d.cameras;

import wings.wxd.Pos;
import wings.math.Mat4;
import wings.math.Vec3;
import wings.w3d.util.Helper;

class PerspectiveCamera extends Camera {

	public function new(position:Vec3 = null) {

		projectionMatrix = Helper.perspective(45, Pos.w / Pos.h, 0.5, 10000);
		viewMatrix = new Mat4();
		worldMatrix = new Mat4();

		super(position);
	}
}
