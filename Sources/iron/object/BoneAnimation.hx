package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;

class BoneAnimation extends Animation {

	// Skinning
	public var object:MeshObject;
	public var data:MeshData;
	public var skinBuffer:haxe.ds.Vector<kha.FastFloat>;
	public var boneMats = new Map<TObj, Mat4>();
	public var boneTimeIndices = new Map<TObj, Int>();

	var m = Mat4.identity(); // Skinning matrix
	var bm = Mat4.identity(); // Absolute bone matrix
	var pos = new Vec4();
	var nor = new Vec4();

	// Lerp
	static var m1 = Mat4.identity();
	static var vpos = new Vec4();
	static var vscl = new Vec4();
	static var q1 = new Quat();
	static var q2 = new Quat();

	public function new(mo:MeshObject, setup:TAnimationSetup) {
		super(setup);
		this.object = mo;
		this.data = mo.data;
		this.isSkinned = data.isSkinned;
		this.isSampled = false;

		if (this.isSkinned) {
			if (!MeshData.ForceCpuSkinning) {
				this.skinBuffer = new haxe.ds.Vector(setup.max_bones * 8); // Dual quat // * 12 for matrices
				for (i in 0...this.skinBuffer.length) this.skinBuffer[i] = 0;
			}

			for (b in data.geom.skeletonBones) {
				this.boneMats.set(b, Mat4.fromArray(b.transform.values));
				this.boneTimeIndices.set(b, 0);
			}
		}
	}

	public override function update(delta:Float) {
		if (!object.visible || object.culled) return;

#if arm_profile
		Animation.beginProfile();
#end

		super.update(delta);
		if (player.paused) return;

		if (isSkinned) {
			updateBoneAnim();
			updateSkin();
		}

#if arm_profile
		Animation.endProfile();
#end
	}

	function updateBoneAnim() {
		for (b in data.geom.skeletonBones) {
			updateAnimSampled(b.animation, boneMats.get(b), setBoneAnimFrame);
		}
	}

	function setBoneAnimFrame(frame:Int) {
		for (b in data.geom.skeletonBones) {
			var boneAnim = b.animation;
			if (boneAnim != null) {
				var track = boneAnim.tracks[0];
				var m1 = Mat4.fromArray(track.values, frame * 16); // Offset to 4x4 matrix array
				boneMats.set(b, m1);
			}
		}
		updateSkin();
	}

	function updateSkin() {
		if (MeshData.ForceCpuSkinning) updateSkinCpu();
		else updateSkinGpu();
	}

	// Dual quat skinning
	function updateSkinGpu() {
		var bones = data.geom.skeletonBones;

		for (i in 0...bones.length) {
			
			bm.setFrom(data.geom.skinTransform);
			bm.multmat2(data.geom.skeletonTransformsI[i]);
			m.setFrom(boneMats.get(bones[i]));
			var p = bones[i].parent;
			while (p != null) { // TODO: store absolute transforms per bone
				var pm = boneMats.get(p);
				if (pm == null) pm = Mat4.fromArray(p.transform.values);
				m.multmat2(pm);
				p = p.parent;
			}
			bm.multmat2(m);

			// Matrix skinning
			// bm.transpose2();
			// skinBuffer[i * 12] = bm._00;
			// skinBuffer[i * 12 + 1] = bm._01;
			// skinBuffer[i * 12 + 2] = bm._02;
			// skinBuffer[i * 12 + 3] = bm._03;
			// skinBuffer[i * 12 + 4] = bm._10;
			// skinBuffer[i * 12 + 5] = bm._11;
			// skinBuffer[i * 12 + 6] = bm._12;
			// skinBuffer[i * 12 + 7] = bm._13;
			// skinBuffer[i * 12 + 8] = bm._20;
			// skinBuffer[i * 12 + 9] = bm._21;
			// skinBuffer[i * 12 + 10] = bm._22;
			// skinBuffer[i * 12 + 11] = bm._23;

			// Dual quat skinning
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
		// var vdepth = data.geom.vertexBufferDepth.lock();
		// var ldepth = data.geom.structLengthDepth;
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
				var bone = data.geom.skeletonBones[boneIndex];

				// Position
				m.initTranslate(data.geom.positions[i * 3],
								data.geom.positions[i * 3 + 1],
								data.geom.positions[i * 3 + 2]);

				m.multmat2(data.geom.skinTransform);

				m.multmat2(data.geom.skeletonTransformsI[boneIndex]);

				bm.setFrom(boneMats.get(bone));
				var p = bone.parent;
				while (p != null) { // TODO: store absolute transforms per bone
					var pm = boneMats.get(p);
					if (pm == null) pm = Mat4.fromArray(p.transform.values);
					bm.multmat2(pm);
					p = p.parent;
				}
				m.multmat2(bm);

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
			// TODO: use correct vertex structure
			v.set(i * l, pos.x);
			v.set(i * l + 1, pos.y);
			v.set(i * l + 2, pos.z);
			v.set(i * l + 3, nor.x);
			v.set(i * l + 4, nor.y);
			v.set(i * l + 5, nor.z);
			// vdepth.set(i * ldepth, pos.x);
			// vdepth.set(i * ldepth + 1, pos.y);
			// vdepth.set(i * ldepth + 2, pos.z);
#end
		}

#if arm_deinterleaved
		data.geom.vertexBuffers[0].unlock();
		data.geom.vertexBuffers[1].unlock();
#else
		data.geom.vertexBuffer.unlock();
		// data.geom.vertexBufferDepth.unlock();
#end
	}
}
