package iron.system;

import iron.math.Mat4;

#if arm_vr
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

	public static function initButton() {
		var vrImage:kha.Image = iron.Scene.active.embedded.get('vr.png');

		function vrDownListener(index:Int, x:Float, y:Float) {
			var vr = kha.vr.VrInterface.instance;
			if (vr == null || !vr.IsVrEnabled() || vr.IsPresenting()) return;
			var w:Float = iron.App.w();
			var h:Float = iron.App.h();
			if (x < w - 150 || y < h - 150) return;
			vr.onVRRequestPresent();
		}		

		function vrRender2D(g:kha.graphics2.Graphics) {
			var vr = kha.vr.VrInterface.instance;
			if (vr == null || !vr.IsVrEnabled() || vr.IsPresenting()) return;
			var w:Float = iron.App.w();
			var h:Float = iron.App.h();
			g.color = 0xffffffff;
			g.drawImage(vrImage, w - 150, h - 150);
		}

		kha.input.Mouse.get().notify(vrDownListener, null, null, null);
		iron.App.notifyOnRender2D(vrRender2D);

		var vr = kha.vr.VrInterface.instance; // Straight to VR (Oculus Carmel)
		if (vr != null && vr.IsVrEnabled()) {
			vr.onVRRequestPresent();
		}
	}
}
#end
