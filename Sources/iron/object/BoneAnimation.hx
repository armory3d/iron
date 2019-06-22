package iron.object;

#if arm_skin

import kha.FastFloat;
import kha.arrays.Float32Array;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;
import iron.data.Armature;
import iron.data.Data;

class BoneAnimation extends Animation {

	public static var skinMaxBones = 50;

	// Skinning
	public var object:MeshObject;
	public var data:MeshData;
	public var skinBuffer:Float32Array;

	var skeletonBones:Array<TObj> = null;
	var skeletonMats:Array<Mat4> = null;
	var skeletonBonesBlend:Array<TObj> = null;
	var skeletonMatsBlend:Array<Mat4> = null;
	var absMats:Array<Mat4> = null;
	var applyParent:Array<Bool> = null;
	var matsFast:Array<Mat4> = [];
	var matsFastSort:Array<Int> = [];
	var matsFastBlend:Array<Mat4> = [];
	var matsFastBlendSort:Array<Int> = [];

	var boneChildren:Map<String, Array<Object>> = null; // Parented to bone

	var constraintTargets:Array<Object> = null;
	var constraintTargetsI:Array<Mat4> = null;
	var constraintMats:Map<TObj, Mat4> = null;

	static var m = Mat4.identity(); // Skinning matrix
	static var m1 = Mat4.identity();
	static var m2 = Mat4.identity();
	static var bm = Mat4.identity(); // Absolute bone matrix
	static var wm = Mat4.identity();
	static var vpos = new Vec4();
	static var vscl = new Vec4();
	static var q1 = new Quat();
	static var q2 = new Quat();
	static var q3 = new Quat();
	static var vpos2 = new Vec4();
	static var vscl2 = new Vec4();
	static var v1 = new Vec4();
	static var v2 = new Vec4();

	public function new(armatureName = '') {
		super();
		this.isSampled = false;
		for (a in Scene.active.armatures) {
			if (a.name == armatureName) {
				this.armature = a;
				break;
			}
		}
	}

	public function setSkin(mo:MeshObject) {
		this.object = mo;
		this.data = mo != null ? mo.data : null;
		this.isSkinned = data != null ? data.isSkinned : false;
		if (this.isSkinned) {
			var boneSize = 8; // Dual-quat skinning
			this.skinBuffer = new Float32Array(skinMaxBones * boneSize);
			for (i in 0...this.skinBuffer.length) this.skinBuffer[i] = 0;
			// Rotation is already applied to skin at export
			object.transform.rot.set(0, 0, 0, 1);
			object.transform.buildMatrix();

			var refs = mo.parent.raw.bone_actions;
			if (refs != null && refs.length > 0) {
				Data.getSceneRaw(refs[0], function(action:TSceneFormat) { play(action.name); });
			}
		}
	}

	public function addBoneChild(bone:String, o:Object) {
		if (boneChildren == null) boneChildren = new Map();
		var ar:Array<Object> = boneChildren.get(bone);
		if (ar == null) { ar = []; boneChildren.set(bone, ar); }
		ar.push(o);
	}

	@:access(iron.object.Transform)
	function updateBoneChildren(bone:TObj, bm:Mat4) {
		var ar = boneChildren.get(bone.name);
		if (ar == null) return;
		for (o in ar) {
			var t = o.transform;
			if (t.boneParent == null) t.boneParent = Mat4.identity();
			if (o.raw.parent_bone_tail != null) {
				if (o.raw.parent_bone_connected || isSkinned) {
					var v = o.raw.parent_bone_tail;
					t.boneParent.initTranslate(v[0], v[1], v[2]);
					t.boneParent.multmat(bm);
				}
				else {
					var v = o.raw.parent_bone_tail_pose;
					t.boneParent.setFrom(bm);
					t.boneParent.translate(v[0], v[1], v[2]);
				}
			}
			else t.boneParent.setFrom(bm);
			t.buildMatrix();
		}
	}

	function numParents(b:TObj):Int {
		var i = 0;
		var p = b.parent;
		while (p != null) { i++; p = p.parent; }
		return i;
	}

	function setMats() {
		while (matsFast.length < skeletonBones.length) {
			matsFast.push(Mat4.identity());
			matsFastSort.push(matsFastSort.length);
		}
		// Calc bones with 0 parents first
		matsFastSort.sort(function(a, b) {
			var i = numParents(skeletonBones[a]);
			var j = numParents(skeletonBones[b]);
			return i < j ? -1 : i > j ? 1 : 0;
		});

		if (skeletonBonesBlend != null) {
			while (matsFastBlend.length < skeletonBonesBlend.length) {
				matsFastBlend.push(Mat4.identity());
				matsFastBlendSort.push(matsFastBlendSort.length);
			}
			matsFastBlendSort.sort(function(a, b) {
				var i = numParents(skeletonBonesBlend[a]);
				var j = numParents(skeletonBonesBlend[b]);
				return i < j ? -1 : i > j ? 1 : 0;
			});
		}
	}

	function setAction(action:String) {
		if (isSkinned) {
			skeletonBones = data.geom.actions.get(action);
			skeletonMats = data.geom.mats.get(action);
			skeletonBonesBlend = null;
			skeletonMatsBlend = null;
		}
		else {
			armature.initMats();
			var a = armature.getAction(action);
			skeletonBones = a.bones;
			skeletonMats = a.mats;
		}
		setMats();
	}

	function setActionBlend(action:String) {
		if (isSkinned) {
			skeletonBonesBlend = skeletonBones;
			skeletonMatsBlend = skeletonMats;
			skeletonBones = data.geom.actions.get(action);
			skeletonMats = data.geom.mats.get(action);
		}
		else {
			armature.initMats();
			var a = armature.getAction(action);
			skeletonBones = a.bones;
			skeletonMats = a.mats;
		}
		setMats();
	}

	override public function play(action = '', onComplete:Void->Void = null, blendTime = 0.2, speed = 1.0, loop = true) {
		super.play(action, onComplete, blendTime, speed, loop);
		if (action != '') {
			blendTime > 0 ? setActionBlend(action) : setAction(action);
		}
		blendFactor = 0.0;
	}

	override public function blend(action1:String, action2:String, factor:FastFloat) {
		if (factor == 0.0) {
			setAction(action1);
			return;
		}
		setAction(action2);
		setActionBlend(action1);
		super.blend(action1, action2, factor);
	}

	override public function update(delta:FastFloat) {
		if (!isSkinned && skeletonBones == null) setAction(armature.actions[0].name);
		if (object != null && (!object.visible || object.culled)) return;
		if (skeletonBones == null || skeletonBones.length == 0) return;

		#if arm_debug
		Animation.beginProfile();
		#end

		super.update(delta);
		if (paused || speed == 0.0) return;

		var lastBones = skeletonBones;
		for (b in skeletonBones) {
			if (b.anim != null) { updateTrack(b.anim); break; }
		}
		// Action has been changed by onComplete
		if (lastBones != skeletonBones) return;

		for (i in 0...skeletonBones.length) {
			updateAnimSampled(skeletonBones[i].anim, skeletonMats[i]);
		}
		if (blendTime > 0 && skeletonBonesBlend != null) {
			for (b in skeletonBonesBlend) {
				if (b.anim != null) { updateTrack(b.anim); break; }
			}
			for (i in 0...skeletonBonesBlend.length) {
				updateAnimSampled(skeletonBonesBlend[i].anim, skeletonMatsBlend[i]);
			}
		}

		updateConstraints();

		// Do inverse kinematics here
		if (onUpdates != null) for (f in onUpdates) f();

		// Calc absolute bones
		for (i in 0...skeletonBones.length) {
			// Take bones with 0 parents first
			multParent(matsFastSort[i], matsFast, skeletonBones, skeletonMats);
		}
		if (skeletonBonesBlend != null) {
			for (i in 0...skeletonBonesBlend.length) {
				multParent(matsFastBlendSort[i], matsFastBlend, skeletonBonesBlend, skeletonMatsBlend);
			}
		}

		if (isSkinned) updateSkinGpu();
		else updateBonesOnly();

		#if arm_debug
		Animation.endProfile();
		#end
	}

	function multParent(i:Int, fasts:Array<Mat4>, bones:Array<TObj>, mats:Array<Mat4>) {
		var f = fasts[i];
		if (applyParent != null && !applyParent[i]) { f.setFrom(mats[i]); return; }
		var p = bones[i].parent;
		var bi = getBoneIndex(p, bones);
		(p == null || bi == -1) ? f.setFrom(mats[i]) : f.multmats(fasts[bi], mats[i]);
	}

	function multParents(m:Mat4, i:Int, bones:Array<TObj>, mats:Array<Mat4>) {
		var bone = bones[i];
		var p = bone.parent;
		while (p != null) {
			var i = getBoneIndex(p, bones);
			if (i == -1) continue;
			m.multmat(mats[i]);
			p = p.parent;
		}
	}

	function updateConstraints() {
		if (data == null) return;
		var cs = data.raw.skin.constraints;
		if (cs == null) return;
		// Init constraints
		if (constraintTargets == null) {
			constraintTargets = [];
			constraintTargetsI = [];
			for (c in cs) {
				var o = Scene.active.getChild(c.target);
				constraintTargets.push(o);
				var m:Mat4 = null;
				if (o != null) {
					m = Mat4.fromFloat32Array(o.raw.transform.values);
					m.getInverse(m);
				}
				constraintTargetsI.push(m);
			}
			constraintMats = new Map();
		}
		// Update matrices
		for (i in 0...cs.length) {
			var c = cs[i];
			var bone = getBone(c.bone);
			if (bone == null) continue;
			var o = constraintTargets[i];
			if (o == null) continue;
			if (c.type == "CHILD_OF") {
				var m = constraintMats.get(bone);
				if (m == null) { m = Mat4.identity(); constraintMats.set(bone, m); }
				m.setFrom(object.parent.transform.world); // Armature transform
				m.multmat(constraintTargetsI[i]); // Roll back initial hitbox transform
				m.multmat(o.transform.world); // Current hitbox transform
				m1.getInverse(object.parent.transform.world); // Roll back armature transform
				m.multmat(m1);
			}
		}
	}

	// Do inverse kinematics here
	var onUpdates:Array<Void->Void> = null;
	public function notifyOnUpdate(f:Void->Void) {
		if (onUpdates == null) onUpdates = [];
		onUpdates.push(f);
	}

	public function removeUpdate(f:Void->Void) {
		onUpdates.remove(f);
	}

	function updateBonesOnly() {
		if (boneChildren != null) {
			for (i in 0...skeletonBones.length) {
				var b = skeletonBones[i]; // TODO: blendTime > 0
				m.setFrom(matsFast[i]);
				updateBoneChildren(b, m);
			}
		}
	}

	function updateSkinGpu() {
		var bones = skeletonBones;

		var s:FastFloat = blendCurrent / blendTime;
		s = s * s * (3.0 - 2.0 * s); // Smoothstep
		if (blendFactor != 0.0) s = 1.0 - blendFactor;

		// Update skin buffer
		for (i in 0...bones.length) {
			
			if (constraintMats != null) {
				var m = constraintMats.get(bones[i]);
				if (m != null) { updateSkinBuffer(m, i); continue; }
			}

			m.setFrom(matsFast[i]);

			if (blendTime > 0 && skeletonBonesBlend != null) {
				// Decompose
				m1.setFrom(matsFastBlend[i]);
				m1.decompose(vpos, q1, vscl);
				m.decompose(vpos2, q2, vscl2);

				// Lerp
				v1.lerp(vpos, vpos2, s);
				v2.lerp(vscl, vscl2, s);
				q3.lerp(q1, q2, s);

				// Compose
				m.fromQuat(q3);
				m.scale(v2);
				m._30 = v1.x;
				m._31 = v1.y;
				m._32 = v1.z;
			}

			if (absMats != null && i < absMats.length) absMats[i].setFrom(m);
			if (boneChildren != null) updateBoneChildren(bones[i], m);

			m.multmats(m, data.geom.skeletonTransformsI[i]);
			updateSkinBuffer(m, i);
		}
	}

	function updateSkinBuffer(m:Mat4, i:Int) {
		// Dual quat skinning
		m.decompose(vpos, q1, vscl);
		q1.normalize();
		q2.set(vpos.x, vpos.y, vpos.z, 0.0);
		q2.multquats(q2, q1);
		skinBuffer[i * 8] = q1.x; // Real
		skinBuffer[i * 8 + 1] = q1.y;
		skinBuffer[i * 8 + 2] = q1.z;
		skinBuffer[i * 8 + 3] = q1.w;
		skinBuffer[i * 8 + 4] = q2.x * 0.5; // Dual
		skinBuffer[i * 8 + 5] = q2.y * 0.5;
		skinBuffer[i * 8 + 6] = q2.z * 0.5;
		skinBuffer[i * 8 + 7] = q2.w * 0.5;
	}

	public override function totalFrames():Int { 
		if (skeletonBones == null) return 0;
		var track = skeletonBones[0].anim.tracks[0];
		return Std.int(track.frames[track.frames.length - 1] - track.frames[0]);
	}

	public function getBone(name:String):TObj {
		if (skeletonBones == null) return null;
		for (b in skeletonBones) if (b.name == name) return b;
		return null;
	}

	function getBoneIndex(bone:TObj, bones:Array<TObj> = null):Int {
		if (bones == null) bones = skeletonBones;
		if (bones != null) for (i in 0...bones.length) if (bones[i] == bone) return i;
		return -1;
	}

	public function getBoneMat(bone:TObj):Mat4 {
		return skeletonMats != null ? skeletonMats[getBoneIndex(bone)] : null;
	}

	public function getBoneMatBlend(bone:TObj):Mat4 {
		return skeletonMatsBlend != null ? skeletonMatsBlend[getBoneIndex(bone)] : null;
	}

	public function getAbsMat(bone:TObj):Mat4 {
		// With applied blending
		if (skeletonMats == null) return null;
		if (absMats == null) {
			absMats = [];
			while (absMats.length < skeletonMats.length) absMats.push(Mat4.identity());
		}
		return absMats[getBoneIndex(bone)];
	}

	public function getWorldMat(bone:TObj):Mat4 {
		if (skeletonMats == null) return null;
		if (applyParent == null) { applyParent = []; for (m in skeletonMats) applyParent.push(true); }
		var i = getBoneIndex(bone);
		wm.setFrom(skeletonMats[i]);
		multParents(wm, i, skeletonBones, skeletonMats);
		// wm.setFrom(matsFast[i]); // TODO
		return wm;
	}

	public function getBoneLen(bone:TObj):FastFloat {
		var refs = data.geom.skeletonBoneRefs;
		var lens = data.geom.skeletonBoneLens;
		for (i in 0...refs.length) if (refs[i] == bone.name) return lens[i];
		return 0.0;
	}

	public function solveIK(effector:TObj, goal:Vec4, precission = 0.1, maxIterations = 6) {
		// FABRIK - Forward and backward reaching inverse kinematics solver
		var bones:Array<TObj> = [];
		var lengths:Array<FastFloat> = [];
		var start = effector;
		while (start.parent != null) {
			bones.push(start);
			lengths.push(getBoneLen(start));
			start = start.parent;
		}
		start = bones[bones.length - 1];

		// Distance to goal
		var armsc = object.parent.transform.scale; // Transform goal to armature space
		goal.x *= 1 / armsc.x; goal.y *= 1 / armsc.y; goal.z *= 1 / armsc.z;
		var startLoc = getWorldMat(start).getLoc();
		startLoc.z -= getBoneLen(start.parent); // Fix this
		var dist = Vec4.distance(goal, startLoc);

		// Bones length
		var x:FastFloat = 0.0;
		for (l in lengths) x += l;

		v1.set(0, 1, 0);

		// Unreachable distance
		if (dist > x) {
			// Point to goal
			var m = getBoneMat(start);
			var w = getWorldMat(start);
			var iw = Mat4.identity();
			iw.getInverse(w);

			m.setFrom(w);
			m.decompose(vpos, q1, vscl);
			v2.setFrom(goal).sub(startLoc).normalize();
			q1.fromTo(v1, v2);
			m.compose(vpos, q1, vscl);
			m.multmat(iw);
			
			for (i in 0...bones.length - 1) {
				// Cancel child bone rotation
				var b = bones[i];
				var m = skeletonMats[getBoneIndex(b)];
				m.decompose(vpos, q1, vscl);
				m.compose(vpos, new Quat(), vscl);
			}

			// Restore apply parent
			for (b in bones) applyParent[getBoneIndex(b)] = true;

			return;
		}

		// Solve IK
		var vec = new Vec4();
		var locs:Array<Vec4> = [];
		for (b in bones) locs.push(getWorldMat(b).getLoc());

		for (i in 0...maxIterations) {
			// Backward
			vec.setFrom(goal);
			vec.sub(locs[0]);
			vec.normalize();
			vec.mult(lengths[0]);
			locs[0].setFrom(goal);
			locs[0].sub(vec);
			for (j in 1...locs.length) {
				vec.setFrom(locs[j]);
				vec.sub(locs[j - 1]);
				vec.normalize();
				vec.mult(lengths[j]);
				locs[j].setFrom(locs[j - 1]);
				locs[j].add(vec);
			}
			// Forward 
			locs[locs.length - 1].setFrom(startLoc);
			var l = locs.length;
			for (j in 1...l) {
				vec.setFrom(locs[l - j - 1]);
				vec.sub(locs[l - j]);
				vec.normalize();
				vec.mult(lengths[l - j]);
				locs[l - j - 1].setFrom(locs[l - j]);
				locs[l - j - 1].add(vec);
			}
			if (Vec4.distance(locs[0], goal) <= precission) break;
		}

		for (b in bones) applyParent[getBoneIndex(b)] = false;

		for (i in 0...bones.length) {
			var m = getBoneMat(bones[i]);
			m.decompose(vpos, q1, vscl);
			var l1 = i == 0 ? locs[i] : locs[i - 1];
			var l2 = i == 0 ? locs[i + 1] : locs[i];
			v2.setFrom(l1).sub(l2).normalize();
			q1.fromTo(v1, v2);
			vec.setFrom(locs[i]);
			m.compose(vec, q1, vscl);
		}
	}
}

#end
