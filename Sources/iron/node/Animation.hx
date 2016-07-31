package iron.node;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.resource.ModelResource;
import iron.resource.SceneFormat;

class Animation {

	public var player:Player = null;

	// Skinning
	public var resource:ModelResource;
	public var isSkinned:Bool;
	public var isSampled:Bool;
	public var skinBuffer:haxe.ds.Vector<kha.FastFloat>;
	public var boneMats = new Map<TNode, Mat4>();
	public var boneTimeIndices = new Map<TNode, Int>();

	var m = Mat4.identity(); // Skinning matrix
	var bm = Mat4.identity(); // Absolute bone matrix
	var pos = new Vec4();
	var nor = new Vec4();

	// Node based
	public var node:Node;

	function new(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
		player = new Player(startTrack, names, starts, ends, speeds, loops, reflects);
	}

	public static function setupBoneAnimation(resource:ModelResource, startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
		var anim = new Animation(startTrack, names, starts, ends, speeds, loops, reflects);
		anim.resource = resource;
		anim.isSkinned = resource.isSkinned;
		anim.isSampled = false;

		if (anim.isSkinned) {
			if (!ModelResource.ForceCpuSkinning) {
				anim.skinBuffer = new haxe.ds.Vector(50 * 12);
				for (i in 0...anim.skinBuffer.length) anim.skinBuffer[i] = 0;
			}

			for (b in resource.geometry.skeletonBones) {
				anim.boneMats.set(b, Mat4.fromArray(b.transform.values));
				anim.boneTimeIndices.set(b, 0);
			}
		}
		return anim;
	}

	static function parseAnimationTransforms(t:Transform, animation_transforms:Array<TAnimationTransform>) {
		for (at in animation_transforms) {
			switch (at.type) {
			case "translation": t.pos.set(at.values[0], at.values[1], at.values[2]);
			case "translation_x": t.pos.x = at.value;
			case "translation_y": t.pos.y = at.value;
			case "translation_z": t.pos.z = at.value;
			case "rotation": t.setRotation(at.values[0], at.values[1], at.values[2]);
			case "rotation_x": t.setRotation(at.value, 0, 0);
			case "rotation_y": t.setRotation(0, at.value, 0);
			case "rotation_z": t.setRotation(0, 0, at.value);
			case "scale": t.scale.set(at.values[0], at.values[1], at.values[2]);
			case "scale_x": t.scale.x = at.value;
			case "scale_y": t.scale.x = at.value;
			case "scale_z": t.scale.x = at.value;
			}
		}
		t.buildMatrix();
	}

	public static function setupNodeAnimation(node:Node, startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
		var anim = new Animation(startTrack, names, starts, ends, speeds, loops, reflects);
		anim.isSkinned = false;
		anim.node = node;

		// Check animation_transforms to determine non-sampled animation
		if (node.raw.animation_transforms != null) {
			anim.isSampled = false;
			parseAnimationTransforms(node.transform, node.raw.animation_transforms);
		}
		else {
			anim.isSampled = true;
		}

		return anim;
	}

	public function setAnimationParams(delta:Float) {
		if (player.paused) return;

    	player.animTime += delta * player.speed * player.dir;

		if (isSkinned) {
			updateBoneAnim();
			updateSkin();
		}
		else {
			updateNodeAnim();
		}
    }

    function updateNodeAnim() {
		if (isSampled) {
			updateAnimSampled(node.raw.animation, node.transform.matrix);

			// Decompose manually on every update for now
			node.transform.matrix.decompose(node.transform.pos, node.transform.rot, node.transform.scale);
		}
		else {
			updateAnimNonSampled(node.raw.animation, node.transform);

			node.transform.buildMatrix();
		}
    }

    function updateBoneAnim() {
		for (b in resource.geometry.skeletonBones) {
			updateAnimSampled(b.animation, boneMats.get(b));
		}
	}

	inline function interpolateLinear(t:Float, t1:Float, t2:Float):Float {
		return (t - t1) / (t2 - t1);
	}
	inline function interpolateBezier(t:Float, t1:Float, t2:Float) {
		// TODO: proper interpolation
		var k = interpolateLinear(t, t1, t2);
		return k == 1 ? 1 : (1 - Math.pow(2, -10 * k));
	}
	inline function interpolateTcb() {}

	function updateAnimNonSampled(anim:TAnimation, transform:Transform) {
		if (anim == null) return;
		
		var begin = anim.begin;
		var end = anim.end;
		var total = end - begin;

		for (track in anim.tracks) {

			// No data for this track at current time
			if (player.timeIndex >= track.time.values.length) continue;

			// End of track
			if (player.animTime > total || player.animTime < 0) {
				if (!player.current.loop) {
					player.paused = true;
					return;
				}

				if (player.current.reflect) player.dir *= -1; // Reflect
				
				player.animTime = player.dir > 0 ? 0 : total; // Rewind
				player.timeIndex = player.dir > 0 ? 0 : track.time.values.length - 1;
			}

			// End of current time range
			var t = player.animTime + begin;
			if (player.dir > 0) {
				while (player.timeIndex < track.time.values.length - 2 && t > track.time.values[player.timeIndex + 1]) {
					player.timeIndex++;
				}
			}
			// Reversed
			else {
				while (player.timeIndex > 1 && t < track.time.values[player.timeIndex - 1]) {
					player.timeIndex--;
				}
			}

			var ti = player.timeIndex;
			var t1 = track.time.values[ti];
			var t2 = track.time.values[ti + 1 * player.dir];
			var interpolate = interpolateLinear;
			switch (track.curve) {
			case "linear": interpolate = interpolateLinear;
			case "bezier": interpolate = interpolateBezier;
			// case "tcb": interpolate = interpolateTcb;
			}
			var s = player.dir > 0 ? interpolate(t, t1, t2) : interpolate(t, t2, t1);
			var v1 = track.value.values[ti];
			var v2 = track.value.values[ti + 1 * player.dir];
			var invs = 1.0 - s;
			var v = player.dir > 0 ? v1 * invs + v2 * s : v1 * s + v2 * invs;

			switch (track.target) {
			case "xpos": transform.pos.x = v;
			case "ypos": transform.pos.y = v;
			case "zpos": transform.pos.z = v;
			case "xrot": transform.setRotation(v, 0, 0);
			case "yrot": transform.setRotation(0, v, 0);
			case "zrot": transform.setRotation(0, 0, v);
			case "xscl": transform.scale.x = v;
			case "yscl": transform.scale.y = v;
			case "zscl": transform.scale.z = v;
			}
		}
	}

	inline function checkTimeIndex(player:Player, timeValues:Array<Float>):Bool {
		if (player.dir > 0) {
			return ((player.timeIndex + 1) < timeValues.length && player.animTime > timeValues[player.timeIndex + 1]);
		}
		else {
			return ((player.timeIndex - 1) > 0 && player.animTime < timeValues[player.timeIndex - 1]);
		}
	}

	inline function checkTrackEnd(player:Player, track:TTrack):Bool {
		if (player.dir > 0) {
			return (player.timeIndex >= track.time.values.length - 1 || player.timeIndex >= player.current.end);
		}
		else {
			return (player.timeIndex <= 1 || player.timeIndex <= player.current.start);
		}
	}

    function updateAnimSampled(anim:TAnimation, targetMatrix:Mat4) {
    	if (anim == null) return;
		var track = anim.tracks[0];

		// Current track has been changed
		if (player.dirty) {
			player.dirty = false;
			// Single frame - set skin and pause
			if (player.current.frames == 0) {
				player.paused = true;
				if (isSkinned) setBoneAnimFrame(player.current.start);
				else setNodeAnimFrame(player.current.start);
				return;
			}
			// Animation - loop frames
			else {
				if (player.current.reflect) player.dir *= -1;

				player.timeIndex = player.dir > 0 ? player.current.start : player.current.end;
				player.animTime = track.time.values[player.timeIndex];
			}
		}

		// Move keyframe
		//var timeIndex = boneTimeIndices.get(b);
		while (checkTimeIndex(player, track.time.values)) {
			player.timeIndex += 1 * player.dir;
		}
		// Safe check, remove
		if (player.timeIndex >= track.time.values.length) player.timeIndex = track.time.values.length - 1;
		//boneTimeIndices.set(b, timeIndex);

		// End of track
		if (checkTrackEnd(player, track)) {
			if (player.current.loop) player.dirty = true; // Rewind
			else player.paused = true;

			// Give chance to change current track
			if (player.onTrackComplete != null) player.onTrackComplete();

			//boneTimeIndices.set(b, player.timeIndex);
			//continue;
			return;
		}

		var t = player.animTime;
		var ti = player.timeIndex;
		var t1 = track.time.values[ti];
		var t2 = track.time.values[ti + 1 * player.dir];
		var s = (t - t1) / (t2 - t1); // Linear

		var v1:Array<Float> = track.value.values[ti];
		var v2:Array<Float> = track.value.values[ti + 1 * player.dir];

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
#if WITH_DEINTERLEAVED
		// Assume position=0, normal=1 storage
		var v = resource.geometry.vertexBuffers[0].lock();
		var vnor = resource.geometry.vertexBuffers[1].lock();
		var l = 3;
#else
		var v = resource.geometry.vertexBuffer.lock();
		var l = resource.geometry.structLength;
		// var vdepth = resource.geometry.vertexBufferDepth.lock();
		// var ldepth = resource.geometry.structLengthDepth;
#end

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

#if WITH_DEINTERLEAVED
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

#if WITH_DEINTERLEAVED
		resource.geometry.vertexBuffers[0].unlock();
		resource.geometry.vertexBuffers[1].unlock();
#else
		resource.geometry.vertexBuffer.unlock();
		// resource.geometry.vertexBufferDepth.unlock();
#end
	}
}

class Player {

	public var animTime:Float = 0;
	public var timeIndex:Int = 0; // TODO: use boneTimeIndices
	public var dirty:Bool = false;

	public var current:Track;
	var tracks:Map<String, Track> = new Map();
	public var onTrackComplete:Void->Void = null;

	public var paused = false;
	public var speed:Float;
	public var dir:Int;

    public function new(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
        for (i in 0...names.length) {
        	addTrack(names[i], starts[i], ends[i], speeds[i], loops[i], reflects[i]);
        }

        play(startTrack);
    }

    public function play(name:String, onTrackComplete:Void->Void = null) {
 		this.onTrackComplete = onTrackComplete;
 		current = tracks.get(name);
 		dirty = true;
 		paused = false;
 		dir = current.speed >= 0 ? 1 : -1;
 		if (current.reflect) dir *= -1; // Start at correct dir for reflect
 		speed = Math.abs(current.speed);
    }

    public function pause() {
    	paused = true;
    }

    function addTrack(name:String, start:Int, end:Int, speed:Float, loop:Bool, reflect:Bool) {
    	var t = new Track(start, end, speed, loop, reflect);
    	tracks.set(name, t);
    }
}

class Track {
	public var start:Int;
	public var end:Int;
	public var frames:Int;
	public var speed:Float;
	public var loop:Bool;
	public var reflect:Bool;

	public function new(start:Int, end:Int, speed:Float, loop:Bool, reflect:Bool) {
		this.start = start;
		this.end = end;
		frames = end - start;
		this.speed = speed;
		this.loop = loop;
		this.reflect = reflect;
	}
}
