package iron.node;

import kha.graphics4.Graphics;
import iron.math.Mat4;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Plane;
import iron.resource.CameraResource;
import iron.resource.WorldResource;

class CameraNode extends Node {

	public var resource:CameraResource;
	public var renderPath:RenderPath;
	
	public var world:WorldResource;

	public var P:Mat4; // Matrices
	public var V:Mat4;
	public var prevV:Mat4;
	public var VP:Mat4;
	public var frustumPlanes:Array<Plane> = null;
	public var nearPlane:Float;
	public var farPlane:Float;

	public function new(resource:CameraResource) {
		super();

		this.resource = resource;

		renderPath = new RenderPath(this);

		nearPlane = resource.resource.near_plane;
		farPlane = resource.resource.far_plane;

		if (resource.resource.type == "perspective") {
			P = Mat4.perspective(3.14159265 / 4, App.w / App.h, nearPlane, farPlane);
		}
		else if (resource.resource.type == "orthographic") {
			P = Mat4.orthogonal(-10, 10, -6, 6, -farPlane, farPlane, 2);
		}

		V = Mat4.identity();
		prevV = V;
		VP = Mat4.identity();

		if (resource.resource.frustum_culling) {
			frustumPlanes = [];
			for (i in 0...6) frustumPlanes.push(new Plane());
		}

		RootNode.cameras.push(this);
	}

	public override function remove() {
		RootNode.cameras.remove(this);
		super.remove();
	}

	public function renderFrame(g:Graphics, root:Node, lights:Array<LightNode>) {
		updateMatrix(); // TODO: only when dirty

		renderPath.renderFrame(g, root, lights);
		
		prevV = V.clone();
	}

	public function updateMatrix() {
		transform.buildMatrix();
		V.inverse2(transform.matrix);

		if (resource.resource.frustum_culling) {
			VP.multiply(V, P);
			buildViewFrustum(VP, frustumPlanes);
		}
	}

	public static function buildViewFrustum(VP:Mat4, frustumPlanes:Array<Plane>) {
	    // Left plane
	    frustumPlanes[0].setComponents(
	    	VP._03 + VP._00,
	    	VP._13 + VP._10,
	    	VP._23 + VP._20,
	    	VP._33 + VP._30
	    );
	 
	    // Right plane
	    frustumPlanes[1].setComponents(
	    	VP._03 - VP._00,
	    	VP._13 - VP._10,
	    	VP._23 - VP._20,
	    	VP._33 - VP._30
	    );
	 
	    // Top plane
	    frustumPlanes[2].setComponents(
	    	VP._03 - VP._01,
	    	VP._13 - VP._11,
	    	VP._23 - VP._21,
	    	VP._33 - VP._31
	    );
	 
	    // Bottom plane
	    frustumPlanes[3].setComponents(
	    	VP._03 + VP._01,
	    	VP._13 + VP._11,
	    	VP._23 + VP._21,
	    	VP._33 + VP._31
	    );
	 
	    // Near plane
	    frustumPlanes[4].setComponents(
	    	VP._02,
	    	VP._12,
	    	VP._22,
	    	VP._32
	    );
	    // frustumPlanes[4].setComponents(
	    // 	VP._03 + VP._02,
	    // 	VP._13 + VP._12,
	    // 	VP._23 + VP._22,
	    // 	VP._33 + VP._32
	    // );
	 
	    // Far plane
	    frustumPlanes[5].setComponents(
	    	VP._03 - VP._02,
	    	VP._13 - VP._12,
	    	VP._23 - VP._22,
	    	VP._33 - VP._32
	    );
	 
	    // Normalize planes
	    for (plane in frustumPlanes) plane.normalize();
	}

	static var sphere = new iron.math.Sphere();
	public static function sphereInFrustum(frustumPlanes:Array<Plane>, t:Transform):Bool {
		for (plane in frustumPlanes) {	
			sphere.set(t.pos, t.radius);
			// Outside the frustum
			if (plane.distanceToSphere(sphere) + t.radius * 2 < 0) {
				return false;
			}
	    }
	    return true;
	}

	public function rotate(axis:Vec4, f:Float) {
		var q = new Quat();
		q.setFromAxisAngle(axis, f);
		transform.rot.multiply(q, transform.rot);

		updateMatrix();
	}

	public function move(axis:Vec4, f:Float) {
        axis.mult(f, axis);

		transform.pos.vadd(axis, transform.pos);
		transform.dirty = true;
		transform.update();
		updateMatrix();
	}

	// public inline function right():Vec4 { return new Vec4(V._00, V._10, V._20); }
	// public inline function up():Vec4 { return new Vec4(V._01, V._11, V._21); }
	// public inline function look():Vec4 { return new Vec4(-V._02, -V._12, -V._22); }
	public inline function right():Vec4 { return new Vec4(transform.local._00, transform.local._01, transform.local._02); }
	public inline function up():Vec4 { return new Vec4(transform.local._10, transform.local._11, transform.local._12); }
    public inline function look():Vec4 { return new Vec4(-transform.local._20, -transform.local._21, -transform.local._22); }
}
