package wings.trait.camera;

import wings.Root;
import wings.math.Mat4;
import wings.math.Vec3;
import wings.math.Helper;

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
