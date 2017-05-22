package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;

class Animation {

	public var player:Player = null;

	public var isSkinned:Bool;
	public var isSampled:Bool;

	// Lerp
	static var m1 = Mat4.identity();
	static var m2 = Mat4.identity();
	static var vpos = new Vec4();
	static var vpos2 = new Vec4();
	static var vscl = new Vec4();
	static var vscl2 = new Vec4();
	static var q1 = new Quat();
	static var q2 = new Quat();

	function new(setup:TAnimationSetup) {
		player = new Player(setup);
		Scene.active.animations.push(this);
	}

	public function remove() {
		Scene.active.animations.remove(this);
	}

	public function update(delta:Float) {
		if (player.paused) return;
		player.animTime += delta * player.speed * player.dir;
	}	

	inline function checkTimeIndex(player:Player, timeValues:kha.arrays.Float32Array):Bool {
		if (player.dir > 0) {
			return ((player.timeIndex + 1) < timeValues.length && player.animTime > timeValues[player.timeIndex + 1]);
		}
		else {
			return ((player.timeIndex - 1) > 0 && player.animTime < timeValues[player.timeIndex - 1]);
		}
	}

	inline function checkTrackEnd(player:Player, track:TTrack):Bool {
		if (player.dir > 0) {
			return (player.timeIndex >= track.times.length - 1 || player.timeIndex >= player.current.end);
		}
		else {
			return (player.timeIndex <= 1 || player.timeIndex <= player.current.start);
		}
	}

	function updateAnimSampled(anim:TAnimation, targetMatrix:Mat4, setFrame:Int->Void) {
		if (anim == null || player.current == null) return;
		var track = anim.tracks[0];

		// Current track has been changed
		if (player.dirty) {
			player.dirty = false;
			// Single frame - set skin and pause
			if (player.current.frames == 0) {
				player.paused = true;
				setFrame(player.current.start);
				return;
			}
			// Animation - loop frames
			else {
				if (player.current.reflect) player.dir *= -1;

				player.timeIndex = player.dir > 0 ? player.current.start : player.current.end;
				player.animTime = track.times[player.timeIndex];
			}
		}

		// Move keyframe
		//var timeIndex = boneTimeIndices.get(b);
		while (checkTimeIndex(player, track.times)) {
			player.timeIndex += 1 * player.dir;
		}
		// Safe check, remove
		if (player.timeIndex >= track.times.length) player.timeIndex = track.times.length - 1;
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
		var t1 = track.times[ti];
		var t2 = track.times[ti + 1 * player.dir];
		var s = (t - t1) / (t2 - t1); // Linear

		m1.setF32(track.values, ti * 16); // Offset to 4x4 matrix array
		m2.setF32(track.values, (ti + 1 * player.dir) * 16);

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
	public static var animTime = 0.0;
	static var startTime = 0.0;

	static function beginProfile() {
		startTime = kha.Scheduler.realTime();
	}

	static function endProfile() {
		animTime += kha.Scheduler.realTime() - startTime;
	}

	public static function endFrame() {
		animTime = 0;
	}
#end
}

class Player {

	public var animTime:Float = 0;
	public var timeIndex:Int = 0; // TODO: use boneTimeIndices
	public var dirty:Bool = false;

	public var current:Track = null;
	var tracks:Map<String, Track> = new Map();
	public var onTrackComplete:Void->Void = null;

	public var paused = false;
	public var speed:Float;
	public var dir:Int;

	public var frameTime:Float;

	public function new(setup:TAnimationSetup) {
		frameTime = setup.frame_time;
		for (i in 0...setup.names.length) {
			addTrack(setup.names[i], setup.starts[i], setup.ends[i], setup.speeds[i], setup.loops[i], setup.reflects[i]);
		}

		play(setup.start_track);
	}

	public function play(name:String, onTrackComplete:Void->Void = null) {
		current = tracks.get(name);
		if (current == null) return; // Track not found
		this.onTrackComplete = onTrackComplete;
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
		var t = new Track(name, start, end, speed, loop, reflect);
		tracks.set(name, t);
	}
}

class Track {
	public var name:String;
	public var start:Int;
	public var end:Int;
	public var frames:Int;
	public var speed:Float;
	public var loop:Bool;
	public var reflect:Bool;

	public function new(name:String, start:Int, end:Int, speed:Float, loop:Bool, reflect:Bool) {
		this.name = name;
		this.start = start;
		this.end = end;
		frames = end - start;
		this.speed = speed;
		this.loop = loop;
		this.reflect = reflect;
	}
}
