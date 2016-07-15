package iron.node;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.resource.ModelResource;
import iron.resource.SceneFormat;

class Animation {

	public var resource:ModelResource;
	public var skinBuffer:haxe.ds.Vector<kha.FastFloat>;
	public var player:Player = null;
	// Skinning
	var boneMats = new Map<TNode, Mat4>();
	var boneTimeIndices = new Map<TNode, Int>();
	// Node based
	var node:ModelNode;

	var m = Mat4.identity(); // Skinning matrix
	var bm = Mat4.identity(); // Absolute bone matrix
	var pos = new Vec4();
	var nor = new Vec4();

	public function new(resource:ModelResource) {
		this.resource = resource;
	}

	public function setupBoneAnimation(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>) {
		player = new Player(startTrack, names, starts, ends);

		if (resource.isSkinned) {
			if (!ModelResource.ForceCpuSkinning) {
				skinBuffer = new haxe.ds.Vector(50 * 12);
				for (i in 0...skinBuffer.length) skinBuffer[i] = 0;
			}

			for (b in resource.geometry.skeletonBones) {
				boneMats.set(b, Mat4.fromArray(b.transform.values));
				boneTimeIndices.set(b, 0);
			}
		}
	}

	public function setupNodeAnimation(node:ModelNode, startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>) {
		player = new Player(startTrack, names, starts, ends);
		this.node = node;
	}

	public function setAnimationParams(delta:Float) {
		if (player.paused) return;
    	player.animTime += delta * player.speed;
		
		if (resource.isSkinned) {
			updateBoneAnim();
			updateSkin();
		}
		else {
			updateNodeAnim();
		}
    }

    function updateNodeAnim() {
		updateAnim(node.raw.animation, node.transform.matrix);
    }

    function updateBoneAnim() {
		for (b in resource.geometry.skeletonBones) {
			updateAnim(b.animation, boneMats.get(b));
		}
	}

    function updateAnim(anim:TAnimation, targetMatrix:Mat4) {
    	if (anim != null) {
			var track = anim.tracks[0];

			// Current track has been changed
			if (player.dirty) {
				player.dirty = false;
				// Single frame - set skin and pause
				if (player.current.frames == 0) {
					player.paused = true;
					if (resource.isSkinned) setBoneAnimFrame(player.current.start);
					else setNodeAnimFrame(player.current.start);
					return;
				}
				// Animation - loop frames
				else {
					player.timeIndex = player.current.start;
					player.animTime = track.time.values[player.timeIndex];
				}
			}

			// Move keyframe
			//var timeIndex = boneTimeIndices.get(b);
			while (track.time.values.length > (player.timeIndex + 1) &&
				   player.animTime > track.time.values[player.timeIndex + 1]) {
				player.timeIndex++;
			}
			//boneTimeIndices.set(b, timeIndex);

			// End of track
			if (player.timeIndex >= track.time.values.length - 1 ||
				player.timeIndex >= player.current.end) {

				// Rewind
				if (player.loop) {
					player.dirty = true;
				}
				// Pause
				else {
					player.paused = true;
				}

				// Give chance to change current track
				if (player.onTrackComplete != null) player.onTrackComplete();

				//boneTimeIndices.set(b, player.timeIndex);
				//continue;
				return;
			}

			var t1 = track.time.values[player.timeIndex];
			var t2 = track.time.values[player.timeIndex + 1];
			var s = (player.animTime - t1) / (t2 - t1);

			var v1:Array<Float> = track.value.values[player.timeIndex];
			var v2:Array<Float> = track.value.values[player.timeIndex + 1];

			var m1 = Mat4.fromArray(v1);
			var m2 = Mat4.fromArray(v2);

			// Decompose
			var p1 = m1.pos();
			var p2 = m2.pos();
			var s1 = m1.scaleV();
			var s2 = m2.scaleV();
			var q1 = m1.getQuat();
			var q2 = m2.getQuat();

			// Lerp
			var fp = Vec4.lerp(p1, p2, 1.0 - s);
			// var fp = Vec4.lerp(p1, p2, s);
			var fs = Vec4.lerp(s1, s2, s);
			var fq = Quat.lerp(q1, q2, s);

			// Compose
			var m = targetMatrix;
			fq.saveToMatrix(m);
			m.scale(fs);
			m._30 = fp.x;
			m._31 = fp.y;
			m._32 = fp.z;
			// boneMats.set(b, m);
		}
    }

	function setBoneAnimFrame(frame:Int) {
		for (b in resource.geometry.skeletonBones) {
			var boneAnim = b.animation;
			if (boneAnim != null) {
				var track = boneAnim.tracks[0];
				var v1:Array<Float> = track.value.values[frame];
				var m1 = Mat4.fromArray(v1);
				boneMats.set(b, m1);
			}
		}
		updateSkin();
	}

	function setNodeAnimFrame(frame:Int) {
		var nodeAnim = node.raw.animation;
		if (nodeAnim != null) {
			var track = nodeAnim.tracks[0];
			var v1:Array<Float> = track.value.values[frame];
			var m1 = Mat4.fromArray(v1);
			node.transform.matrix = m1;
		}
	}

	function updateSkin() {
		if (ModelResource.ForceCpuSkinning) updateSkinCpu();
		else updateSkinGpu();
	}

	function updateSkinGpu() {
		var bones = resource.geometry.skeletonBones;
		for (i in 0...bones.length) {
			
			bm.loadFrom(resource.geometry.skinTransform);
			bm.mult2(resource.geometry.skeletonTransformsI[i]);
			var m = Mat4.identity();
			m.loadFrom(boneMats.get(bones[i]));
			var p = bones[i].parent;
			while (p != null) { // TODO: store absolute transforms per bone
				var pm = boneMats.get(p);
				if (pm == null) pm = Mat4.fromArray(p.transform.values);
				m.mult2(pm);
				p = p.parent;
			}
			bm.mult2(m);
			bm.transpose2();

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
		}
	}

	function updateSkinCpu() {
		var v = resource.geometry.vertexBuffer.lock();
		var l = resource.geometry.structureLength;

		var index = 0;

		for (i in 0...Std.int(v.length / l)) {

			var boneCount = resource.geometry.skinBoneCounts[i];
			var boneIndices = [];
			var boneWeights = [];
			for (j in index...(index + boneCount)) {
				boneIndices.push(resource.geometry.skinBoneIndices[j]);
				boneWeights.push(resource.geometry.skinBoneWeights[j]);
			}
			index += boneCount;

			pos.set(0, 0, 0);
			nor.set(0, 0, 0);
			for (j in 0...boneCount) {
				var boneIndex = boneIndices[j];
				var boneWeight = boneWeights[j];
				var bone = resource.geometry.skeletonBones[boneIndex];

				// Position
				m.initTranslate(resource.geometry.positions[i * 3],
								resource.geometry.positions[i * 3 + 1],
								resource.geometry.positions[i * 3 + 2]);

				m.mult2(resource.geometry.skinTransform);

				m.mult2(resource.geometry.skeletonTransformsI[boneIndex]);

				bm.loadFrom(boneMats.get(bone));
				var p = bone.parent;
				while (p != null) { // TODO: store absolute transforms per bone
					var pm = boneMats.get(p);
					if (pm == null) pm = Mat4.fromArray(p.transform.values);
					bm.mult2(pm);
					p = p.parent;
				}
				m.mult2(bm);

				m.multiplyScalar(boneWeight);
				
				pos.add(m.pos());

				// Normal
				m.getInverse(bm);

				m.mult2(resource.geometry.skeletonTransforms[boneIndex]);

				m.mult2(resource.geometry.skinTransformI);

				m.translate(resource.geometry.normals[i * 3],
							resource.geometry.normals[i * 3 + 1],
							resource.geometry.normals[i * 3 + 2]);

				m.multiplyScalar(boneWeight);

				nor.add(m.pos());
			}

			// TODO: use correct vertex structure
			v.set(i * l, pos.x);
			v.set(i * l + 1, pos.y);
			v.set(i * l + 2, pos.z);
			v.set(i * l + 3, nor.x);
			v.set(i * l + 4, nor.y);
			v.set(i * l + 5, nor.z);
		}

		resource.geometry.vertexBuffer.unlock();
	}
}

class Player {

	public var animTime:Float = 0;
	public var timeIndex:Int = 0; // TODO: use boneTimeIndices
	public var dirty:Bool = false;

	public var current:Track;
	var tracks:Map<String, Track> = new Map();

	public var speed:Float = 1.0;
	public var loop:Bool;
	public var onTrackComplete:Void->Void = null;

	public var paused = false;

    public function new(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>) {

        for (i in 0...names.length) {
        	addTrack(names[i], starts[i], ends[i]);
        }

        play(startTrack);
    }

    public function play(name:String, loop = true, speed = 1.0, onTrackComplete:Void->Void = null) {
 		current = tracks.get(name);
 		dirty = true;

 		this.speed = speed;
 		this.loop = loop;
 		this.onTrackComplete = onTrackComplete;

 		paused = false;
    }

    public function pause() {
    	paused = true;
    }

    function addTrack(name:String, start:Int, end:Int) {
    	var t = new Track(start, end);
    	tracks.set(name, t);
    }
}

class Track {
	public var start:Int;
	public var end:Int;
	public var frames:Int;

	public function new(start:Int, end:Int) {
		this.start = start;
		this.end = end;
		frames = end - start;
	}
}
