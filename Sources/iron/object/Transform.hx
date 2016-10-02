package iron.object;

import iron.math.Mat4;
import iron.math.Vec4;
import iron.math.Quat;

class Transform {
	public var matrix:Mat4;
	public var local:Mat4;
	public var localOnly:Bool = false;
	public var dirty:Bool;

	// Decomposed local matrix
	public var loc:Vec4;
	public var rot:Quat;
	public var scale:Vec4;
	
	public var object:Object;
	public var size:Vec4;
	public var radius:Float;
	static var temp = Mat4.identity();
	var prependMats:Array<Mat4> = null;
	var appendMats:Array<Mat4> = null;

	public function new(object:Object) {
		this.object = object;
		reset();
	}

	public function reset() {
		matrix = Mat4.identity();
		local = Mat4.identity();
		loc = new Vec4();
		rot = new Quat();
		scale = new Vec4(1, 1, 1);
		size = new Vec4();
		dirty = true;
	}

	public function update() {
		if (dirty) { dirty = false; buildMatrix(); }
	}

	public function prependMatrix(m:Mat4) {
		if (prependMats == null) prependMats = [];
		prependMats.push(m);
	}

	public function appendMatrix(m:Mat4) {
		if (appendMats == null) appendMats = [];
		appendMats.push(m);
	}

	public function buildMatrix() {
		local.compose(loc, rot, scale);
		
		if (prependMats != null) {
			temp.setIdentity();
			for (m in prependMats) temp.mult2(m);
			temp.mult2(local);
			local.loadFrom(temp);
		}
		
		if (appendMats != null) for (m in appendMats) local.mult2(m);

		if (!localOnly && object.parent != null) {
			matrix.multiply3x4(local, object.parent.transform.matrix);
		}
		else {
			matrix = local;
		}

		// Constraints
		if (object.constraints != null) for (c in object.constraints) c.apply(this);

		// Update children
		for (n in object.children) {
			n.transform.buildMatrix();
		}
	}

	public function set(x:Float = 0, y:Float = 0, z:Float = 0, rX:Float = 0, rY:Float = 0, rZ:Float = 0, sX:Float = 1, sY:Float = 1, sZ:Float = 1) {
		loc.set(x, y, z);
		setRotation(rX, rY, rZ);
		scale.set(sX, sY, sZ);
		buildMatrix();
	}

	public function setMatrix(mat:Mat4) {
		matrix = mat;
		loc = matrix.loc();
		scale = matrix.scaleV();
		rot = matrix.getQuat();
	}

	public function rotate(axis:Vec4, f:Float) {
		var q = new Quat();
		q.setFromAxisAngle(axis, f);
		rot.multiply(q, rot);
		dirty = true;
	}

	public function setRotation(x:Float, y:Float, z:Float) {
		rot.setFromEuler(x, y, z, "ZXY");
		dirty = true;
	}

	public function getEuler():Vec4 {
		var v = new Vec4();
		rot.toEuler(v);
		return v;
	}

	public function setEuler(v:Vec4) {
		rot.setFromEuler(v.x, v.y, v.z, "YZX");
		dirty = true;
	}

	public function computeRadius() {
		radius = Math.sqrt(size.x * size.x + size.y * size.y + size.z * size.z);// / 2;
	}

	public inline function look():Vec4 { return matrix._look2(); }
	public inline function right():Vec4 { return matrix._right2(); }
	public inline function up():Vec4 { return matrix._up2(); }

	public inline function absx():Float { return matrix._30; }
	public inline function absy():Float { return matrix._31; }
	public inline function absz():Float { return matrix._32; }
}
