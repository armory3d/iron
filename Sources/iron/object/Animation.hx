package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;

class Animation {

	public var isSkinned:Bool;
	public var isSampled:Bool;
	public var action = '';

	// Lerp
	static var m1 = Mat4.identity();
	static var m2 = Mat4.identity();
	static var vpos = new Vec4();
	static var vpos2 = new Vec4();
	static var vscl = new Vec4();
	static var vscl2 = new Vec4();
	static var q1 = new Quat();
	static var q2 = new Quat();

	public var animTime:Float = 0;
	public var timeIndex:Int = 0; // TODO: use boneTimeIndices
	public var onActionComplete:Void->Void = null;
	public var paused = false;
	var frameTime:Float;

	var blendTime = 0.0;
	var blendCurrent = 0.0;
	var blendAction = '';

	public function play(action = '', onActionComplete:Void->Void = null, blendTime = 0.0) {
		if (blendTime > 0) {
			this.blendTime = blendTime;
			this.blendCurrent = 0.0;
			this.blendAction = this.action;
		}
		else timeIndex = -1;
		this.action = action;
		this.onActionComplete = onActionComplete;
		paused = false;
	}

	public function pause() {
		paused = true;
	}

	function new() {
		Scene.active.animations.push(this);
		frameTime = Scene.active.raw.frame_time;
		play();
	}

	public function remove() {
		Scene.active.animations.remove(this);
	}

	public function update(delta:Float) {
		if (paused) return;
		animTime += delta;

		if (blendTime > 0) {
			blendCurrent += delta;
			if (blendCurrent >= blendTime) blendTime = 0.0;
		}
	}	

	inline function checkTimeIndex(timeValues:TFloat32Array):Bool {
		return ((timeIndex + 1) < timeValues.length && animTime > timeValues[timeIndex + 1] * frameTime);
	}

	function rewind(track:TTrack) {
		timeIndex = 0;
		animTime = track.times[0] * frameTime;
	}

	function updateAnimSampled(anim:TAnimation, targetMatrix:Mat4) {
		if (anim == null) return;
		var track = anim.tracks[0];

		if (timeIndex == -1) rewind(track);

		// Move keyframe
		//var timeIndex = boneTimeIndices.get(b);
		while (checkTimeIndex(track.times)) timeIndex++;
		//boneTimeIndices.set(b, timeIndex);

		// End of track
		if (timeIndex >= track.times.length - 1) {
			rewind(track);

			if (onActionComplete != null) onActionComplete();
			//boneTimeIndices.set(b, timeIndex);

			// Give chance to change current track
			// return;
		}

		var t = animTime;
		var ti = timeIndex;
		var t1 = track.times[ti] * frameTime;
		var t2 = track.times[ti + 1] * frameTime;
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

#if arm_profile
	public static var animationTime = 0.0;
	static var startTime = 0.0;
	static function beginProfile() { startTime = kha.Scheduler.realTime(); }
	static function endProfile() { animationTime += kha.Scheduler.realTime() - startTime; }
	public static function endFrame() { animationTime = 0; }
#end
}
