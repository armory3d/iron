package fox.trait;

import fox.core.Trait;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.math.Quat;
import fox.math.Helper;
import fox.math.Plane;

class Camera extends Trait {

	public var transform:Transform;

	public var projectionMatrix:Mat4;
	public var viewMatrix:Mat4;
	public var viewProjectionMatrix:Mat4;

	public var up:Vec3;
	public var look:Vec3;
	public var right:Vec3;

	// Shadow map
	public var depthProjectionMatrix:Mat4;
	public var depthViewMatrix:Mat4;
	public var biasMat:Mat4;

	var frustumPlanes:Array<Plane> = [];

	function new() {
		super();

		if (Main.gameData.orient == 0) {
			up = new Vec3(0, 0, 1);
			look = new Vec3(0, 1, 0);
			right = new Vec3(1, 0, 0);
		}
		else {
			up = new Vec3(0, 0, 1);
			look = new Vec3(1, 0, 0);
			right = new Vec3(0, 1, 0);
		}

		// Shadow map
		// Compute the MVP matrix from the light's point of view
		//var m = new fox.math.Matrix4();
		//m.makeFrustum(-1, 1, -1, 1, 1, 4000);
		//depthProjectionMatrix = new Mat4(m.elements);
		//depthProjectionMatrix = Mat4.ortho(-30, 30, -30, 30, -30, 60);
		depthProjectionMatrix = Mat4.perspective(45, 1, 0.1, 1000);
		
		//depthViewMatrix = Mat4.lookAt(new Vec3(0, 0, 10), new Vec3(0, 0, 0), new Vec3(0, 0, 1));
	    depthViewMatrix = new Mat4([1,0,0,0,0,0.642787627309709,-0.766044428331382,0,0,0.766044428331382,0.642787627309709,0,0,0.053007244402691,-15.6204094130737,1]);

		biasMat = new Mat4([
			0.5, 0.0, 0.0, 0.0,
			0.0, 0.5, 0.0, 0.0,
			0.0, 0.0, 0.5, 0.0,
			0.5, 0.5, 0.5, 1.0
		]);

		viewProjectionMatrix = new Mat4();

		for (i in 0...6) {
			frustumPlanes.push(new Plane());
		}
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        // Invert
        invertRot(transform.rot);
        updateMatrix();
    }

    function invertRot(r:Quat) {
    	var v = new Vec3();
		r.toEuler(v);
		var q = new Quat();
		q.setFromEuler(-v.x, -v.y, -v.z);
	    r.x = q.x;
	    r.y = q.y;
	    r.z = q.z;
	    r.w = q.w;
    }

	public function updateMatrix() {
		var q = new Quat(); // Camera parent
		if (owner != null && owner.parent != null && owner.parent.transform != null) {
			q.x = owner.parent.transform.rot.x;
			q.y = owner.parent.transform.rot.y;
			q.z = owner.parent.transform.rot.z;
			q.w = owner.parent.transform.rot.w;
			q = q.inverse(q);
		}

		q.multiply(transform.rot, q); // Camera transform
	    
	    viewMatrix = q.toMatrix();

	    var trans = new Mat4();
	    //trans.translate(-transform.absx, -transform.absy, -transform.absz); // When parent is included
	    trans.translate(-transform.x, -transform.y, -transform.z);
	    viewMatrix.multiply(trans, viewMatrix);

	    buildViewFrustum();
	}

	function buildViewFrustum() {

		viewProjectionMatrix.identity();
    	viewProjectionMatrix.append(viewMatrix);
    	viewProjectionMatrix.append(projectionMatrix);

	    // Left plane
	    frustumPlanes[0].setComponents(
	    	viewProjectionMatrix._14 + viewProjectionMatrix._11,
	    	viewProjectionMatrix._24 + viewProjectionMatrix._21,
	    	viewProjectionMatrix._34 + viewProjectionMatrix._31,
	    	viewProjectionMatrix._44 + viewProjectionMatrix._41
	    );
	 
	    // Right plane
	    frustumPlanes[1].setComponents(
	    	viewProjectionMatrix._14 - viewProjectionMatrix._11,
	    	viewProjectionMatrix._24 - viewProjectionMatrix._21,
	    	viewProjectionMatrix._34 - viewProjectionMatrix._31,
	    	viewProjectionMatrix._44 - viewProjectionMatrix._41
	    );
	 
	    // Top plane
	    frustumPlanes[2].setComponents(
	    	viewProjectionMatrix._14 - viewProjectionMatrix._12,
	    	viewProjectionMatrix._24 - viewProjectionMatrix._22,
	    	viewProjectionMatrix._34 - viewProjectionMatrix._32,
	    	viewProjectionMatrix._44 - viewProjectionMatrix._42
	    );
	 
	    // Bottom plane
	    frustumPlanes[3].setComponents(
	    	viewProjectionMatrix._14 + viewProjectionMatrix._12,
	    	viewProjectionMatrix._24 + viewProjectionMatrix._22,
	    	viewProjectionMatrix._34 + viewProjectionMatrix._32,
	    	viewProjectionMatrix._44 + viewProjectionMatrix._42
	    );
	 
	    // Near plane
	    frustumPlanes[4].setComponents(
	    	viewProjectionMatrix._13,
	    	viewProjectionMatrix._23,
	    	viewProjectionMatrix._33,
	    	viewProjectionMatrix._43
	    );
	 
	    // Far plane
	    frustumPlanes[5].setComponents(
	    	viewProjectionMatrix._14 - viewProjectionMatrix._13,
	    	viewProjectionMatrix._24 - viewProjectionMatrix._23,
	    	viewProjectionMatrix._34 - viewProjectionMatrix._33,
	    	viewProjectionMatrix._44 - viewProjectionMatrix._43
	    );
	 
	    // Normalize planes
	    for (i in 0...6) {
	    	frustumPlanes[i].normalize();
	    }
	}

	public function sphereInFrustum(t:Transform, radius:Float):Bool {
		
		for (i in 0...6) {
			
			var vpos = new fox.math.Vec3(t.absx, t.absy, t.absz);
			//var pos = new fox.math.Vec3(t.absx, t.absy, t.absz);

			//var fn = frustumPlanes[i].normal;
			//var vn = new fox.math.Vec3(fn.x, fn.y, fn.z);

			//var dist = frustumPlanes[i].distanceToPoint(vpos);

			// Outside the frustum, reject it
			var sphere = new fox.math.Sphere(vpos, radius);
			if (frustumPlanes[i].distanceToSphere(sphere) + radius * 2 < 0) {
			//if (Helper.planeDotCoord(vn, pos, dist) + radius < 0) {
				return false;
			}
	    }

	    return true;
	}

	public function getLook():Vec3 {
	    var mRot:Mat4 = transform.rot.toMatrix();

	    return new Vec3(mRot._13, mRot._23, mRot._33);
	    //return new Vec3(mRot.matrix[2], mRot.matrix[6], mRot.matrix[10]);
	}

	public function getRight():Vec3 {
	    var mRot:Mat4 = transform.rot.toMatrix();

	    return new Vec3(mRot._11, mRot._21, mRot._31);
	    //return new Vec3(mRot.matrix[0], mRot.matrix[4], mRot.matrix[8]);
	}

	public function getUp():Vec3 {
	    var mRot:Mat4 = transform.rot.toMatrix();

	    return new Vec3(mRot._12, mRot._22, mRot._32);
	    //return new Vec3(mRot.matrix[1], mRot.matrix[5], mRot.matrix[9]);
	}

	public function pitch(f:Float) {

		var q = new Quat();
		q.setFromAxisAngle(right, -f);
		transform.rot.multiply(q, transform.rot);

		updateMatrix();
	}

	public function yaw(f:Float) {

		var q = new Quat();
		q.setFromAxisAngle(up, -f);
		transform.rot.multiply(q, transform.rot);

		updateMatrix();
	}

	public function roll(f:Float) {

		var q = new Quat();
		q.setFromAxisAngle(look, -f);
		transform.rot.multiply(q, transform.rot);

		updateMatrix();
	}

	public function moveForward(f:Float) {

		var v3Move = getLook();
        v3Move.mult(-f, v3Move);
        moveCamera(v3Move);
	}

	public function moveRight(f:Float) {

		var v3Move = getRight();
        v3Move.mult(-f, v3Move);
        moveCamera(v3Move);
	}

	public function moveUp(f:Float) {

		var v3Move = getUp();
        v3Move.mult(-f, v3Move);
        moveCamera(v3Move);
	}

	function moveCamera(vec:Vec3) {

		transform.pos.vadd(vec, transform.pos);
		transform.modified = true;
		updateMatrix();
	}

	public function viewMatrixForward():Vec3 {
        return new Vec3(-viewMatrix._13, -viewMatrix._23, -viewMatrix._33);
    }

    public function viewMatrixBackward():Vec3 {
        return new Vec3(viewMatrix._13, viewMatrix._23, viewMatrix._33);
    }
}
