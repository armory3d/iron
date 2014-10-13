package fox.trait.camera;

import fox.Root;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.math.Helper;

class OrthoCamera extends Camera {

	public function new() {

		if (kha.Sys.screenRotation == kha.ScreenRotation.RotationNone) {
			//projectionMatrix = Helper.ortho();
		}
		else {
			//projectionMatrix = Helper.ortho();
		}
		viewMatrix = new Mat4();
		worldMatrix = new Mat4();

		super();
	}
}
