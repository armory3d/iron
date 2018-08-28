package iron.object;

import iron.math.Mat4;
import iron.math.Vec4;
import iron.math.Quat;

class Transform {
	public var world:Mat4; // Read only
	public var localOnly = false; // Whether to apply parent matrix
	public var local:Mat4; // Call decompose()
	public var loc:Vec4; // Decomposed local matrix
	public var rot:Quat;
	public var scale:Vec4;
	
	public var dirty:Bool;
	public var object:Object;
	public var dim:Vec4;
	public var radius:kha.FastFloat;
	static var temp = Mat4.identity();
	static var q = new Quat();
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
		dim = new Vec4(2.0, 2.0, 2.0);
		radius = 1.0;
		dirty = true;
	}

	public function update() {
		if (dirty) buildMatrix();
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
			for (m in prependMats) temp.multmat(m);
			temp.multmat(local);
			local.setFrom(temp);
		}
		if (appendMats != null) for (m in appendMats) local.multmat(m);

		if (boneParent != null) local.multmats(boneParent, local);
		
		if (object.parent != null && !localOnly) {
			world.multmats3x4(local, object.parent.transform.world);
		}
		else {
			world.setFrom(local);
		}

		// Constraints
		if (object.constraints != null) for (c in object.constraints) c.apply(this);

		computeDim();

		// Update children
		for (n in object.children) {
			n.transform.buildMatrix();
		}

		dirty = false;
	}

	/**
	 * Move the game Object by the defined amount relative to it's current location.
	 *
	 * @param	x Amount to move on the x axis.
	 * @param	y Amount to move on the y axis.
	 * @param	z Amount to move on the z axis.
	 */
	public function translate(x:kha.FastFloat, y:kha.FastFloat, z:kha.FastFloat) {
		loc.x += x;
		loc.y += y;
		loc.z += z;
		buildMatrix();
	}

	public function setMatrix(mat:Mat4) {
		local.setFrom(mat);
		decompose();
		buildMatrix();
	}

	public function multMatrix(mat:Mat4) {
		local.multmat(mat);
		decompose();
		buildMatrix();
	}

	public function decompose() {
		local.decompose(loc, rot, scale);
	}

	public function rotate(axis:Vec4, f:kha.FastFloat) {
		q.fromAxisAngle(axis, f);
		rot.multquats(q, rot);
		dirty = true;
	}

	/**
	 * Set the rotation of the object in radians.
	 *
	 * @param	x Set the x axis rotation in radians.
	 * @param	y Set the y axis rotation in radians.
	 * @param	z Set the z axis rotation in radians.
	 */
	public function setRotation(x:kha.FastFloat, y:kha.FastFloat, z:kha.FastFloat) {
		rot.fromEuler(x, y, z);
		_eulerX = x;
		_eulerY = y;
		_eulerZ = z;
		dirty = true;
	}

	function computeRadius() {
		radius = Math.sqrt(dim.x * dim.x + dim.y * dim.y + dim.z * dim.z);
	}

	function computeDim() {
		if (object.raw == null) { computeRadius(); return; }
		var d = object.raw.dimensions;
		if (d == null) dim.set(2 * scale.x, 2 * scale.y, 2 * scale.z);
		else dim.set(d[0] * scale.x, d[1] * scale.y, d[2] * scale.z);
		computeRadius();
	}

	public function applyParentInverse() {
		var pt = object.parent.transform;
		pt.buildMatrix();
		temp.getInverse(pt.world);
		this.local.multmat(temp);
		this.decompose();
		this.buildMatrix();
	}

	public function applyParent() {
		var pt = object.parent.transform;
		this.local.multmat(pt.world);
		this.decompose();
	}

	var lastWorld:Mat4 = null;
	public function diff():Bool {
		if (lastWorld == null) { lastWorld = Mat4.identity().setFrom(world); return false; }
		var a = world;
		var b = lastWorld;
		var r = a._00 != b._00 || a._01 != b._01 || a._02 != b._02 || a._03 != b._03 ||
				a._10 != b._10 || a._11 != b._11 || a._12 != b._12 || a._13 != b._13 ||
				a._20 != b._20 || a._21 != b._21 || a._22 != b._22 || a._23 != b._23 ||
				a._30 != b._30 || a._31 != b._31 || a._32 != b._32 || a._33 != b._33;
		if (r) lastWorld.setFrom(world);
		return r;
	}

	public function overlap(t2:Transform) {
		var t1 = this;
		return t1.worldx() + t1.dim.x / 2 > t2.worldx() - t2.dim.x / 2 && t1.worldx() - t1.dim.x / 2 < t2.worldx() + t2.dim.x / 2 &&
			   t1.worldy() + t1.dim.y / 2 > t2.worldy() - t2.dim.y / 2 && t1.worldy() - t1.dim.y / 2 < t2.worldy() + t2.dim.y / 2 &&
			   t1.worldz() + t1.dim.z / 2 > t2.worldz() - t2.dim.z / 2 && t1.worldz() - t1.dim.z / 2 < t2.worldz() + t2.dim.z / 2;
	}

	// Wrong order returned from getEuler(), store last state for animation
	var _eulerX:kha.FastFloat;
	var _eulerY:kha.FastFloat;
	var _eulerZ:kha.FastFloat;

	public inline function look():Vec4 { return world.look(); }
	public inline function right():Vec4 { return world.right(); }
	public inline function up():Vec4 { return world.up(); }

	public inline function worldx():kha.FastFloat { return world._30; }
	public inline function worldy():kha.FastFloat { return world._31; }
	public inline function worldz():kha.FastFloat { return world._32; }

	// Animated delta transform
	public var dloc:Vec4 = null;
	public var drot:Quat = null;
	public var dscale:Vec4 = null;
	var _deulerX:kha.FastFloat;
	var _deulerY:kha.FastFloat;
	var _deulerZ:kha.FastFloat;
}
