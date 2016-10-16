package iron.object;

import iron.math.Mat4;
import iron.math.Vec4;
import iron.data.LampData;
import iron.object.CameraObject.FrustumPlane;
import iron.Scene;

class LampObject extends Object {

	public var data:LampData;

	// Shadow map matrices
	public var V:Mat4 = null;
	static var VP:Mat4 = null;

	public var frustumPlanes:Array<FrustumPlane> = null;

	public function new(data:LampData) {
		super();
		
		this.data = data;

		Scene.active.lamps.push(this);
	}

	public override function remove() {
		Scene.active.lamps.remove(this);
		super.remove();
	}

	public function buildMatrices(camera:CameraObject) {
		transform.buildMatrix();
		
		V = Mat4.identity();
		V.getInverse(transform.matrix);

		// Frustum culling enabled
		if (camera.data.raw.frustum_culling) {
			if (frustumPlanes == null) {
				frustumPlanes = [];
				for (i in 0...6) frustumPlanes.push(new FrustumPlane());
				if (VP == null) VP = Mat4.identity();
			}

			VP.multmats(camera.P, V);
			CameraObject.buildViewFrustum(VP, frustumPlanes);
		}
	}

	public inline function right():Vec4 { return new Vec4(V._00, V._10, V._20); }
	public inline function up():Vec4 { return new Vec4(V._01, V._11, V._21); }
	public inline function look():Vec4 { return new Vec4(V._02, V._12, V._22); }
}
