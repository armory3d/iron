package wings.trait.camera;

import wings.Root;
import wings.math.Mat4;
import wings.math.Vec3;
import wings.math.Helper;

class PerspectiveCamera extends Camera {

	public function new(position:Vec3 = null) {

		projectionMatrix = Helper.perspective(45, Root.w / Root.h, 0.1, 10000);
		viewMatrix = new Mat4();
		worldMatrix = new Mat4();

		super(position);
	}
}
