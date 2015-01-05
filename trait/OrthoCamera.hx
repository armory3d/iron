package fox.trait;

import fox.math.Mat4;

class OrthoCamera extends Camera {

	public function new() {

		if (kha.Sys.screenRotation == kha.ScreenRotation.RotationNone) {
			//projectionMatrix = Mat4.ortho();
		}
		else {
			//projectionMatrix = Mat4.ortho();
		}

		viewMatrix = new Mat4();

		super();
	}
}
