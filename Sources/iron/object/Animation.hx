package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;
import iron.data.Armature;

class Animation {

	public var isSkinned:Bool;
	public var isSampled:Bool;
	public var action = '';
	public var armature:Armature; // Bone

	// Lerp
	static var m1 = Mat4.identity();
	static var m2 = Mat4.identity();
	static var vpos = new Vec4();
	static var vpos2 = new Vec4();
	static var vscl = new Vec4();
	static var vscl2 = new Vec4();
	static var q1 = new Quat();
	static var q2 = new Quat();

	public var time = 0.0;
	public var speed = 1.0;
	public var loop = true;
	public var frameIndex = 0; // TODO: use boneTimeIndices
	public var onComplete:Void->Void = null;
	public var paused = false;
	var frameTime:Float;

	var blendTime = 0.0;
	var blendCurrent = 0.0;
	var blendAction = '';

	function new() {
		Scene.active.animations.push(this);
		frameTime = Scene.active.raw.frame_time;
		play();
	}

	public function play(action = '', onComplete:Void->Void = null, blendTime = 0.0, speed = 1.0, loop = true) {
		if (blendTime > 0) {
			this.blendTime = blendTime;
			this.blendCurrent = 0.0;
			this.blendAction = this.action;
		}
		else frameIndex = -1;
		this.action = action;
		this.onComplete = onComplete;
		this.speed = speed;
		this.loop = loop;
		paused = false;
	}

	public function pause() {
		paused = true;
	}

	public function resume() {
		paused = false;
	}

	public function remove() {
		Scene.active.animations.remove(this);
	}

	public function update(delta:Float) {
		if (paused) return;
		time += delta * speed;

		if (blendTime > 0) {
			blendCurrent += delta;
			if (blendCurrent >= blendTime) blendTime = 0.0;
		}
	}	

	inline function checkFrameIndex(frameValues:TUint32Array):Bool {
		return ((frameIndex + 1) < frameValues.length && time > frameValues[frameIndex + 1] * frameTime);
	}

	function rewind(track:TTrack) {
		frameIndex = 0;
		time = track.frames[0] * frameTime;
	}

	function updateTrack(anim:TAnimation) {
		if (anim == null) return;
		var track = anim.tracks[0];

		if (frameIndex == -1) rewind(track);

		// Move keyframe
		//var frameIndex = boneTimeIndices.get(b);
		while (checkFrameIndex(track.frames)) frameIndex++;
		//boneTimeIndices.set(b, frameIndex);

		// End of track
		if (frameIndex >= track.frames.length - 1) {
			if (onComplete != null && blendTime == 0) onComplete();
			if (loop || blendTime > 0) {
				rewind(track);
			}
			else {
				frameIndex--;
				paused = true;
			}
			//boneTimeIndices.set(b, frameIndex);
		}

		trace(totalFrames());
	}

	function updateAnimSampled(anim:TAnimation, targetMatrix:Mat4) {
		if (anim == null) return;
		var track = anim.tracks[0];

		var t = time;
		var ti = frameIndex;
		var t1 = track.frames[ti] * frameTime;
		var t2 = track.frames[ti + 1] * frameTime;
		var s = (t - t1) / (t2 - t1); // Linear

		m1.setF32(track.values, ti * 16); // Offset to 4x4 matrix array
		m2.setF32(track.values, (ti + 1) * 16);

		// Decompose
		m1.decompose(vpos, q1, vscl);
		m2.decompose(vpos2, q2, vscl2);

		// Lerp
		var fp = Vec4.lerp(vpos, vpos2, 1.0 - s);
		var fs = Vec4.lerp(vscl, vscl2, 1.0 - s);
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

	public function currentFrame():Int { return Std.int(time / frameTime); }
	public function totalFrames():Int { return 0; }

#if arm_profile
	public static var animationTime = 0.0;
	static var startTime = 0.0;
	static function beginProfile() { startTime = kha.Scheduler.realTime(); }
	static function endProfile() { animationTime += kha.Scheduler.realTime() - startTime; }
	public static function endFrame() { animationTime = 0; }
#end
}
