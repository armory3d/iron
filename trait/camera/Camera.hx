package wings.trait.camera;

import wings.core.Trait;
import wings.math.Mat4;
import wings.math.Vec3;
import wings.math.Quat;

class Camera extends Trait {

	public var transform:Transform;

	public var projectionMatrix:Mat4;
	public var viewMatrix:Mat4;

	var up:Vec3;
	var look:Vec3;
	var right:Vec3;

	function new() {
		super();

		if (kha.Sys.screenRotation == kha.ScreenRotation.RotationNone) {
			//up = new Vec3(0, 1, 0);
			//look = new Vec3(0, 0, 1);
			//right = new Vec3(1, 0, 0);
			up = new Vec3(0, 0, 1);
			look = new Vec3(0, 1, 0);
			right = new Vec3(1, 0, 0);
		}
		else {
			up = new Vec3(1, 0, 0);
			look = new Vec3(0, 0, 1);
			right = new Vec3(0, -1, 0);
		}
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;
        updateMatrix();
    }

	public function updateMatrix() {

		var q = new Quat(); // Camera parent
		if (parent != null && parent.parent != null && parent.parent.transform != null) {
			q.x = parent.parent.transform.rot.x;
			q.y = parent.parent.transform.rot.y;
			q.z = parent.parent.transform.rot.z;
			q.w = parent.parent.transform.rot.w;
		}
		q = q.inverse(q);

		q.multiply(transform.rot, q); // Camera transform

	    viewMatrix = q.toMatrix().toRotation();

	    var trans = new Mat4();
	    trans.translate(-transform.absx, -transform.absy, -transform.absz);
	    viewMatrix.multiply(trans, viewMatrix);
	}

	function getLook():Vec3 {
	    var mRot:Mat4 = transform.rot.toMatrix();

	    return new Vec3(mRot._13, mRot._23, mRot._33);
	    //return new Vec3(mRot.matrix[2], mRot.matrix[6], mRot.matrix[10]);
	}

	function getRight():Vec3 {
	    var mRot:Mat4 = transform.rot.toMatrix();

	    return new Vec3(mRot._11, mRot._21, mRot._31);
	    //return new Vec3(mRot.matrix[0], mRot.matrix[4], mRot.matrix[8]);
	}

	function getUp():Vec3 {
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
}
