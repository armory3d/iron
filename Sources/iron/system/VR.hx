package iron.system;

import iron.math.Mat4;

class VR {

	static var undistortionMatrix:Mat4 = null;

	public function new() {

	}

	public static function getUndistortionMatrix():Mat4 {
		if (undistortionMatrix == null) {
			undistortionMatrix = Mat4.identity();
		}
		
		return undistortionMatrix;
	}

	public static function getMaxRadiusSq():Float {
		return 0.0;
	}
}
