package fox.math;

/**
 * @author mrdoob / http://mrdoob.com/
 * @author *kile / http://kile.stravaganza.org/
 * @author philogb / http://blog.thejit.org/
 * @author mikael emtinger / http://gomo.se/
 * @author egraether / http://egraether.com/
 * @author WestLangley / http://github.com/WestLangley
 * @haxeport Krtolica Vujadin - GameStudioHx.com
 */

class Vector3 {
		
	public var x:Float;
	public var y:Float;
	public var z:Float;
	
	public var u:Float;
	public var v:Float;
	public var w:Float;
	
	public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
		
		// TODO: Inspect this, rendering in canvas2d is broken because of this
		//this.u = 1.5;
		//this.v = 1.5;
		//this.w = 1.5;
	}
	
	public function set(x:Float = 0, y:Float = 0, z:Float = 0):Vector3 {
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}	
	
	public function setX(x:Float = 0):Vector3 {
		this.x = x;
		return this;
	}	
	
	public function setY(y:Float = 0):Vector3 {
		this.y = y;
		return this;
	}	
	
	public function setZ(z:Float = 0):Vector3 {
		this.z = z;
		return this;
	}	
	
	public function setComponent(index:Int, value:Float):Vector3 {
		switch (index) {
			case 0: x = value;
			case 1: y = value;
			case 2: z = value;
			default: trace("setComponent: Index is out of range ($index)");
		}
		return this;
	}
	
	public function getComponent(index:Int):Float {
		switch (index) {
			case 0: return x;
			case 1: return y;
			case 2: return z;
			default:
				trace("getComponent: Index is out of range ($index)");
				return 0.0;
		}
	}
	
	public function copy(v:Vector3):Vector3 {
		x = v.x;
		y = v.y;
		z = v.z;
		return this;
	}	
	
	public function add(v:Vector3, w:Vector3 = null):Vector3 {
		if (w != null) {
			trace("DEPRECATED: Vector3\'s .add() now only accepts one argument. Use .addVectors( a, b ) instead.");
			return this.addVectors(v, w);
		}

		x += v.x;
		y += v.y;
		z += v.z;

		return this;
	}	
	
	public function addScalar(s:Float):Vector3 {
		x += s;
		y += s;
		z += s;
		return this;
	}	
	
	public function addVectors(a:Vector3, b:Vector3):Vector3 {
		x = a.x + b.x;
		y = a.y + b.y;
		z = a.z + b.z;
		return this;
	}	
	
	public function sub(v:Vector3, w:Vector3 = null):Vector3 {
		if (w != null) {
			trace("DEPRECATED: Vector3\'s .sub() now only accepts one argument. Use .subVectors( a, b ) instead.");
			return this.subVectors(v, w);
		}
		
		x -= v.x;
		y -= v.y;
		z -= v.z;
		return this;
	}	
	
	public function subVectors(a:Vector3, b:Vector3):Vector3 {
		x = a.x - b.x;
		y = a.y - b.y;
		z = a.z - b.z;
		return this;
	}	
	
	public function multiply(v:Vector3, w:Vector3 = null):Vector3 {
		if (w != null) {
			trace("DEPRECATED: Vector3\'s .multiply() now only accepts one argument. Use .multiplyVectors( a, b ) instead.");
			return this.multiplyVectors(v, w);
		}
		
		x *= v.x;
		y *= v.y;
		z *= v.z;
		return this;
	}	
	
	public function multiplyScalar(scalar:Float):Vector3 {
		x *= scalar;
		y *= scalar;
		z *= scalar;
		return this;
	}
		
	public function multiplyVectors(a:Vector3, b:Vector3):Vector3 {
		x = a.x * b.x;
		y = a.y * b.y;
		z = a.z * b.z;
		return this;
	}
	
	/*public function applyMatrix3(m:Matrix3):Vector3 {
		var x = this.x;
		var y = this.y;
		var z = this.z;
		
		var e = m.elements;
		
		this.x = e[0] * x + e[3] * y + e[6] * z;
		this.y = e[1] * x + e[4] * y + e[7] * z;
		this.z = e[2] * x + e[5] * y + e[8] * z;

		return this;
	}*/
	
	public function applyMatrix4(m:Matrix4):Vector3 {
		// input: THREE.Matrix4 affine matrix
		var x = this.x;
		var y = this.y;
		var z = this.z;

		var e = m.elements;

		this.x = e[0] * x + e[4] * y + e[8]  * z + e[12];
		this.y = e[1] * x + e[5] * y + e[9]  * z + e[13];
		this.z = e[2] * x + e[6] * y + e[10] * z + e[14];

		return this;
	}	
	
	public function applyProjection(m:Matrix4):Vector3 {
		var e = m.elements;
		var x = this.x;
		var y = this.y;
		var z = this.z;
		var d = 1 / (e[3] * x + e[7] * y + e[11] * z + e[15]);
		this.x = (e[0] * x + e[4] * y + e[8] * z + e[12]) * d;
		this.y = (e[1] * x + e[5] * y + e[9] * z + e[13]) * d;
		this.z = (e[2] * x + e[6] * y + e[10] * z + e[14]) * d;
		return this;
	}
	
	/*public function applyQuaternion(q:Quaternion):Vector3 {		
		var qx = q.x;
		var qy = q.y;
		var qz = q.z;
		var qw = q.w;

		// calculate quat * vector
		var ix =  qw * this.x + qy * this.z - qz * this.y;
		var iy =  qw * this.y + qz * this.x - qx * this.z;
		var iz =  qw * this.z + qx * this.y - qy * this.x;
		var iw = -qx * this.x - qy * this.y - qz * this.z;

		// calculate result * inverse quat
		this.x = ix * qw + iw * -qx + iy * -qz - iz * -qy;
		this.y = iy * qw + iw * -qy + iz * -qx - ix * -qz;
		this.z = iz * qw + iw * -qz + ix * -qy - iy * -qx;

		return this;
	}*/
	
	public function transformDirection(m:Matrix4):Vector3 {
		var e = m.elements;
		this.x = e[0] * this.x + e[4] * this.y + e[8] * this.z;
		this.y = e[1] * this.x + e[5] * this.y + e[9] * this.z;
		this.z = e[2] * this.x + e[6] * this.y + e[10] * this.z;
		normalize();
		return this;
	}
	
	public function divide(v:Vector3):Vector3 {
		x /= v.x;
		y /= v.y;
		z /= v.z;
		return this;
	}	
	
	public function divideScalar(scalar:Float):Vector3 {
		if (scalar != 0) {
			var invScalar = 1 / scalar;

			this.x *= invScalar;
			this.y *= invScalar;
			this.z *= invScalar;
		} else {
			this.x = 0;
			this.y = 0;
			this.z = 0;
		}

		return this;
	}
	
	public function min(v:Vector3):Vector3 {
		if (x > v.x) x = v.x;
		if (y > v.y) y = v.y;
		if (z > v.z) z = v.z;
		return this;
	}	
	
	public function max(v:Vector3):Vector3 {
		if (x < v.x) x = v.x;
		if (y < v.y) y = v.y;
		if (z < v.z) z = v.z;
		return this;
	}	
	
	public function clamp(vmin:Vector3, vmax:Vector3):Vector3 {
		// This function assumes min < max, if this assumption isn't true it will not operate correctly
		if (x < vmin.x) x = vmin.x; else if (x > vmax.x) x = vmax.x;
		if (y < vmin.y) y = vmin.y; else if (y > vmax.y) y = vmax.y;
		if (z < vmin.z) z = vmin.z; else if (z > vmax.z) z = vmax.z;
		return this;
	}	
	
	public function negate():Vector3 {
		return multiplyScalar(-1);
	}	
	
	public function dot(v:Vector3):Float {
		return x * v.x + y * v.y + z * v.z;
	}	
	
	public function lengthSq():Float {
		return x * x + y * y + z * z;
	}	
	
	public function length():Float {
		return Math.sqrt(x * x + y * y + z * z);
	}	
	
	public function lengthManhattan():Float {
		return Math.abs(x) + Math.abs(y) + Math.abs(z);
	}
	
	public function normalize():Vector3 {
		return divideScalar(length());
	}	
	
	public function setLength(l:Float):Vector3 {
		var oldLength = length();
		if (oldLength != 0 && l != oldLength) multiplyScalar(l / oldLength);
		return this;
	}	
	
	public function lerp(v:Vector3, alpha:Float):Vector3 {
		x += (v.x - x) * alpha;
		y += (v.y - y) * alpha;
		z += (v.z - z) * alpha;
		return this;
	}	
	
	public function cross(v:Vector3):Vector3 {
		x = y * v.z - z * v.y;
		y = z * v.x - x * v.z;
		z = x * v.y - y * v.x;
		return this;
	}	
	
	public function crossVectors(a:Vector3, b:Vector3):Vector3 {
		x = a.y * b.z - a.z * b.y;
		y = a.z * b.x - a.x * b.z;
		z = a.x * b.y - a.y * b.x;
		return this;
	}	
	
	public function angleTo(v:Vector3):Float {
		var theta:Float = dot(v) / (length() * v.length());		
		// clamp, to handle numerical problems
		return Math.acos(fox.math.Math.clamp(theta, -1, 1));
	}
	
	public function distanceTo(v:Vector3):Float {
		return Math.sqrt(distanceToSquared(v));
	}
	
	public function distanceToSquared(v:Vector3):Float {
		var dx = x - v.x;
		var dy = y - v.y;
		var dz = z - v.z;
		return dx * dx + dy * dy + dz * dz;
	}	
	
	public function setEulerFromRotationMatrix(m:Matrix4, order:String = 'XYZ'):Vector3 {
		trace("REMOVED: Vector3\'s setEulerFromRotationMatrix has been removed in favor of Euler.setFromRotationMatrix(), please update your code.");
		return null;
	}	
	
	//public function setEulerFromQuaternion(q:Quaternion, order:String = 'XYZ'):Vector3 {
	//	trace("REMOVED: Vector3\'s setEulerFromQuaternion: has been removed in favor of Euler.setFromQuaternion(), please update your code.");
	//	return null;
	//}	
	
	public function getPositionFromMatrix(m:Matrix4):Vector3 {
		trace("DEPRECATED: Vector3\'s .getPositionFromMatrix() has been renamed to .setFromMatrixPosition(). Please update your code.");
		return this.setFromMatrixPosition(m);
	}	
	
	public function getScaleFromMatrix(m:Matrix4):Vector3 {
		trace("DEPRECATED: Vector3\'s .getScaleFromMatrix() has been renamed to .setFromMatrixScale(). Please update your code.");
		return this.setFromMatrixScale(m);
	}	
	
	public function getColumnFromMatrix(index:Int, m:Matrix4):Vector3 {
		trace("DEPRECATED: Vector3\'s .getColumnFromMatrix() has been renamed to .setFromMatrixColumn(). Please update your code.");
		return this.setFromMatrixColumn(index, m);
	}
	
	public function setFromMatrixPosition(m:Matrix4):Vector3 {
		this.x = m.elements[12];
		this.y = m.elements[13];
		this.z = m.elements[14];

		return this;
	}
	
	public function setFromMatrixScale(m:Matrix4):Vector3 {
		var sx = this.set(m.elements[0], m.elements[1], m.elements[2]).length();
		var sy = this.set(m.elements[4], m.elements[5], m.elements[6]).length();
		var sz = this.set(m.elements[8], m.elements[9], m.elements[10]).length();

		this.x = sx;
		this.y = sy;
		this.z = sz;

		return this;
	}
	
	public function setFromMatrixColumn(index:Int, matrix:Matrix4):Vector3 {
		var offset = index * 4;

		var me = matrix.elements;

		this.x = me[offset];
		this.y = me[offset + 1];
		this.z = me[offset + 2];

		return this;
	}
	
	public function equals(v:Vector3):Bool {
		return ((x == v.x) && (y == v.y) && (z == v.z));
	}
	
	public function fromArray(a:Array<Float>):Vector3 {
		x = a[0];
		y = a[1];
		z = a[2];
		return this;
	}	
	
	public function toArray():Array<Float> {
		return [this.x, this.y, this.z];
	}	
	
	public function clone():Vector3 {
		return new Vector3(x, y, z);
	}	
	
	/*public function applyEuler(euler:Euler):Vector3 {
		if (!Std.is(euler, Euler)) {
			throw("ERROR: Vector3\'s .applyEuler() now expects a Euler rotation rather than a Vector3 and order.  Please update your code.");
		}
		var quaternion = new Quaternion();
		this.applyQuaternion(quaternion.setFromEuler(euler, false));

		return this;
	}*/
	
	/*public function applyAxisAngle(axis:Vector3, angle:Float):Vector3 {
		var q1 = new Quaternion();
		applyQuaternion(q1.setFromAxisAngle(axis, angle));
		return this;
	}*/
	
	public function projectOnVector(vector:Vector3):Vector3 {
		var v1 = new Vector3();
		v1.copy(vector).normalize();
		var d = dot(v1);
		copy(v1).multiplyScalar(d);
		return this;
	}	
	
	public function projectOnPlane(planeNormal:Vector3):Vector3 {
		var v1 = new Vector3();
		v1.copy(this).projectOnVector(planeNormal);
		return this.sub(v1);
	}	
	
	public function reflect(vector:Vector3):Vector3 {
		var v1 = new Vector3();
		v1.copy(this).projectOnVector(vector).multiplyScalar(2);
		return this.subVectors(v1, this);
	}
}
