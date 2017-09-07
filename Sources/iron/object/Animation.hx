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
	public var dirty:Bool = false;
	public var onActionComplete:Void->Void = null;
	public var paused = false;
	public var frameTime = 1 / 24;

	public function play(action = '', onActionComplete:Void->Void = null) {
		this.action = action;
		this.onActionComplete = onActionComplete;
		dirty = true;
		paused = false;
	}

	public function pause() {
		paused = true;
	}

	function new() {
		Scene.active.animations.push(this);
		play();
	}

	public function remove() {
		Scene.active.animations.remove(this);
	}

	public function update(delta:Float) {
		if (paused) return;
		animTime += delta;
	}	

	inline function checkTimeIndex(timeValues:TFloat32Array):Bool {
		return ((timeIndex + 1) < timeValues.length && animTime > timeValues[timeIndex + 1]);
		// return ((timeIndex + 1) < timeValues.length && animTime > (timeIndex + 1) * (frameTime));
	}

	function updateAnimSampled(anim:TAnimation, targetMatrix:Mat4, setFrame:Int->Void) {
		if (anim == null) return;
		var track = anim.tracks[0];

		// Current track has been changed
		if (dirty) {
			dirty = false;
			
			// Animation - loop frames
			timeIndex = 0;
			animTime = track.times[0];
		}

		// Move keyframe
		//var timeIndex = boneTimeIndices.get(b);
		while (checkTimeIndex(track.times)) {
			timeIndex += 1;
		}
		// Safe check, remove
		if (timeIndex >= track.times.length) timeIndex = track.times.length - 1;
		//boneTimeIndices.set(b, timeIndex);

		// End of track
		if (timeIndex == track.times.length - 1) {
			dirty = true; // Rewind

			// Give chance to change current track
			if (onActionComplete != null) onActionComplete();

			//boneTimeIndices.set(b, timeIndex);
			//continue;
			return;
		}

		var t = animTime;
		var ti = timeIndex;
		var t1 = track.times[ti];
		var t2 = track.times[ti + 1];
		var s = (t - t1) / (t2 - t1); // Linear

		m1.setF32(track.values, ti * 16); // Offset to 4x4 matrix array
		m2.setF32(track.values, (ti + 1) * 16);

		// Decompose
		m1.decompose(vpos, q1, vscl);
		m2.decompose(vpos2, q2,vscl2);

		// Lerp
		var fp = Vec4.lerp(vpos, vpos2, 1.0 - s);
		// var fp = Vec4.lerp(p1, p2, s);
		var fq = Quat.lerp(q1, q2, s);
		var fs = Vec4.lerp(vscl, vscl2, s);

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
