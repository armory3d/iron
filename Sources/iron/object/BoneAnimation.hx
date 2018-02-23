package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;
import iron.data.Armature;

class BoneAnimation extends Animation {

	public static var skinMaxBones = 50;

	// Skinning
	public var object:MeshObject;
	public var data:MeshData;
	public var skinBuffer:haxe.ds.Vector<kha.FastFloat>;
	// public var boneTimeIndices = new Map<TObj, Int>();

	var skeletonBones:Array<TObj> = null;
	var skeletonMats:Array<Mat4> = null;
	var absMats:Array<Mat4> = null;
	var skeletonBonesBlend:Array<TObj> = null;
	var skeletonMatsBlend:Array<Mat4> = null;

	var boneChildren:Map<String, Array<Object>> = null; // Parented to bone

	var constraintTargets:Array<Object> = null;
	var constraintTargetsI:Array<Mat4> = null;
	var constraintMats:Map<TObj, Mat4> = null;

	var m = Mat4.identity(); // Skinning matrix
	var m1 = Mat4.identity(); // Skinning matrix
	var m2 = Mat4.identity(); // Skinning matrix
	var bm = Mat4.identity(); // Absolute bone matrix
	var pos = new Vec4();
	var nor = new Vec4();

	// Lerp
	static var vpos = new Vec4();
	static var vscl = new Vec4();
	static var q1 = new Quat();
	static var q2 = new Quat();
	static var vpos2 = new Vec4();
	static var vscl2 = new Vec4();

	public function new(armatureName = '') {
		super();
		this.isSampled = false;
		for (a in iron.Scene.active.armatures) {
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
			#if (!arm_skin_cpu)
				#if arm_skin_mat
				var boneSize = 12; // Matrix skinning
				#else
				var boneSize = 8; // Dual-quat skinning
				#end
				this.skinBuffer = new haxe.ds.Vector(skinMaxBones * boneSize);
				for (i in 0...this.skinBuffer.length) this.skinBuffer[i] = 0;
				// Rotation is already applied to skin at export
				object.transform.rot.set(0, 0, 0, 1);
				object.transform.buildMatrix();
			#end
			var refs = mo.parent.raw.bone_actions;
			if (refs != null && refs.length > 0) {
				iron.data.Data.getSceneRaw(refs[0], function(action:TSceneFormat) { play(action.name); });
			}
		}
	}

	public function addBoneChild(bone:String, o:Object) {
		if (boneChildren == null) boneChildren = new Map();
		var ar:Array<Object> = boneChildren.get(bone);
		if (ar == null) { ar = []; boneChildren.set(bone, ar); }
		ar.push(o);
	}

	function updateBoneChildren(bone:TObj, bm:Mat4) {
		var ar = boneChildren.get(bone.name);
		if (ar == null) return;
		for (o in ar) {
			var t = o.transform;
			if (t.boneParent == null) t.boneParent = Mat4.identity();
			if (o.raw.parent_bone_tail != null) { // && !isSkinned) {
				var v = o.raw.parent_bone_tail;
				t.boneParent.initTranslate(v[0], v[1], v[2]);
				t.boneParent.multmat2(bm);
			}
			else t.boneParent.setFrom(bm);
			t.buildMatrix();
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
	}

	override public function play(action = '', onComplete:Void->Void = null, blendTime = 0.2, speed = 1.0, loop = true) {
		super.play(action, onComplete, blendTime, speed, loop);
		if (action != '') {
			blendTime > 0 ? setActionBlend(action) : setAction(action);
		}
	}

	override public function update(delta:Float) {
		if (!isSkinned && skeletonBones == null) setAction(armature.actions[0].name);
		if (object != null && (!object.visible || object.culled)) return;
		if (skeletonBones == null || skeletonBones.length == 0) return;

		#if arm_debug
		Animation.beginProfile();
		#end

		super.update(delta);
		if (paused) return;

		updateAnim();

		#if arm_debug
		Animation.endProfile();
		#end
	}

	function updateAnim() {
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
		if (onUpdate != null) onUpdate();

		if (isSkinned) {
			#if arm_skin_cpu
			updateSkinCpu();
			#else
			updateSkinGpu();
			#end
		}
		else updateBonesOnly();
	}

	function updateConstraints() {
		var cs = data.raw.skin.constraints;
		if (cs == null) return;
		// Init constraints
		if (constraintTargets == null) {
			constraintTargets = [];
			constraintTargetsI = [];
			for (c in cs) {
				var o = iron.Scene.active.getChild(c.target);
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
				m.multmat2(constraintTargetsI[i]); // Roll back initial hitbox transform
				m.multmat2(o.transform.world); // Current hitbox transform
				m1.getInverse(object.parent.transform.world); // Roll back armature transform
				m.multmat2(m1);
			}
		}
	}

	// Do inverse kinematics here
	var onUpdate:Void->Void = null;
	public function notifyOnUpdate(f:Void->Void) {
		onUpdate = f;
	}

	function updateBonesOnly() {
		for (i in 0...skeletonBones.length) {
			// TODO: blendTime > 0
			var b = skeletonBones[i];
			m.setFrom(skeletonMats[i]);
			applyParent(m, b, skeletonMats, skeletonBones);
			if (boneChildren != null) updateBoneChildren(b, m);
		}
	}

	function applyParent(m:Mat4, bone:TObj, mats:Array<Mat4>, bones:Array<TObj>) {
		var p = bone.parent;
		while (p != null) { // TODO: store absolute transforms per bone
			var boneIndex = getBoneIndex(p, bones);
			if (boneIndex == -1) continue;
			var pm = mats[boneIndex];
			m.multmat2(pm);
			p = p.parent;
		}
	}

	// Dual quat skinning
	#if (!arm_skin_cpu)
	function updateSkinGpu() {
		var bones = skeletonBones;

		var s = blendCurrent / blendTime;
		s = s * s * (3.0 - 2.0 * s); // Smoothstep

		for (i in 0...bones.length) {
			
			if (constraintMats != null) {
				var m = constraintMats.get(bones[i]);
				if (m != null) { updateSkinBuffer(m, i); continue; }
			}

			if (blendTime > 0 && skeletonBonesBlend != null) {
				var bonesBlend = skeletonBonesBlend;
				// Decompose
				m1.setFrom(skeletonMatsBlend[i]);
				applyParent(m1, bonesBlend[i], skeletonMatsBlend, skeletonBonesBlend);

				m2.setFrom(skeletonMats[i]);
				applyParent(m2, bones[i], skeletonMats, skeletonBones);

				m1.decompose(vpos, q1, vscl);
				m2.decompose(vpos2, q2, vscl2);

				// Lerp
				var fp = Vec4.lerp(vpos, vpos2, 1.0 - s);
				var fs = Vec4.lerp(vscl, vscl2, 1.0 - s);
				var fq = Quat.lerp(q1, q2, s);

				// Compose
				fq.toMat(m1);
				m1.scale(fs);
				m1._30 = fp.x;
				m1._31 = fp.y;
				m1._32 = fp.z;
				m.setFrom(m1);
			}
			else {
				m.setFrom(skeletonMats[i]);
				applyParent(m, bones[i], skeletonMats, skeletonBones);
			}

			if (absMats != null && i < absMats.length) absMats[i].setFrom(m);

			if (boneChildren != null) updateBoneChildren(bones[i], m);

			m.multmats(m, data.geom.skeletonTransformsI[i]);

			updateSkinBuffer(m, i);
		}
	}

	function updateSkinBuffer(m:Mat4, i:Int) {
		#if arm_skin_mat // Matrix skinning
		
		m.transpose();
		skinBuffer[i * 12] = m._00;
		skinBuffer[i * 12 + 1] = m._01;
		skinBuffer[i * 12 + 2] = m._02;
		skinBuffer[i * 12 + 3] = m._03;
		skinBuffer[i * 12 + 4] = m._10;
		skinBuffer[i * 12 + 5] = m._11;
		skinBuffer[i * 12 + 6] = m._12;
		skinBuffer[i * 12 + 7] = m._13;
		skinBuffer[i * 12 + 8] = m._20;
		skinBuffer[i * 12 + 9] = m._21;
		skinBuffer[i * 12 + 10] = m._22;
		skinBuffer[i * 12 + 11] = m._23;
		
		#else // Dual quat skinning
		
		m.decompose(vpos, q1, vscl);
		q1.normalize();
		q2.set(vpos.x, vpos.y, vpos.z, 0.0);
		q2.multquats(q2, q1);
		q2.x *= 0.5; q2.y *= 0.5; q2.z *= 0.5; q2.w *= 0.5;
		// q1.set(0, 0, 0, 1); // No skin
		// q2.set(0, 0, 0, 1);
		skinBuffer[i * 8] = q1.x; // Real
		skinBuffer[i * 8 + 1] = q1.y;
		skinBuffer[i * 8 + 2] = q1.z;
		skinBuffer[i * 8 + 3] = q1.w;
		skinBuffer[i * 8 + 4] = q2.x; // Dual
		skinBuffer[i * 8 + 5] = q2.y;
		skinBuffer[i * 8 + 6] = q2.z;
		skinBuffer[i * 8 + 7] = q2.w;
		
		#end
	}
	#end

	#if arm_skin_cpu
	function updateSkinCpu() {
		#if arm_deinterleaved
		// Assume position=0, normal=1 storage
		var v = data.geom.vertexBuffers[0].lock();
		var vnor = data.geom.vertexBuffers[1].lock();
		var l = 3;
		#else
		var v = data.geom.vertexBuffer.lock();
		var l = data.geom.structLength;
		#end

		var index = 0;

		for (i in 0...Std.int(v.length / l)) {

			var boneCount = data.geom.skinBoneCounts[i];
			var boneIndices = [];
			var boneWeights = [];
			for (j in index...(index + boneCount)) {
				boneIndices.push(data.geom.skinBoneIndices[j]);
				boneWeights.push(data.geom.skinBoneWeights[j]);
			}
			index += boneCount;

			pos.set(0, 0, 0);
			nor.set(0, 0, 0);
			for (j in 0...boneCount) {
				var boneIndex = boneIndices[j];
				var boneWeight = boneWeights[j];
				var bone = skeletonBones[boneIndex];

				// Position
				m.initTranslate(data.geom.positions[i * 3],
								data.geom.positions[i * 3 + 1],
								data.geom.positions[i * 3 + 2]);

				m.multmat2(data.geom.skinTransform);

				m.multmat2(data.geom.skeletonTransformsI[boneIndex]);

				bm.setFrom(skeletonMats[boneIndex]);
				applyParent(bm, bone, skeletonMats, skeletonBones);
				m.multmat2(bm);

				if (boneChildren != null) updateBoneChildren(bone, bm);

				m.mult(boneWeight);
				
				pos.add(m.getLoc());

				// Normal
				m.getInverse(bm);

				m.multmat2(data.geom.skeletonTransforms[boneIndex]);

				m.multmat2(data.geom.skinTransformI);

				m.translate(data.geom.normals[i * 3],
							data.geom.normals[i * 3 + 1],
							data.geom.normals[i * 3 + 2]);

				m.mult(boneWeight);

				nor.add(m.getLoc());
			}

			#if arm_deinterleaved
			v.set(i * l, pos.x);
			v.set(i * l + 1, pos.y);
			v.set(i * l + 2, pos.z);
			vnor.set(i * l, nor.x);
			vnor.set(i * l + 1, nor.y);
			vnor.set(i * l + 2, nor.z);
			#else
			v.set(i * l, pos.x);
			v.set(i * l + 1, pos.y);
			v.set(i * l + 2, pos.z);
			v.set(i * l + 3, nor.x);
			v.set(i * l + 4, nor.y);
			v.set(i * l + 5, nor.z);
			#end
		}

		#if arm_deinterleaved
		data.geom.vertexBuffers[0].unlock();
		data.geom.vertexBuffers[1].unlock();
		#else
		data.geom.vertexBuffer.unlock();
		#end
	}
	#end

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
		if (bones == null) return -1;
		for (i in 0...bones.length) if (bones[i] == bone) return i;
		return -1;
	}

	public function getBoneMat(bone:TObj):Mat4 {
		return skeletonMats != null ? skeletonMats[getBoneIndex(bone)] : null;
	}

	public function getBoneMatBlend(bone:TObj):Mat4 {
		return skeletonMatsBlend != null ? skeletonMatsBlend[getBoneIndex(bone)] : null;
	}

	public function getAbsMat(bone:TObj):Mat4 {
		if (skeletonMats == null) return null;
		if (absMats == null) {
			absMats = [];
			while (absMats.length < skeletonMats.length) absMats.push(Mat4.identity());
		}
		return absMats[getBoneIndex(bone)];
	}

	static var v1 = new Vec4();
	static var v2 = new Vec4();
	function boneLoc(bone:TObj):Vec4 {
		var sc = object.parent.transform.scale; // Armature scale
		var m = getBoneMat(bone);
		v1.set(m._30 * sc.x, m._31 * sc.y, m._32 * sc.z);
		return v1;
	}

	function boneDist(bone1:TObj, bone2:TObj):Float {
		var sc = object.parent.transform.scale; // Armature scale
		var m = getBoneMat(bone1);
		v1.set(m._30 * sc.x, m._31 * sc.y, m._32 * sc.z);
		m = getBoneMat(bone2);
		v2.set(m._30 * sc.x, m._31 * sc.y, m._32 * sc.z);
		return Vec4.distance(v1, v2);
	}

	public function solveIK(effector:TObj, goal:Vec4, precission = 1.0, maxIterations = 10) {
		// FABRIK - Forward and backward reaching inverse kinematics solver
		var bones:Array<TObj> = [];
		var lengths:Array<Float> = [];
		var startLocs:Array<Vec4> = [];
		var prevLocs:Array<Vec4> = [];

		// Traverse bone tree
		var start = effector;
		while (start.parent != null) {
			bones.push(start);
			lengths.push(boneDist(start, start.parent));
			start = start.parent;
		}

		// Distance to goal
		var v = boneLoc(start);
		var dist = Vec4.distance(goal, v);

		// Bones length
		var x = 0.0;
		for (l in lengths) x += l;

		// Unreachable distance
		if (dist > x) {
			// Direction to goal
			var b = bones[bones.length - 1];
			var m = skeletonMats[getBoneIndex(b)];
			var q = new Quat();
			var loc = new Vec4(0, 0, 0);
			var rot = new Quat();
			var sc = new Vec4(1, 1, 1);
			m.decompose(loc, q, sc);

			// var a1 = getAbsMat(b);
			// m1.getInverse(a1);

			// var vv = new Vec4();
			// vv.setFrom(goal);
			// vv.sub(v);
			// q.fromTo(m1.look(), vv);

			q.fromTo(v, goal);

			m.compose(loc, q, sc);

			// m.multmat2(m1);
			
			for (i in 0...bones.length - 1) {
				// Cancel child bone rotation
				var b = bones[i];
				var m = skeletonMats[getBoneIndex(b)];
				m.decompose(loc, q, sc);
				m.compose(loc, new Quat(), sc);
			}
			return;
		}


	}
}
