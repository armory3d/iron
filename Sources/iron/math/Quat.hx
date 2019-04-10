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
	static var helpMat = Mat4.identity();
	static var xAxis = Vec4.xAxis();
	static var yAxis = Vec4.yAxis();

	inline public function new(x:FastFloat = 0.0, y:FastFloat = 0.0, z:FastFloat = 0.0, w:FastFloat = 1.0) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	inline public function set(x:FastFloat, y:FastFloat, z:FastFloat, w:FastFloat):Quat {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
		return this;
	}

	inline public function fromAxisAngle(axis:Vec4, angle:FastFloat):Quat {
		var s:FastFloat = Math.sin(angle * 0.5);
		x = axis.x * s;
		y = axis.y * s;
		z = axis.z * s;
		w = Math.cos(angle * 0.5);
		return normalize();
	}

	inline public function toAxisAngle(axis:Vec4):FastFloat {
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
	}

	inline public function fromMat(m:Mat4):Quat {
		helpMat.setFrom(m);
		helpMat.toRotation();
		return fromRotationMat(helpMat);
	}

	inline public function fromRotationMat(m:Mat4):Quat {
		// Assumes the upper 3x3 is a pure rotation matrix
		var m11 = m._00; var m12 = m._10; var m13 = m._20;
		var m21 = m._01; var m22 = m._11; var m23 = m._21;
		var m31 = m._02; var m32 = m._12; var m33 = m._22;
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

	/**
	 * Multiply this quaternion by another.
	 * @param	q The quaternion to multiply this one with.
	 * @return	This quaternion.
	 */
	inline public function mult(q:Quat):Quat {	
		return multquats(this, q);
	}

	/**
	 * Multiply two other quaternions and store the result in this one.
	 * @param	q1 The first operand.
	 * @param	q2 The second operand.
	 * @return	This quaternion.
	 */
	inline public function multquats(q1:Quat, q2:Quat):Quat {
		var q1x = q1.x; var q1y = q1.y; var q1z = q1.z; var q1w = q1.w;
		var q2x = q2.x; var q2y = q2.y; var q2z = q2.z; var q2w = q2.w;
		x = q1x * q2w + q1w * q2x + q1y * q2z - q1z * q2y;
		y = q1w * q2y - q1x * q2z + q1y * q2w + q1z * q2x;
		z = q1w * q2z + q1x * q2y - q1y * q2x + q1z * q2w;
		w = q1w * q2w - q1x * q2x - q1y * q2y - q1z * q2z;
		return this;
	}

	/**
	 * Scale this quaternion to have a magnitude of 1.
	 * @return	This quaternion.
	 */
	inline public function normalize():Quat {
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
		return this;
	}

	/**
	 * Copy the rotation of another quaternion to this one.
	 * @param	q A quaternion to copy.
	 * @return	This quaternion.
	 */
	inline public function setFrom(q:Quat):Quat {
		x = q.x;
		y = q.y;
		z = q.z;
		w = q.w;
		return this;
	}

	/**
	 * Convert this quaternion to a YZX Euler.
	 * @return	A new YZX Euler that represents the same rotation as this
	 * 			quaternion.
	 */
	inline public function getEuler():Vec4 {
		var a = -2 *(x * z - w * y);
		var b =  w * w + x * x - y * y - z * z;
		var c =  2 *(x * y + w * z);
		var d = -2 *(y * z - w * x);
		var e =  w * w - x * x + y * y - z * z;
		return new Vec4(Math.atan2(d, e), Math.atan2(a, b), Math.asin(c));
	}

	/**
	 * Set this quaternion to the rotation represented by a YZX Euler.
	 * @param	x The Euler's x component.
	 * @param	y The Euler's y component.
	 * @param	z The Euler's z component.
	 * @return	This quaternion.
	 */
	inline public function fromEuler(x:FastFloat, y:FastFloat, z:FastFloat):Quat {
		var f = x / 2;
		var c1 = Math.cos(f);
		var s1 = Math.sin(f);
		f = y / 2;
		var c2 = Math.cos(f);
		var s2 = Math.sin(f);
		f = z / 2;
		var c3 = Math.cos(f);
		var s3 = Math.sin(f);
		// YZX
		this.x = s1 * c2 * c3 + c1 * s2 * s3;
		this.y = c1 * s2 * c3 + s1 * c2 * s3;
		this.z = c1 * c2 * s3 - s1 * s2 * c3;
		this.w = c1 * c2 * c3 - s1 * s2 * s3;
		return this;
	}

	/**
	 * Linearly interpolate between two other quaterions, and store the
	 * result in this one. This is not a so-called slerp operation.
	 * @param	from The quaterion to interpolate from.
	 * @param	to The quaterion to interpolate to.
	 * @param	s The amount to interpolate, with 0 being `from` and 1 being
	 * 			`to`, and 0.5 being half way between the two.
	 * @return	This quaternion.
	 */
	public inline function lerp(from:Quat, to:Quat, s:FastFloat):Quat {
		var fromx = from.x;
		var fromy = from.y;
		var fromz = from.z;
		var fromw = from.w;
		var dot:FastFloat = from.dot(to);
		if (dot < 0.0) {
			fromx = -fromx;
			fromy = -fromy;
			fromz = -fromz;
			fromw = -fromw;
		}
		x = fromx + (to.x - fromx) * s;
		y = fromy + (to.y - fromy) * s;
		z = fromz + (to.z - fromz) * s;
		w = fromw + (to.w - fromw) * s;
		return normalize();
	}

	/**
	 * Find the dot product of this quaternion with another.
	 * @param	q The other quaternion.
	 * @return	The dot product.
	 */
	inline public function dot(q:Quat):FastFloat {
		return (x * q.x) + (y * q.y) + (z * q.z) + (w * q.w);
	}

	inline public function fromTo(v1:Vec4, v2:Vec4):Quat {
		// Rotation formed by direction vectors
		// v1 and v2 should be normalized first
		var a = helpVec0;
		var dot = v1.dot(v2);
		if (dot < -0.999999) {
			a.crossvecs(xAxis, v1);
			if (a.length() < 0.000001) a.crossvecs(yAxis, v1);
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
		return this;
	}

	public function toString():String {
		return this.x + ", " + this.y + ", " + this.z + ", " + this.w;
	}
}
