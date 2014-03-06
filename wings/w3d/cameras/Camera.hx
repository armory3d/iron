package wings.w3d.cameras;

import wings.wxd.Pos;
import wings.math.Mat4;
import wings.math.Vec3;
import wings.w3d.util.Helper;

class Camera {

	public var projectionMatrix:Mat4;
	public var viewMatrix:Mat4;
	public var worldMatrix:Mat4;
	
	public var pos:Vec3;

	public var up:Vec3;
	public var look:Vec3;
	public var right:Vec3;

	// TODO: store as quaternion
	public var _pitch:Float;
	public var _yaw:Float;
	public var _roll:Float;

	function new(position:Vec3 = null) {
		if (position == null) position = new Vec3();

		pos = position;

		up = new Vec3(0, 1, 0);
		look = new Vec3(0, 0, 1);
		right = new Vec3(1, 0, 0);

		_pitch = 0;
		_yaw = 0;
		_roll = 0;

		updateMatrix();
	}

	function updateMatrix() {
		var yawMatrix:Mat4 = new Mat4();
		yawMatrix.appendRotation(_yaw, up);

		look = yawMatrix.transformVector(look);
		right = yawMatrix.transformVector(right);


		var pitchMatrix:Mat4 = new Mat4();
		pitchMatrix.appendRotation(_pitch, right);

		look = pitchMatrix.transformVector(look);
		up = pitchMatrix.transformVector(up);


		var rollMatrix:Mat4 = new Mat4();
		rollMatrix.appendRotation(_roll, look);

		right = rollMatrix.transformVector(right);
		up = rollMatrix.transformVector(up);


		viewMatrix.load([right.x, up.x, look.x, 0,
						 right.y, up.y, look.y, 0,
						 right.z, up.z, look.z, 0,
						 -pos.dot(right),
						 -pos.dot(up),
						 -pos.dot(look), 1]);


		up.set(0, 1, 0);
		look.set(0, 0, 1);
		right.set(1, 0, 0);


		worldMatrix.identity();
		worldMatrix.appendRotation(_pitch, new Vec3(1,0,0));
		worldMatrix.appendRotation(_yaw, new Vec3(0,1,0));
		worldMatrix.appendRotation(_roll, new Vec3(0,0,1));
		worldMatrix.appendTranslation(pos.x, pos.y, pos.z);
	}

	public function pitch(f:Float) {
		_pitch += f;

		updateMatrix();
	}

	public function yaw(f:Float) {
		_yaw += f;

		updateMatrix();
	}

	public function roll(f:Float) {
		_roll += f;

		updateMatrix();
	}

	public function moveForward(f:Float) {
		incrementPos(new Vec3(0, 0, -f, 0));
	}

	public function moveRight(f:Float) {
		incrementPos(new Vec3(f, 0, 0, 0));
	}

	public function moveUp(f:Float) {
		incrementPos(new Vec3(0, f, 0, 0));
	}

	function incrementPos(vec:Vec3) {
		var result:Vec3 = viewMatrix.multiplyByVector(vec);
		pos.vadd(result, pos);
		
		updateMatrix();
	}
}
