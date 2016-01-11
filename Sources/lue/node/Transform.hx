package lue.node;

import lue.math.Mat4;
import lue.math.Vec3;
import lue.math.Quat;

class Transform {

	public var matrix:Mat4;
	public var temp:Mat4;
	public var append:Mat4 = null;
	public var dirty:Bool;

	public var pos:Vec3;
	public var rot:Quat;
	public var scale:Vec3;
	public var size:Vec3;

	var node:Node;

	public function new(node:Node) {
		this.node = node;
		reset();
	}

	public function reset() {
		matrix = new Mat4();
		temp = new Mat4();

		pos = new Vec3();
		rot = new Quat();
		scale = new Vec3(1, 1, 1);
		size = new Vec3();

		dirty = true;
	}

	public function update() {
		if (dirty) {
			dirty = false;
			buildMatrix();
		}
	}

	public function buildMatrix() {
		matrix.identity();
		matrix.scale(scale);
		rot.saveToMatrix(temp);
		matrix.mult(temp);
		//matrix.translate(pos.x, pos.y, pos.z);
		matrix._41 = pos.x;
		matrix._42 = pos.y;
		matrix._43 = pos.z;

		// Transform node
		if (append != null) matrix.mult(append);

		if (node.parent != null) {
			matrix.multiply3x4(matrix, node.parent.transform.matrix);
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

	public function rotate(axis:Vec3, f:Float) {
		var q = new Quat();
		q.setFromAxisAngle(axis, f);
		rot.multiply(rot, q);
		dirty = true;
	}

	public function setRotation(x:Float, y:Float, z:Float) {
		rot.setFromEuler(x, y, z, "ZXY");
		dirty = true;
	}

	public function getEuler():Vec3 {
		var v = new Vec3();
		rot.toEuler(v);
		return v;
	}

	public function setEuler(v:Vec3) {
		rot.setFromEuler(v.x, v.y, v.z, "YZX");
		dirty = true;
	}

	public function getForward():Vec3 {
        var mat = new Mat4();
        rot.saveToMatrix(mat);
        var f = new Vec3(0, 1, 0);
        f.applyProjection(mat);
        f = f.mult(lue.sys.Time.delta * 200); // TODO: remove delta
        return f;
    }

    public function getBackward():Vec3 {
        var mat = new Mat4();
        rot.saveToMatrix(mat);
        var f = new Vec3(0, -1, 0);
        f.applyProjection(mat);
        f = f.mult(lue.sys.Time.delta * 200);
        return f;
    }

    public function getRight():Vec3 {
        var mat = new Mat4();
        rot.saveToMatrix(mat);
        var f = new Vec3(1, 0, 0);
        f.applyProjection(mat);
        f = f.mult(lue.sys.Time.delta * 200);
        return f;
    }

    public function getLeft():Vec3 {
        var mat = new Mat4();
        rot.saveToMatrix(mat);
        var f = new Vec3(-1, 0, 0);
        f.applyProjection(mat);
        f = f.mult(lue.sys.Time.delta * 200);
        return f;
    }

    public function getUp():Vec3 {
        var mat = new Mat4();
        rot.saveToMatrix(mat);
        var f = new Vec3(0, 0, 1);
        f.applyProjection(mat);
        f = f.mult(lue.sys.Time.delta * 200);
        return f;
    }

    public function getDown():Vec3 {
        var mat = new Mat4();
        rot.saveToMatrix(mat);
        var f = new Vec3(0, 0, -1);
        f.applyProjection(mat);
        f = f.mult(lue.sys.Time.delta * 200);
        return f;
    }

 	public inline function absx():Float { return matrix._41; }

	public inline function absy():Float { return matrix._42; }

	public inline function absz():Float { return matrix._43; }
}
