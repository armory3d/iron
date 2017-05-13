package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;

class ObjectAnimation extends Animation {

	public var object:Object;

	public function new(object:Object, setup:TAnimationSetup) {
		super(setup);
		this.isSkinned = false;
		this.object = object;

		// Check animation_transforms to determine non-sampled animation
		if (object.raw.animation_transforms != null) {
			this.isSampled = false;
			parseAnimationTransforms(object.transform, object.raw.animation_transforms);
		}
		else {
			this.isSampled = true;
		}
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

	public override function update(delta:Float) {
		if (!object.visible || object.culled) return;
		
#if arm_profile
		Animation.beginProfile();
#end

		super.update(delta);
		if (player.paused) return;

		if (!isSkinned) {
			updateObjectAnim();
		}

#if arm_profile
		Animation.endProfile();
#end
	}

	function updateObjectAnim() {
		if (isSampled) {
			updateAnimSampled(object.raw.animation, object.transform.matrix, setObjectAnimFrame);
			// Decompose manually on every update for now
			object.transform.matrix.decompose(object.transform.loc, object.transform.rot, object.transform.scale);
		}
		else {
			updateAnimNonSampled(object.raw.animation, object.transform);
			object.transform.buildMatrix();
		}
	}

	function setObjectAnimFrame(frame:Int) {
		var objectAnim = object.raw.animation;
		if (objectAnim != null) {
			var track = objectAnim.tracks[0];
			var m1 = Mat4.fromArray(track.values, frame * 16);
			object.transform.matrix = m1;
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
		if (anim == null || player.current == null) return;
		
		var begin = anim.begin;
		var end = anim.end;
		var total = end - begin;

		if (player.dirty) {
			player.dirty = false;
			player.animTime = player.current.start * player.ft;
			player.timeIndex = 0;
			var track = anim.tracks[0];
			while (player.animTime > track.times[player.timeIndex] + player.ft) {
				player.timeIndex++;
			}
		}

		// Track with no frames - keep idle
		if (player.current.frames == 0) return;

		for (track in anim.tracks) {

			// No data for this track at current time
			if (player.timeIndex >= track.times.length) continue;

			// End of track
			if (player.animTime > total || player.animTime < 0 ||
				(player.animTime > player.current.end * player.ft - player.ft && player.dir > 0) ||
				(player.animTime < player.current.start * player.ft + player.ft && player.dir < 0)
				) {

				if (!player.current.loop) {
					player.paused = true;
					return;
				}

				if (player.current.reflect) player.dir *= -1; // Reflect
				
				player.animTime = player.dir > 0 ? 0 : total; // Rewind
				player.timeIndex = player.dir > 0 ? 0 : track.times.length - 1;
			}

			// End of current time range
			var t = player.animTime + begin;
			if (player.dir > 0) {
				while (player.timeIndex < track.times.length - 2 && t > track.times[player.timeIndex + 1]) {
					player.timeIndex++;
				}
			}
			// Reversed
			else {
				while (player.timeIndex > 1 && t < track.times[player.timeIndex - 1]) {
					player.timeIndex--;
				}
			}

			var ti = player.timeIndex;
			var t1 = track.times[ti];
			var t2 = track.times[ti + 1 * player.dir];
			var interpolate = interpolateLinear;
			switch (track.curve) {
			case "linear": interpolate = interpolateLinear;
			case "bezier": interpolate = interpolateBezier;
			// case "tcb": interpolate = interpolateTcb;
			}
			var s = player.dir > 0 ? interpolate(t, t1, t2) : interpolate(t1 - (t - t2), t2, t1);
			var invs = 1.0 - s;
			var v1 = track.values[ti];
			var v2 = track.values[ti + 1 * player.dir];
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
}
