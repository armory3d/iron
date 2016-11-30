package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;

class Animation {

	public var player:Player = null;

	// Skinning
	public var data:MeshData;
	public var isSkinned:Bool;
	public var isSampled:Bool;
	public var skinBuffer:haxe.ds.Vector<kha.FastFloat>;
	public var boneMats = new Map<TObj, Mat4>();
	public var boneTimeIndices = new Map<TObj, Int>();

	var m = Mat4.identity(); // Skinning matrix
	var bm = Mat4.identity(); // Absolute bone matrix
	var pos = new Vec4();
	var nor = new Vec4();

	// Object based
	public var object:Object;

	function new(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
		player = new Player(startTrack, names, starts, ends, speeds, loops, reflects);
		Scene.active.animations.push(this);
	}

	public function remove() {
		Scene.active.animations.remove(this);
	}

	public static function setupBoneAnimation(data:MeshData, startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>, maxBones:Int) {
		var anim = new Animation(startTrack, names, starts, ends, speeds, loops, reflects);
		anim.data = data;
		anim.isSkinned = data.isSkinned;
		anim.isSampled = false;

		if (anim.isSkinned) {
			if (!MeshData.ForceCpuSkinning) {
				anim.skinBuffer = new haxe.ds.Vector(maxBones * 8); // Dual quat // * 12 for matrices
				for (i in 0...anim.skinBuffer.length) anim.skinBuffer[i] = 0;
			}

			for (b in data.mesh.skeletonBones) {
				anim.boneMats.set(b, Mat4.fromArray(b.transform.values));
				anim.boneTimeIndices.set(b, 0);
			}
		}
		return anim;
	}

	static function parseAnimationTransforms(t:Transform, animation_transforms:Array<TAnimationTransform>) {
		for (at in animation_transforms) {
			switch (at.type) {
			case "translation": t.loc.set(at.values[0], at.values[1], at.values[2]);
			case "translation_x": t.loc.x = at.value;
			case "translation_y": t.loc.y = at.value;
			case "translation_z": t.loc.z = at.value;
			case "rotation": t.setRotation(at.values[0], at.values[1], at.values[2]);
			case "rotation_x": t.setRotation(at.value, 0, 0);
			case "rotation_y": t.setRotation(0, at.value, 0);
			case "rotation_z": t.setRotation(0, 0, at.value);
			case "scale": t.scale.set(at.values[0], at.values[1], at.values[2]);
			case "scale_x": t.scale.x = at.value;
			case "scale_y": t.scale.y = at.value;
			case "scale_z": t.scale.z = at.value;
			}
		}
		t.buildMatrix();
	}

	public static function setupObjectAnimation(object:Object, startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
		var anim = new Animation(startTrack, names, starts, ends, speeds, loops, reflects);
		anim.isSkinned = false;
		anim.object = object;

		// Check animation_transforms to determine non-sampled animation
		if (object.raw.animation_transforms != null) {
			anim.isSampled = false;
			parseAnimationTransforms(object.transform, object.raw.animation_transforms);
		}
		else {
			anim.isSampled = true;
		}

		return anim;
	}

	public function update(delta:Float) {
		if (player.paused) return;

		player.animTime += delta * player.speed * player.dir;

		if (isSkinned) {
			updateBoneAnim();
			updateSkin();
		}
		else {
			updateObjectAnim();
		}
	}

	function updateObjectAnim() {
		if (isSampled) {
			updateAnimSampled(object.raw.animation, object.transform.matrix);
			// Decompose manually on every update for now
			object.transform.matrix.decompose(object.transform.loc, object.transform.rot, object.transform.scale);
		}
		else {
			updateAnimNonSampled(object.raw.animation, object.transform);
			object.transform.buildMatrix();
		}
	}

	function updateBoneAnim() {
		for (b in data.mesh.skeletonBones) {
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
			var s = player.dir > 0 ? interpolate(t, t1, t2) : interpolate(t1 - (t - t2), t2, t1);
			var invs = 1.0 - s;
			var v1 = track.value.values[ti];
			var v2 = track.value.values[ti + 1 * player.dir];
			var v = v1 * invs + v2 * s;

			switch (track.target) {
			case "xloc": transform.loc.x = v;
			case "yloc": transform.loc.y = v;
			case "zloc": transform.loc.z = v;
			case "xrot": transform.setRotation(v, transform._eulerY, transform._eulerZ);
			case "yrot": transform.setRotation(transform._eulerX, v, transform._eulerZ);
			case "zrot": transform.setRotation(transform._eulerX, transform._eulerY, v);
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
				else setObjectAnimFrame(player.current.start);
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

		var v1:Array<kha.FastFloat> = track.value.values[ti];
		var v2:Array<kha.FastFloat> = track.value.values[ti + 1 * player.dir];

		var m1 = Mat4.fromArray(v1);
		var m2 = Mat4.fromArray(v2);

		// Decompose
		var p1 = m1.getLoc();
		var p2 = m2.getLoc();
		var s1 = m1.getScale();
		var s2 = m2.getScale();
		var q1 = m1.getQuat();
		var q2 = m2.getQuat();

		// Lerp
		var fp = Vec4.lerp(p1, p2, 1.0 - s);
		// var fp = Vec4.lerp(p1, p2, s);
		var fs = Vec4.lerp(s1, s2, s);
		var fq = Quat.lerp(q1, q2, s);

		// Compose
		var m = targetMatrix;
		fq.toMat(m);
		m.scale(fs);
		m._30 = fp.x;
		m._31 = fp.y;
		m._32 = fp.z;
		// boneMats.set(b, m);
	}

	function setBoneAnimFrame(frame:Int) {
		for (b in data.mesh.skeletonBones) {
			var boneAnim = b.animation;
			if (boneAnim != null) {
				var track = boneAnim.tracks[0];
				var v1:Array<kha.FastFloat> = track.value.values[frame];
				var m1 = Mat4.fromArray(v1);
				boneMats.set(b, m1);
			}
		}
		updateSkin();
	}

	function setObjectAnimFrame(frame:Int) {
		var objectAnim = object.raw.animation;
		if (objectAnim != null) {
			var track = objectAnim.tracks[0];
			var v1:Array<kha.FastFloat> = track.value.values[frame];
			var m1 = Mat4.fromArray(v1);
			object.transform.matrix = m1;
		}
	}

	function updateSkin() {
		if (MeshData.ForceCpuSkinning) updateSkinCpu();
		else updateSkinGpu();
	}

	// Dual quat skinning
	static var vpos = new Vec4();
	static var vscl = new Vec4();
	static var q1 = new Quat(); // Real
	static var q2 = new Quat(); // Dual
	function updateSkinGpu() {
		var bones = data.mesh.skeletonBones;
		for (i in 0...bones.length) {
			
			bm.setFrom(data.mesh.skinTransform);
			bm.multmat2(data.mesh.skeletonTransformsI[i]);
			var m = Mat4.identity();
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
			skinBuffer[i * 8] = q1.x;
			skinBuffer[i * 8 + 1] = q1.y;
			skinBuffer[i * 8 + 2] = q1.z;
			skinBuffer[i * 8 + 3] = q1.w;
			skinBuffer[i * 8 + 4] = q2.x;
			skinBuffer[i * 8 + 5] = q2.y;
			skinBuffer[i * 8 + 6] = q2.z;
			skinBuffer[i * 8 + 7] = q2.w;
		}
	}

	function updateSkinCpu() {
#if arm_deinterleaved
		// Assume position=0, normal=1 storage
		var v = data.mesh.vertexBuffers[0].lock();
		var vnor = data.mesh.vertexBuffers[1].lock();
		var l = 3;
#else
		var v = data.mesh.vertexBuffer.lock();
		var l = data.mesh.structLength;
		// var vdepth = data.mesh.vertexBufferDepth.lock();
		// var ldepth = data.mesh.structLengthDepth;
#end

		var index = 0;

		for (i in 0...Std.int(v.length / l)) {

			var boneCount = data.mesh.skinBoneCounts[i];
			var boneIndices = [];
			var boneWeights = [];
			for (j in index...(index + boneCount)) {
				boneIndices.push(data.mesh.skinBoneIndices[j]);
				boneWeights.push(data.mesh.skinBoneWeights[j]);
			}
			index += boneCount;

			pos.set(0, 0, 0);
			nor.set(0, 0, 0);
			for (j in 0...boneCount) {
				var boneIndex = boneIndices[j];
				var boneWeight = boneWeights[j];
				var bone = data.mesh.skeletonBones[boneIndex];

				// Position
				m.initTranslate(data.mesh.positions[i * 3],
								data.mesh.positions[i * 3 + 1],
								data.mesh.positions[i * 3 + 2]);

				m.multmat2(data.mesh.skinTransform);

				m.multmat2(data.mesh.skeletonTransformsI[boneIndex]);

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

				m.multmat2(data.mesh.skeletonTransforms[boneIndex]);

				m.multmat2(data.mesh.skinTransformI);

				m.translate(data.mesh.normals[i * 3],
							data.mesh.normals[i * 3 + 1],
							data.mesh.normals[i * 3 + 2]);

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
		data.mesh.vertexBuffers[0].unlock();
		data.mesh.vertexBuffers[1].unlock();
#else
		data.mesh.vertexBuffer.unlock();
		// data.mesh.vertexBufferDepth.unlock();
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
