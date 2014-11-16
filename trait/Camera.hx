package fox.trait;

import fox.core.Trait;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.math.Quat;
import fox.math.Helper;

class Camera extends Trait {

	public var transform:Transform;

	public var projectionMatrix:Mat4;
	public var viewMatrix:Mat4;

	public var up:Vec3;
	public var look:Vec3;
	public var right:Vec3;

	// Shadowmap
	public var depthProjectionMatrix:Mat4;
	public var depthViewMatrix:Mat4;
	public var depthModelMatrix:Mat4;
	public var biasMat:Mat4;

	function new() {
		super();

		//if (kha.Sys.screenRotation == kha.ScreenRotation.RotationNone) {
		if (Main.gameData.orient == 0) {
		//if (Main.orient == 0) {
			up = new Vec3(0, 0, 1);
			look = new Vec3(0, 1, 0);
			right = new Vec3(1, 0, 0);
		}
		else {
			up = new Vec3(0, 0, 1);
			look = new Vec3(1, 0, 0);
			right = new Vec3(0, 1, 0);
		}

		// Shadowmap
		// Compute the MVP matrix from the light's point of view
		//var m = new fox.math.Matrix4();
		//m.makeFrustum(-1, 1, -1, 1, 1, 4000);
		//depthProjectionMatrix = new Mat4(m.elements);
		//depthProjectionMatrix = Helper.ortho(-30, 30, -30, 30, -30, 60);
		depthViewMatrix = Helper.lookAt(new Vec3(0, 5, 0), new Vec3(0, 0, 0), new Vec3(0, 0, 1));
		depthModelMatrix = new Mat4();

		biasMat = new Mat4([
			0.5, 0.0, 0.0, 0.0,
			0.0, 0.5, 0.0, 0.0,
			0.0, 0.0, 0.5, 0.0,
			0.5, 0.5, 0.5, 1.0
		]);
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
		if (parent != null && parent.parent != null && parent.parent.transform != null) {
			q.x = parent.parent.transform.rot.x;
			q.y = parent.parent.transform.rot.y;
			q.z = parent.parent.transform.rot.z;
			q.w = parent.parent.transform.rot.w;
			q = q.inverse(q);
		}

		q.multiply(transform.rot, q); // Camera transform
	    
	    viewMatrix = q.toMatrix();

	    var trans = new Mat4();
	    trans.translate(-transform.absx, -transform.absy, -transform.absz); // When parent is included
	    //trans.translate(-transform.x, -transform.y, -transform.z);
	    viewMatrix.multiply(trans, viewMatrix);
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
