package iron.math;

using iron.math.MathStaticExtension;
import kha.FastFloat;

class Rotator {
	public var x:FastFloat;
	public var y:FastFloat;
	public var z:FastFloat;

	public function new(x:FastFloat = 0.0, y:FastFloat = 0.0, z:FastFloat = 0.0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function toDegrees():Rotator {
		this.x = this.x.toDegrees();
		this.y = this.y.toDegrees();
		this.z = this.z.toDegrees();
		return this;
	}

	public function toRadians():Rotator {
		this.x = this.x.toRadians();
		this.y = this.y.toRadians();
		this.z = this.z.toRadians();
		return this;
	}

	public function cross(v:Rotator):Rotator {
		var x2 = y * v.z - z * v.y;
		var y2 = z * v.x - x * v.z;
		var z2 = x * v.y - y * v.x;
		x = x2;
		y = y2;
		z = z2;
		return this;
	}

	public function crossvecs(a:Rotator, b:Rotator):Rotator {
		var x2 = a.y * b.z - a.z * b.y;
		var y2 = a.z * b.x - a.x * b.z;
		var z2 = a.x * b.y - a.y * b.x;
		x = x2;
		y = y2;
		z = z2;
		return this;
	}

	public function set(x:FastFloat, y:FastFloat, z:FastFloat):Rotator{
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	public function add(v:Rotator):Rotator {
		x += v.x;
		y += v.y;
		z += v.z;
		return this;
	}

	public function addf(x:FastFloat, y:FastFloat, z:FastFloat):Rotator {
		this.x += x;
		this.y += y;
		this.z += z;
		return this;
	}

	public function addvecs(a:Rotator, b:Rotator):Rotator {
		x = a.x + b.x;
		y = a.y + b.y;
		z = a.z + b.z;
		return this;
	} 

	public function subvecs(a:Rotator, b:Rotator):Rotator {
		x = a.x - b.x;
		y = a.y - b.y;
		z = a.z - b.z;
		return this;
	}

	public function normalize():Rotator {
		var n = length();
		if (n > 0.0) {
			var invN = 1.0 / n;
			this.x *= invN; this.y *= invN; this.z *= invN;
		}
		return this;
	}

	public function mult(f:FastFloat):Rotator {
		x *= f; y *= f; z *= f;
		return this;
	}

	public function dot(v:Rotator):FastFloat {
		return x * v.x + y * v.y + z * v.z;
	}

	public function setFrom(v:Rotator):Rotator {
		x = v.x; y = v.y; z = v.z;
		return this;
	}

	public function clone():Rotator {
		return new Rotator(x, y, z);
	}

	public static function lerp(v1:Rotator, v2:Rotator, t:FastFloat):Rotator {
		var target = new Rotator();
		target.x = v2.x + (v1.x - v2.x) * t;
		target.y = v2.y + (v1.y - v2.y) * t;
		target.z = v2.z + (v1.z - v2.z) * t;
		return target;
	}

	public function applyproj(m:Mat4):Rotator {
		var x = this.x; var y = this.y; var z = this.z;

		// Perspective divide
		var d = 1.0 / (m._03 * x + m._13 * y + m._23 * z + m._33);

		this.x = (m._00 * x + m._10 * y + m._20 * z + m._30) * d;
		this.y = (m._01 * x + m._11 * y + m._21 * z + m._31) * d;
		this.z = (m._02 * x + m._12 * y + m._22 * z + m._32) * d;

		return this;
	}

	public function applymat(m:Mat4):Rotator {
		var x = this.x; var y = this.y; var z = this.z;

		this.x = m._00 * x + m._10 * y + m._20 * z + m._30;
		this.y = m._01 * x + m._11 * y + m._21 * z + m._31;
		this.z = m._02 * x + m._12 * y + m._22 * z + m._32;

		return this;
	}

	public inline function equals(v:Rotator):Bool {
		return x == v.x && y == v.y && z == v.z;
	}

	public inline function length():FastFloat {
		return Math.sqrt(x * x + y * y + z * z);
	}

	public inline function normalizeTo(newLength:FastFloat):Rotator {
		var v = normalize();
		v = mult(newLength);
		return v;
	}

	public function sub(v:Rotator):Rotator {
		x -= v.x; y -= v.y; z -= v.z;
		return this;
	}

	public static inline function distance(v1:Rotator, v2:Rotator):FastFloat {
		return distancef(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
	}

	public static inline function distancef(v1x:FastFloat, v1y:FastFloat, v1z:FastFloat, v2x:FastFloat, v2y:FastFloat, v2z:FastFloat):FastFloat {
		var vx = v1x - v2x;
		var vy = v1y - v2y;
		var vz = v1z - v2z;
		return Math.sqrt(vx * vx + vy * vy + vz * vz);
	}

	public function distanceTo(p:Rotator):FastFloat {
		return Math.sqrt((p.x - x) * (p.x - x) + (p.y - y) * (p.y - y) + (p.z - z) * (p.z - z));
	}

	public function clamp(fmin:FastFloat, fmax:FastFloat):Rotator {
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

	public static function xAxis():Rotator { return new Rotator(1.0, 0.0, 0.0); }
	public static function yAxis():Rotator { return new Rotator(0.0, 1.0, 0.0); }
	public static function zAxis():Rotator { return new Rotator(0.0, 0.0, 1.0); }
	public static function one():Rotator { return new Rotator(1.0, 1.0, 1.0); }
	public static function zero():Rotator { return new Rotator(0.0, 0.0, 0.0); }
	public static function back():Rotator { return new Rotator(0.0, -1.0, 0.0); }
	public static function forward():Rotator { return new Rotator(0.0, 1.0, 0.0); }
	public static function down():Rotator { return new Rotator(0.0, 0.0, -1.0); }
	public static function up():Rotator { return new Rotator(0.0, 0.0, 1.0); }
	public static function left():Rotator { return new Rotator(-1.0, 0.0, 0.0); }
	public static function right():Rotator { return new Rotator(1.0, 0.0, 0.0); }
	public static function negativeInfinity():Rotator { return new Rotator(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY); }
	public static function positiveInfinity():Rotator { return new Rotator(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY); }

	public function toString():String {
		return "(" + this.x + ", " + this.y + ", " + this.z + ")";
	}
}
