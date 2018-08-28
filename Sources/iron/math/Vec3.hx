package iron.math;

import kha.FastFloat;

class Vec3 {
	public var x:FastFloat;
	public var y:FastFloat;
	public var z:FastFloat;

	inline public function new(x:FastFloat = 0.0, y:FastFloat = 0.0, z:FastFloat = 0.0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	inline public function cross(v:Vec3):Vec3 {
		var ax = x; var ay = y; var az = z;
		var vx = v.x; var vy = v.y; var vz = v.z;
		x = ay * vz - az * vy;
		y = az * vx - ax * vz;
		z = ax * vy - ay * vx;
		return this;
	}

	inline public function crossvecs(a:Vec3, b:Vec3):Vec3 {
		var ax = a.x; var ay = a.y; var az = a.z;
		var bx = b.x; var by = b.y; var bz = b.z;
		x = ay * bz - az * by;
		y = az * bx - ax * bz;
		z = ax * by - ay * bx;
		return this;
	}

	inline public function set(x:FastFloat, y:FastFloat, z:FastFloat):Vec3{
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	inline public function add(v:Vec3):Vec3 {
		x += v.x;
		y += v.y;
		z += v.z;
		return this;
	}

	inline public function addf(x:FastFloat, y:FastFloat, z:FastFloat):Vec3 {
		this.x += x;
		this.y += y;
		this.z += z;
		return this;
	}

	inline public function addvecs(a:Vec3, b:Vec3):Vec3 {
		x = a.x + b.x;
		y = a.y + b.y;
		z = a.z + b.z;
		return this;
	} 

	inline public function subvecs(a:Vec3, b:Vec3):Vec3 {
		x = a.x - b.x;
		y = a.y - b.y;
		z = a.z - b.z;
		return this;
	}

	inline public function normalize():Vec3 {
		var n = length();
		if (n > 0.0) {
			var invN = 1.0 / n;
			this.x *= invN; this.y *= invN; this.z *= invN;
		}
		return this;
	}

	inline public function mult(f:FastFloat):Vec3 {
		x *= f;
		y *= f;
		z *= f;
		return this;
	}

	inline public function dot(v:Vec3):FastFloat {
		return x * v.x + y * v.y + z * v.z;
	}

	inline public function setFrom(v:Vec3):Vec3 {
		x = v.x;
		y = v.y;
		z = v.z;
		return this;
	}

	inline public function clone():Vec3 {
		return new Vec3(x, y, z);
	}

	inline public function lerp(from:Vec3, to:Vec3, s:FastFloat):Vec3 {
		x = from.x + (to.x - from.x) * s;
		y = from.y + (to.y - from.y) * s;
		z = from.z + (to.z - from.z) * s;
		return this;
	}

	inline public function applyproj(m:Mat4):Vec3 {
		var x = this.x; var y = this.y; var z = this.z;
		var d = 1.0 / (m._03 * x + m._13 * y + m._23 * z + m._33); // Perspective divide
		this.x = (m._00 * x + m._10 * y + m._20 * z + m._30) * d;
		this.y = (m._01 * x + m._11 * y + m._21 * z + m._31) * d;
		this.z = (m._02 * x + m._12 * y + m._22 * z + m._32) * d;
		return this;
	}

	inline public function applymat(m:Mat4):Vec3 {
		var x = this.x; var y = this.y; var z = this.z;
		this.x = m._00 * x + m._10 * y + m._20 * z + m._30;
		this.y = m._01 * x + m._11 * y + m._21 * z + m._31;
		this.z = m._02 * x + m._12 * y + m._22 * z + m._32;
		return this;
	}

	inline public function equals(v:Vec3):Bool {
		return x == v.x && y == v.y && z == v.z;
	}

	inline public function length():FastFloat {
		return Math.sqrt(x * x + y * y + z * z);
	}

	inline public function sub(v:Vec3):Vec3 {
		x -= v.x; y -= v.y; z -= v.z;
		return this;
	}

	public static inline function distance(v1:Vec3, v2:Vec3):FastFloat {
		return distancef(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
	}

	public static inline function distancef(v1x:FastFloat, v1y:FastFloat, v1z:FastFloat, v2x:FastFloat, v2y:FastFloat, v2z:FastFloat):FastFloat {
		var vx = v1x - v2x;
		var vy = v1y - v2y;
		var vz = v1z - v2z;
		return Math.sqrt(vx * vx + vy * vy + vz * vz);
	}

	inline public function distanceTo(p:Vec3):FastFloat {
		return Math.sqrt((p.x - x) * (p.x - x) + (p.y - y) * (p.y - y) + (p.z - z) * (p.z - z));
	}

	inline public function clamp(min:FastFloat, max:FastFloat):Vec3 {
		var l = length();
		if (l < min) normalize().mult(min);
		else if (l > max) normalize().mult(max);
		return this;
	}

	public static inline function xAxis():Vec3 { return new Vec3(1.0, 0.0, 0.0); }
	public static inline function yAxis():Vec3 { return new Vec3(0.0, 1.0, 0.0); }
	public static inline function zAxis():Vec3 { return new Vec3(0.0, 0.0, 1.0); }

	public function toString():String {
		return "(" + this.x + ", " + this.y + ", " + this.z + ")";
	}
}
