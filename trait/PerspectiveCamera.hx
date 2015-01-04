package fox.trait;

import fox.Root;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.math.Helper;

class PerspectiveCamera extends Camera {

	public function new() {

		if (Main.gameData.orient == 0) {
			projectionMatrix = Helper.perspective(45, Root.w / Root.h, 0.1, 1000);
		}
		else {
			projectionMatrix = Helper.perspective(45, Root.h / Root.w, 0.1, 1000);
		}
		viewMatrix = new Mat4();

		super();
	}
}
