package fox.trait;

import fox.Root;
import fox.math.Mat4;

class PerspectiveCamera extends Camera {

	public function new() {

		if (Main.gameData.orient == 0) {
			P = Mat4.perspective(45, Root.w / Root.h, 0.1, 1000);
		}
		else {
			P = Mat4.perspective(45, Root.h / Root.w, 0.1, 1000);
		}

		super();
	}
}
