package iron.math;

import kha.FastFloat;

class Vec3 {
	public var x:FastFloat;
	public var y:FastFloat;
	public var z:FastFloat;

	public function new(x:FastFloat = 0.0, y:FastFloat = 0.0, z:FastFloat = 0.0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function cross(v:Vec3):Vec3 {
		var x2 = y * v.z - z * v.y;
		var y2 = z * v.x - x * v.z;
		var z2 = x * v.y - y * v.x;
		x = x2;
		y = y2;
		z = z2;
		return this;
	}

	public function crossvecs(a:Vec3, b:Vec3):Vec3 {
		var x2 = a.y * b.z - a.z * b.y;
		var y2 = a.z * b.x - a.x * b.z;
		var z2 = a.x * b.y - a.y * b.x;
		x = x2;
		y = y2;
		z = z2;
		return this;
	}

	public function set(x:FastFloat, y:FastFloat, z:FastFloat):Vec3{
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	public function add(v:Vec3):Vec3 {
		x += v.x;
		y += v.y;
		z += v.z;
		return this;
	}

	public function addf(x:FastFloat, y:FastFloat, z:FastFloat):Vec3 {
		this.x += x;
		this.y += y;
		this.z += z;
		return this;
	}

	public function addvecs(a:Vec3, b:Vec3):Vec3 {
		x = a.x + b.x;
		y = a.y + b.y;
		z = a.z + b.z;
		return this;
	} 

	public function subvecs(a:Vec3, b:Vec3):Vec3 {
		x = a.x - b.x;
		y = a.y - b.y;
		z = a.z - b.z;
		return this;
	}

	public function normalize():Vec3 {
		var n = length();
		if (n > 0.0) {
			var invN = 1.0 / n;
			this.x *= invN; this.y *= invN; this.z *= invN;
		}
		return this;
	}

	public function mult(f:FastFloat):Vec3 {
		x *= f; y *= f; z *= f;
		return this;
	}

	public function dot(v:Vec3):FastFloat {
		return x * v.x + y * v.y + z * v.z;
	}

	public function setFrom(v:Vec3):Vec3 {
		x = v.x; y = v.y; z = v.z;
		return this;
	}

	public function clone():Vec3 {
		return new Vec3(x, y, z);
	}

	public static function lerp(v1:Vec3, v2:Vec3, t:FastFloat):Vec3 {
		var target = new Vec3();
		target.x = v2.x + (v1.x - v2.x) * t;
		target.y = v2.y + (v1.y - v2.y) * t;
		target.z = v2.z + (v1.z - v2.z) * t;
		return target;
	}

	public function applyproj(m:Mat4):Vec3 {
		var x = this.x; var y = this.y; var z = this.z;

		// Perspective divide
		var d = 1.0 / (m._03 * x + m._13 * y + m._23 * z + m._33);

		this.x = (m._00 * x + m._10 * y + m._20 * z + m._30) * d;
		this.y = (m._01 * x + m._11 * y + m._21 * z + m._31) * d;
		this.z = (m._02 * x + m._12 * y + m._22 * z + m._32) * d;

		return this;
	}

	public function applymat(m:Mat4):Vec3 {
		var x = this.x; var y = this.y; var z = this.z;

		this.x = m._00 * x + m._10 * y + m._20 * z + m._30;
		this.y = m._01 * x + m._11 * y + m._21 * z + m._31;
		this.z = m._02 * x + m._12 * y + m._22 * z + m._32;

		return this;
	}

	public inline function equals(v:Vec3):Bool {
		return x == v.x && y == v.y && z == v.z;
	}

	public inline function length():FastFloat {
		return Math.sqrt(x * x + y * y + z * z);
	}

	public inline function normalizeTo(newLength:FastFloat):Vec3 {
		var v = normalize();
		v = mult(newLength);
		return v;
	}

	public function sub(v:Vec3):Vec3 {
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

	public function distanceTo(p:Vec3):FastFloat {
		return Math.sqrt((p.x - x) * (p.x - x) + (p.y - y) * (p.y - y) + (p.z - z) * (p.z - z));
	}

	public function clamp(fmin:FastFloat, fmax:FastFloat):Vec3 {
		var n = length();
		var v = this;

		if (n < fmin) {
			v = normalizeTo(fmin);
		}
		else if (n > fmax) {
			v = normalizeTo(fmax);
		}
		return v;
	}

	public function map(value:Vec3, leftMin:Vec3, leftMax:Vec3, rightMin:Vec3, rightMax:Vec3):Vec3 {
		x = Math.map(value.x, leftMin.x, leftMax.x, rightMin.x, rightMax.x);
		y = Math.map(value.y, leftMin.y, leftMax.y, rightMin.y, rightMax.y);
		z = Math.map(value.z, leftMin.z, leftMax.z, rightMin.z, rightMax.z);
		return this;
	}

	public static function xAxis():Vec3 { return new Vec3(1.0, 0.0, 0.0); }
	public static function yAxis():Vec3 { return new Vec3(0.0, 1.0, 0.0); }
	public static function zAxis():Vec3 { return new Vec3(0.0, 0.0, 1.0); }
	public static function one():Vec3 { return new Vec3(1.0, 1.0, 1.0); }
	public static function zero():Vec3 { return new Vec3(0.0, 0.0, 0.0); }
	public static function back():Vec3 { return new Vec3(0.0, -1.0, 0.0); }
	public static function forward():Vec3 { return new Vec3(0.0, 1.0, 0.0); }
	public static function down():Vec3 { return new Vec3(0.0, 0.0, -1.0); }
	public static function up():Vec3 { return new Vec3(0.0, 0.0, 1.0); }
	public static function left():Vec3 { return new Vec3(-1.0, 0.0, 0.0); }
	public static function right():Vec3 { return new Vec3(1.0, 0.0, 0.0); }
	public static function negativeInfinity():Vec3 { return new Vec3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY); }
	public static function positiveInfinity():Vec3 { return new Vec3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY); }

	public function toString():String {
		return "(" + this.x + ", " + this.y + ", " + this.z + ")";
	}
}
