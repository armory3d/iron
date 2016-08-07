package iron.node;

import iron.math.Mat4;
import iron.math.Vec4;
import iron.math.Quat;

class Transform {
	public var matrix:Mat4;
	public var local:Mat4;
	public var localOnly:Bool = false;
	public var prepend:Mat4 = null;
	public var append:Mat4 = null;
	public var dirty:Bool;

	// Decomposed local matrix
	public var pos:Vec4;
	public var rot:Quat;
	public var scale:Vec4;
	public var size:Vec4;
	public var radius:Float;

	public var node:Node;

	static var temp = Mat4.identity();

	public function new(node:Node) {
		this.node = node;
		reset();
	}

	public function reset() {
		matrix = Mat4.identity();
		local = Mat4.identity();

		pos = new Vec4();
		rot = new Quat();
		scale = new Vec4(1, 1, 1);
		size = new Vec4();

		dirty = true;
	}

	public function update() {
		if (dirty) {
			dirty = false;
			buildMatrix();
		}
	}

	public function buildMatrix() {
		local.compose(pos, rot, scale);
		
		if (prepend != null) {
			prepend.mult2(local);
			local.loadFrom(prepend);
		}
		if (append != null) local.mult2(append);

		if (!localOnly && node.parent != null) {
			matrix.multiply3x4(local, node.parent.transform.matrix);
		}
		else {
			matrix = local;
		}

		// Update children
		for (n in node.children) {
			n.transform.buildMatrix();
		}
	}

	public function set(x:Float = 0, y:Float = 0, z:Float = 0, rX:Float = 0, rY:Float = 0, rZ:Float = 0, sX:Float = 1, sY:Float = 1, sZ:Float = 1) {
		pos.set(x, y, z);
		setRotation(rX, rY, rZ);
		scale.set(sX, sY, sZ);
		buildMatrix();
	}

	public function setMatrix(mat:Mat4) {
		matrix = mat;
		pos = matrix.pos();
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

	public function getForward():Vec4 {
        var mat = Mat4.identity();
        rot.saveToMatrix(mat);
        var f = new Vec4(0, 1, 0);
        f.applyProjection(mat);
        f = f.mult(iron.sys.Time.delta * 200); // TODO: remove delta
        return f;
    }

    public function getBackward():Vec4 {
        var mat = Mat4.identity();
        rot.saveToMatrix(mat);
        var f = new Vec4(0, -1, 0);
        f.applyProjection(mat);
        f = f.mult(iron.sys.Time.delta * 200);
        return f;
    }

    public function getRight():Vec4 {
        var mat = Mat4.identity();
        rot.saveToMatrix(mat);
        var f = new Vec4(1, 0, 0);
        f.applyProjection(mat);
        f = f.mult(iron.sys.Time.delta * 200);
        return f;
    }

    public function getLeft():Vec4 {
        var mat = Mat4.identity();
        rot.saveToMatrix(mat);
        var f = new Vec4(-1, 0, 0);
        f.applyProjection(mat);
        f = f.mult(iron.sys.Time.delta * 200);
        return f;
    }

    public function getUp():Vec4 {
        var mat = Mat4.identity();
        rot.saveToMatrix(mat);
        var f = new Vec4(0, 0, 1);
        f.applyProjection(mat);
        f = f.mult(iron.sys.Time.delta * 200);
        return f;
    }

    public function getDown():Vec4 {
        var mat = Mat4.identity();
        rot.saveToMatrix(mat);
        var f = new Vec4(0, 0, -1);
        f.applyProjection(mat);
        f = f.mult(iron.sys.Time.delta * 200);
        return f;
    }

    public function computeRadius() {
    	radius = Math.sqrt(size.x * size.x + size.y * size.y + size.z * size.z);// / 2;
    }

 	public inline function absx():Float { return matrix._30; }
	public inline function absy():Float { return matrix._31; }
	public inline function absz():Float { return matrix._32; }
}
