package fox.trait;

import fox.core.Trait;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.math.Quat;
import fox.math.Helper;
import fox.math.Plane;

class Camera extends Trait {

	public var transform:Transform;

	public var P:Mat4; // Matrices
	public var V:Mat4;
	public var VP:Mat4;

	public var up:Vec3;
	public var look:Vec3;
	public var right:Vec3;

	public var dP:Mat4; // Shadow map matrices
	public var dV:Mat4 = null;
	//public var biasMat:Mat4;

	var frustumPlanes:Array<Plane> = [];

	function new() {
		super();

		V = new Mat4();

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
		//dP = Mat4.orthogonal(-30, 30, -30, 30, 5, 30);
		dP = Mat4.perspective(45, 1, 5, 30);
		dV = Mat4.lookAt(new Vec3(0, -12, 10), new Vec3(0, 0, 0), new Vec3(0, 0, 1));

		/*biasMat = new Mat4([
			0.5, 0.0, 0.0, 0.0,
			0.0, 0.5, 0.0, 0.0,
			0.0, 0.0, 0.5, 0.0,
			0.5, 0.5, 0.5, 1.0
		]);*/

		VP = new Mat4();

		for (i in 0...6) {
			frustumPlanes.push(new Plane());
		}
	}

	public function registerLight(light:Light) {
		var t = light.transform;
		dV = Mat4.lookAt(new Vec3(t.pos.x, t.pos.y, t.pos.z), new Vec3(0, 0, 0), new Vec3(0, 0, 1));
	}

	@injectAdd
    function addTransform(trait:Transform) {
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
	    
	    V = q.toMatrix();

	    var trans = new Mat4();
	    //trans.translate(-transform.absx, -transform.absy, -transform.absz); // When parent is included
	    trans.translate(-transform.x, -transform.y, -transform.z);
	    V.multiply(trans, V);

	    buildViewFrustum();
	}

	function buildViewFrustum() {

		VP.identity();
    	VP.append(V);
    	VP.append(P);

	    // Left plane
	    frustumPlanes[0].setComponents(
	    	VP._14 + VP._11,
	    	VP._24 + VP._21,
	    	VP._34 + VP._31,
	    	VP._44 + VP._41
	    );
	 
	    // Right plane
	    frustumPlanes[1].setComponents(
	    	VP._14 - VP._11,
	    	VP._24 - VP._21,
	    	VP._34 - VP._31,
	    	VP._44 - VP._41
	    );
	 
	    // Top plane
	    frustumPlanes[2].setComponents(
	    	VP._14 - VP._12,
	    	VP._24 - VP._22,
	    	VP._34 - VP._32,
	    	VP._44 - VP._42
	    );
	 
	    // Bottom plane
	    frustumPlanes[3].setComponents(
	    	VP._14 + VP._12,
	    	VP._24 + VP._22,
	    	VP._34 + VP._32,
	    	VP._44 + VP._42
	    );
	 
	    // Near plane
	    frustumPlanes[4].setComponents(
	    	VP._13,
	    	VP._23,
	    	VP._33,
	    	VP._43
	    );
	 
	    // Far plane
	    frustumPlanes[5].setComponents(
	    	VP._14 - VP._13,
	    	VP._24 - VP._23,
	    	VP._34 - VP._33,
	    	VP._44 - VP._43
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
        return new Vec3(-V._13, -V._23, -V._33);
    }

    public function viewMatrixBackward():Vec3 {
        return new Vec3(V._13, V._23, V._33);
    }
}
