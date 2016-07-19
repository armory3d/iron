package iron.node;

import iron.math.Mat4;
import iron.math.Vec4;
import iron.resource.LightResource;
import iron.math.Plane;

class LightNode extends Node {

	public var resource:LightResource;

	// Shadow map matrices
	public var V:Mat4 = null;
	static var VP:Mat4 = null;

	public var frustumPlanes:Array<Plane> = null;

	public function new(resource:LightResource) {
		super();
		
		this.resource = resource;

		RootNode.lights.push(this);
	}

	public override function removeChild(o:Node) {
		RootNode.lights.remove(cast o);
		super.removeChild(o);
	}

	public function buildMatrices(camera:CameraNode) {
		transform.buildMatrix();
		
		V = Mat4.identity();
		V.inverse2(transform.matrix);

		// Frustum culling enabled
		if (camera.resource.resource.frustum_culling) {
			if (frustumPlanes == null) {
				frustumPlanes = [];
				for (i in 0...6) frustumPlanes.push(new Plane());
				if (VP == null) VP = Mat4.identity();
			}

			VP.multiply(V, camera.P);
			CameraNode.buildViewFrustum(VP, frustumPlanes);
		}
	}
	
	public inline function look():Vec4 { return new Vec4(V._02, V._12, V._22); }
}
