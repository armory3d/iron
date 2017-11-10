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
	var skeletonMats:Map<TObj, Mat4> = null;
	var skeletonBonesBlend:Array<TObj> = null;
	var skeletonMatsBlend:Map<TObj, Mat4> = null;

	var boneChildren:Map<String, Array<Object>> = null; // Parented to bone

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
			if (!MeshData.ForceCpuSkinning) {
				this.skinBuffer = new haxe.ds.Vector(skinMaxBones * 8); // Dual quat // * 12 for matrices
				for (i in 0...this.skinBuffer.length) this.skinBuffer[i] = 0;
			}
			var refs = mo.parent.raw.bone_actions;
			if (refs != null && refs.length > 0) {
				iron.data.Data.getSceneRaw(refs[0], function(action:TSceneFormat) { play(action.name); });
			}
		}
	}

	public function addBoneChild(bone:String, mo:MeshObject) {
		if (boneChildren == null) boneChildren = new Map();
		var ar:Array<Object> = boneChildren.get(bone);
		if (ar == null) { ar = []; boneChildren.set(bone, ar); }
		ar.push(mo);
	}

	function updateBoneChildren(bone:TObj, bm:Mat4) {
		var ar = boneChildren.get(bone.name);
		if (ar == null) return;
		for (o in ar) {
			var t = o.transform;
			if (t.boneParent == null) t.boneParent = Mat4.identity();
			if (o.raw.parent_bone_tail != null) {
				var v = o.raw.parent_bone_tail;
				t.boneParent.initTranslate(v[0], v[1], v[2]);
			}
			else {
				t.boneParent.setIdentity();
			}
			t.boneParent.multmat2(bm);
			t.buildMatrix();
		}
	}

	function setAction(action:String) {
		if (isSkinned) {
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

	override public function play(action = '', onComplete:Void->Void = null, blendTime = 0.0, animSpeed = 1.0) {
		super.play(action, onComplete, blendTime, animSpeed);
		if (action != '') {
			blendTime > 0 ? setActionBlend(action) : setAction(action);
		}
	}

	override public function update(delta:Float) {
		if (!isSkinned && skeletonBones == null) setAction(armature.actions[0].name);
		if (object != null && (!object.visible || object.culled)) return;
		if (skeletonBones == null || skeletonBones.length == 0) return;

		#if arm_profile
		Animation.beginProfile();
		#end

		super.update(delta);
		if (paused) return;

		updateAnim();

		#if arm_profile
		Animation.endProfile();
		#end
	}

	function updateAnim() {
		for (b in skeletonBones) {
			if (b.anim != null) { updateTrack(b.anim); break; }
		}
		for (b in skeletonBones) {
			updateAnimSampled(b.anim, skeletonMats.get(b));
		}
		if (blendTime > 0) {
			for (b in skeletonBonesBlend) {
				if (b.anim != null) { updateTrack(b.anim); break; }
			}
			for (b in skeletonBonesBlend) {
				updateAnimSampled(b.anim, skeletonMatsBlend.get(b));
			}
		}

		if (isSkinned) MeshData.ForceCpuSkinning ? updateSkinCpu() : updateSkinGpu();
		else updateBonesOnly();
	}

	function updateBonesOnly() {
		for (b in skeletonBones) {
			// TODO: blendTime > 0
			m.setFrom(skeletonMats.get(b));
			applyParent(m, b, skeletonMats);
			if (boneChildren != null) updateBoneChildren(b, m);
		}
	}

	function applyParent(m:Mat4, bone:TObj, mats:Map<TObj, Mat4>) {
		var p = bone.parent;
		while (p != null) { // TODO: store absolute transforms per bone
			var pm = mats.get(p);
			if (pm == null) {
				pm = Mat4.fromFloat32Array(p.transform.values);
				mats.set(p, pm);
			}
			m.multmat2(pm);
			p = p.parent;
		}
	}

	// Dual quat skinning
	function updateSkinGpu() {
		var bones = skeletonBones;

		var s = blendCurrent / blendTime;
		s = s * s * (3.0 - 2.0 * s); // Smoothstep

		for (i in 0...bones.length) {
			
			bm.setFrom(data.geom.skinTransform);
			bm.multmat2(data.geom.skeletonTransformsI[i]);
			if (blendTime > 0) {
				var bonesBlend = skeletonBonesBlend;
				// Decompose
				m1.setFrom(skeletonMatsBlend.get(bonesBlend[i]));
				applyParent(m1, bonesBlend[i], skeletonMatsBlend);

				m2.setFrom(skeletonMats.get(bones[i]));
				applyParent(m2, bones[i], skeletonMats);

				m1.decompose(vpos, q1, vscl);
				m2.decompose(vpos2, q2,vscl2);

				// Lerp
				var fp = Vec4.lerp(vpos, vpos2, 1.0 - s);
				var fs = Vec4.lerp(vscl, vscl2, 1.0 - s);
				var fq = Quat.lerp(q1, q2, s);

				// Compose
				fq.toMat(m);
				m.scale(fs);
				m._30 = fp.x;
				m._31 = fp.y;
				m._32 = fp.z;
			}
			else {
				m.setFrom(skeletonMats.get(bones[i]));
				applyParent(m, bones[i], skeletonMats);
			}
			bm.multmat2(m);

			if (boneChildren != null) updateBoneChildren(bones[i], m);

			#if arm_skin_mat // Matrix skinning
			
			bm.transpose();
			skinBuffer[i * 12] = bm._00;
			skinBuffer[i * 12 + 1] = bm._01;
			skinBuffer[i * 12 + 2] = bm._02;
			skinBuffer[i * 12 + 3] = bm._03;
			skinBuffer[i * 12 + 4] = bm._10;
			skinBuffer[i * 12 + 5] = bm._11;
			skinBuffer[i * 12 + 6] = bm._12;
			skinBuffer[i * 12 + 7] = bm._13;
			skinBuffer[i * 12 + 8] = bm._20;
			skinBuffer[i * 12 + 9] = bm._21;
			skinBuffer[i * 12 + 10] = bm._22;
			skinBuffer[i * 12 + 11] = bm._23;
			
			#else // Dual quat skinning
			
			bm.decompose(vpos, q1, vscl);
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
	}

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

				bm.setFrom(skeletonMats.get(bone));
				applyParent(bm, bone, skeletonMats);
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
}
