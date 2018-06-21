package iron.math;

import kha.FastFloat;

class Quat {

	public var x:FastFloat;
	public var y:FastFloat;
	public var z:FastFloat;
	public var w:FastFloat;

	static var helpVec0 = new Vec4();
	static var helpVec1 = new Vec4();
	static var helpVec2 = new Vec4();

	public static function identity():Quat { return new Quat(0.0, 0.0, 0.0, 1.0); }

	// Basde on https://github.com/mrdoob/three.js/
	public function new(x = 0.0, y = 0.0, z = 0.0, w = 1.0) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	public inline function set(x:FastFloat, y:FastFloat, z:FastFloat, w:FastFloat) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	public function fromAxisAngle(axis:Vec4, angle:FastFloat) {
		var s:FastFloat = Math.sin(angle * 0.5);
		x = axis.x * s;
		y = axis.y * s;
		z = axis.z * s;
		w = Math.cos(angle * 0.5);
		normalize();
	}

	public function toAxisAngle(axis:Vec4):FastFloat {
		normalize();
		var angle = 2 * Math.acos(w);
		var s = Math.sqrt(1 - w * w);
		if (s < 0.001) {
			axis.x = this.x;
			axis.y = this.y;
			axis.z = this.z;
		}
		else {
			axis.x = this.x / s;
			axis.y = this.y / s;
			axis.z = this.z / s;
		}
		return angle;
	};

	public function fromRotationMat(m:Mat4) {
		// Assumes the upper 3x3 is a pure rotation matrix
		var m11 = m._00, m12 = m._10, m13 = m._20;
		var m21 = m._01, m22 = m._11, m23 = m._21;
		var m31 = m._02, m32 = m._12, m33 = m._22;

		var tr = m11 + m22 + m33;
		var s = 0.0;

		if (tr > 0) {
			s = 0.5 / Math.sqrt(tr + 1.0);
			this.w = 0.25 / s;
			this.x = (m32 - m23) * s;
			this.y = (m13 - m31) * s;
			this.z = (m21 - m12) * s;
		}
		else if (m11 > m22 && m11 > m33) {
			s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33);
			this.w = (m32 - m23) / s;
			this.x = 0.25 * s;
			this.y = (m12 + m21) / s;
			this.z = (m13 + m31) / s;
		}
		else if (m22 > m33) {
			s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33);
			this.w = (m13 - m31) / s;
			this.x = (m12 + m21) / s;
			this.y = 0.25 * s;
			this.z = (m23 + m32) / s;
		}
		else {
			s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22);
			this.w = (m21 - m12) / s;
			this.x = (m13 + m31) / s;
			this.y = (m23 + m32) / s;
			this.z = 0.25 * s;
		}
		return this;
	}

	public function mult(q:Quat) {
		multquats(this, q);
	}

	public function multquats(q1:Quat, q2:Quat) {
		var x2 = q1.x * q2.w + q1.w * q2.x + q1.y * q2.z - q1.z * q2.y;
		var y2 = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x;
		var z2 = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w;
		var w2 = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
		x = x2;
		y = y2;
		z = z2;
		w = w2;
	}

	public function normalize() {
		var l = Math.sqrt(x * x + y * y + z * z + w * w);
		if (l == 0.0) {
			x = 0;
			y = 0;
			z = 0;
			w = 0;
		}
		else {
			l = 1.0 / l;
			x *= l;
			y *= l;
			z *= l;
			w *= l;
		}
	}

	public function setFrom(q:Quat) {
		x = q.x;
		y = q.y;
		z = q.z;
		w = q.w;
	}

	public function getEuler():Vec4 {
		// YZX
		var roll = Math.NaN;
		var yaw = 0.0;
		var pitch = 0.0;

		var test = x * y + z * w;
		if (test > 0.499) { // Singularity at north pole
			roll = 2 * Math.atan2(x, w);
			yaw = Math.PI / 2;
			pitch = 0;
		}
		if (test < -0.499) { // Singularity at south pole
			roll = -2 * Math.atan2(x, w);
			yaw = -Math.PI / 2;
			pitch = 0;
		}
		if (Math.isNaN(roll)) {
			var sqx = x * x;
			var sqy = y * y;
			var sqz = z * z;
			roll = Math.atan2(2 * y * w - 2 * x * z , 1.0 - 2 * sqy - 2 * sqz);
			yaw = Math.asin(2 * test);
			pitch = Math.atan2(2 * x * w - 2 * y * z , 1.0 - 2 * sqx - 2 * sqz);
		}
		return new Vec4(pitch, roll, yaw);
	}

	public function getRotator():Rotator {
		var v = getEuler();
		return new Rotator(v.x, v.y, v.z);
	}

	public function fromEuler(x:FastFloat, y:FastFloat, z:FastFloat) {
		var c1 = Math.cos(x / 2);
		var c2 = Math.cos(y / 2);
		var c3 = Math.cos(z / 2);
		var s1 = Math.sin(x / 2);
		var s2 = Math.sin(y / 2);
		var s3 = Math.sin(z / 2);
		// YZX
		this.x = s1 * c2 * c3 + c1 * s2 * s3;
		this.y = c1 * s2 * c3 + s1 * c2 * s3;
		this.z = c1 * c2 * s3 - s1 * s2 * c3;
		this.w = c1 * c2 * c3 - s1 * s2 * s3;
		return this;
	}

	public function toMat(m:Mat4):Mat4 {
		var x2 = x + x, y2 = y + y, z2 = z + z;
		var xx = x * x2, xy = x * y2, xz = x * z2;
		var yy = y * y2, yz = y * z2, zz = z * z2;
		var wx = w * x2, wy = w * y2, wz = w * z2;

		m._00 = 1 - (yy + zz);
		m._10 = xy - wz;
		m._20 = xz + wy;

		m._01 = xy + wz;
		m._11 = 1 - (xx + zz);
		m._21 = yz - wx;

		m._02 = xz - wy;
		m._12 = yz + wx;
		m._22 = 1 - (xx + yy);

		m._03 = 0; m._13 = 0; m._23 = 0;
		m._30 = 0; m._31 = 0; m._32 = 0; m._33 = 1;

		return m;
	}

	public static function lerp(q1:Quat, q2:Quat, ratio:FastFloat):Quat {
		var c = new Quat();
		var ca = new Quat();
		ca.setFrom(q1);
		var dot:FastFloat = q1.dot(q2);
		if (dot < 0.0) {
			ca.w = -ca.w;
			ca.x = -ca.x;
			ca.y = -ca.y;
			ca.z = -ca.z;
		}
		c.x = ca.x + (q2.x - ca.x) * ratio;
		c.y = ca.y + (q2.y - ca.y) * ratio;
		c.z = ca.z + (q2.z - ca.z) * ratio;
		c.w = ca.w + (q2.w - ca.w) * ratio;
		c.normalize();
		return c;
	}

	public static function slerp(q1:Quat, q2:Quat, v:FastFloat):Quat {
		// Based on https://github.com/HeapsIO/heaps/blob/master/h3d/Quat.hx
		var c = new Quat();
		var cosHalfTheta = q1.dot(q2);
		if (Math.abs(cosHalfTheta) >= 1) {
			c.x = q1.x;
			c.y = q1.y;
			c.z = q1.z;
			c.w = q1.w;
			return c;
		}
		var halfTheta = Math.acos(cosHalfTheta);
		var invSinHalfTheta = 1 / Math.sqrt(1 - cosHalfTheta * cosHalfTheta);
		if (Math.abs(invSinHalfTheta) > 1e3) {
			return Quat.lerp(q1, q2, 0.5);
		}
		var a = Math.sin((1 - v) * halfTheta) * invSinHalfTheta;
		var b = Math.sin(v * halfTheta) * invSinHalfTheta * (cosHalfTheta < 0 ? -1 : 1);
		c.x = q1.x * a + q2.x * b;
		c.y = q1.y * a + q2.y * b;
		c.z = q1.z * a + q2.z * b;
		c.w = q1.w * a + q2.w * b;
		return c;
	}

	public function dot(q:Quat):FastFloat {
		return (x * q.x) + (y * q.y) + (z * q.z) + (w * q.w);
	}

	public function fromTo(v1:Vec4, v2:Vec4) {
		// Rotation formed by direction vectors
		var a = helpVec0;
		var dot = v1.dot(v2);
		if (dot < -0.999999) {
			a.crossvecs(Vec4.xAxis(), v1);
			if (a.length() < 0.000001) a.crossvecs(Vec4.yAxis(), v1);
			a.normalize();
			fromAxisAngle(a, Math.PI);
		}
		else if (dot > 0.999999) {
			set(0, 0, 0, 1);
		}
		else {
			a.crossvecs(v1, v2);
			set(a.x, a.y, a.z, 1 + dot);
			normalize();
		}
	}

	public function toString():String {
		return this.x + ", " + this.y + ", " + this.z + ", " + this.w;
	}
}
