package iron.node;

import iron.math.Mat4;
import iron.math.Vec4;
import iron.resource.LightResource;
import iron.node.CameraNode.FrustumPlane;
import iron.Root;

class LightNode extends Node {

	public var resource:LightResource;

	// Shadow map matrices
	public var V:Mat4 = null;
	static var VP:Mat4 = null;

	public var frustumPlanes:Array<FrustumPlane> = null;

	public var farPlane:Float;

	public function new(resource:LightResource) {
		super();
		
		this.resource = resource;
		farPlane = resource.resource.far_plane;

		Root.lights.push(this);
	}

	public override function remove() {
		Root.lights.remove(this);
		super.remove();
	}

	public function buildMatrices(camera:CameraNode) {
		transform.buildMatrix();
		
		V = Mat4.identity();
		V.inverse2(transform.matrix);

		// Frustum culling enabled
		if (camera.resource.resource.frustum_culling) {
			if (frustumPlanes == null) {
				frustumPlanes = [];
				for (i in 0...6) frustumPlanes.push(new FrustumPlane());
				if (VP == null) VP = Mat4.identity();
			}

			VP.multiply(V, camera.P);
			CameraNode.buildViewFrustum(VP, frustumPlanes);
		}
	}

	public inline function right():Vec4 { return new Vec4(V._00, V._10, V._20); }
	public inline function up():Vec4 { return new Vec4(V._01, V._11, V._21); }
	public inline function look():Vec4 { return new Vec4(V._02, V._12, V._22); }
}
