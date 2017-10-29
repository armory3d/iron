package iron.object;

import iron.math.Mat4;
import iron.math.Vec4;
import iron.math.Quat;

@:allow(iron.object.Animation)
class Transform {
	public var world:Mat4; // Read only
	public var localOnly = false;
	public var local:Mat4; // Call decompose()
	public var loc:Vec4; // Decomposed local matrix
	public var rot:Quat;
	public var scale:Vec4;
	
	public var dirty:Bool;
	public var object:Object;
	public var size:Vec4;
	public var radius:Float;
	static var temp = Mat4.identity();
	var prependMats:Array<Mat4> = null;
	var appendMats:Array<Mat4> = null;
	public var boneParent:Mat4 = null;

	public function new(object:Object) {
		this.object = object;
		reset();
	}

	public function reset() {
		world = Mat4.identity();
		local = Mat4.identity();
		loc = new Vec4();
		rot = new Quat();
		scale = new Vec4(1.0, 1.0, 1.0);
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

	public function popPrependMatrix() {
		if (prependMats != null) {
			prependMats.pop();
			if (prependMats.length == 0) prependMats = null;
		}
	}

	public function appendMatrix(m:Mat4) {
		if (appendMats == null) appendMats = [];
		appendMats.push(m);
	}

	public function popAppendMatrix() {
		if (appendMats != null) {
			appendMats.pop();
			if (appendMats.length == 0) appendMats = null;
		}
	}

	function composeDelta() {
		// Delta transform
		dloc.addvecs(loc, dloc);
		dscale.addvecs(dscale, scale);
		drot.fromEuler(_deulerX, _deulerY, _deulerZ);
		drot.multquats(rot, drot);
		local.compose(dloc, drot, dscale);
	}

	public function buildMatrix() {
		dloc == null ? local.compose(loc, rot, scale) : composeDelta();

		if (prependMats != null) {
			temp.setIdentity();
			for (m in prependMats) temp.multmat2(m);
			temp.multmat2(local);
			local.setFrom(temp);
		}
		
		if (appendMats != null) for (m in appendMats) local.multmat2(m);

		if (boneParent != null) local.multmats(boneParent, local);
		if (object.parent != null && !localOnly) {
			world.multmat3x4(local, object.parent.transform.world);
		}
		else {
			world.setFrom(local);
		}

		// Constraints
		if (object.constraints != null) for (c in object.constraints) c.apply(this);

		// Update children
		for (n in object.children) {
			n.transform.buildMatrix();
		}
	}

	public function set(x = 0.0, y = 0.0, z = 0.0, rX = 0.0, rY = 0.0, rZ = 0.0, sX = 1.0, sY = 1.0, sZ = 1.0) {
		loc.set(x, y, z);
		setRotation(rX, rY, rZ);
		scale.set(sX, sY, sZ);
		buildMatrix();
	}

	public function translate(x:Float, y:Float, z:Float) {
		loc.x += x;
		loc.y += y;
		loc.z += z;
		buildMatrix();
	}

	public function setMatrix(mat:Mat4) {
		local.setFrom(mat);
		decompose();
		dirty = true;
	}

	public function multMatrix(mat:Mat4) {
		local.multmat2(mat);
		decompose();
	}

	public function decompose() {
		local.decompose(loc, rot, scale);
	}

	public function rotate(axis:Vec4, f:Float) {
		var q = new Quat();
		q.fromAxisAngle(axis, f);
		rot.multquats(q, rot);
		dirty = true;
	}

	public function setRotation(x:Float, y:Float, z:Float) {
		rot.fromEuler(x, y, z);
		dirty = true;
		_eulerX = x;
		_eulerY = y;
		_eulerZ = z;
	}

	public function computeRadius() {
		radius = Math.sqrt(size.x * size.x + size.y * size.y + size.z * size.z);// / 2;
	}

	public function setDimensions(x:Float, y:Float, z:Float) {
		size.set(x, y, z);
		computeRadius();
	}

	// Wrong order returned from getEuler(), store last state for animation
	var _eulerX:Float;
	var _eulerY:Float;
	var _eulerZ:Float;

	public inline function look():Vec4 { return world.look(); }
	public inline function right():Vec4 { return world.right(); }
	public inline function up():Vec4 { return world.up(); }

	public inline function worldx():Float { return world._30; }
	public inline function worldy():Float { return world._31; }
	public inline function worldz():Float { return world._32; }

	// Animated delta transform
	public var dloc:Vec4 = null;
	public var drot:Quat = null;
	public var dscale:Vec4 = null;
	var _deulerX:Float;
	var _deulerY:Float;
	var _deulerZ:Float;
}
