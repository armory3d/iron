package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;

class ObjectAnimation extends Animation {

	public var object:Object;

	public function new(object:Object) {
		super();
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
		if (paused) return;

		if (!isSkinned) {
			updateObjectAnim();
		}

#if arm_profile
		Animation.endProfile();
#end
	}

	function updateObjectAnim() {
		if (isSampled) {
			updateAnimSampled(object.raw.animation, object.transform.world);
			// Decompose manually on every update for now
			object.transform.world.decompose(object.transform.loc, object.transform.rot, object.transform.scale);
		}
		else {
			updateAnimNonSampled(object.raw.animation, object.transform);
			object.transform.buildMatrix();
		}
	}

	// function setObjectAnimFrame(frame:Int) {
	// 	var objectAnim = object.raw.animation;
	// 	if (objectAnim != null) {
	// 		var track = objectAnim.tracks[0];
	// 		var m1 = Mat4.fromFloat32Array(track.values, frame * 16);
	// 		object.transform.world = m1;
	// 	}
	// }

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
		
		var total = anim.end * frameTime - anim.begin * frameTime;

		for (track in anim.tracks) {

			// No data for this track at current time
			if (timeIndex >= track.times.length) continue;

			// End of track
			if (animTime > total) rewind(track);

			// End of current time range
			var t = animTime + anim.begin * frameTime;
			while (timeIndex < track.times.length - 2 && t > track.times[timeIndex + 1] * frameTime) {
				timeIndex++;
			}

			var ti = timeIndex;
			var t1 = track.times[ti] * frameTime;
			var t2 = track.times[ti + 1] * frameTime;
			var interpolate = interpolateLinear;
			switch (track.curve) {
			case "linear": interpolate = interpolateLinear;
			case "bezier": interpolate = interpolateBezier;
			// case "tcb": interpolate = interpolateTcb;
			}
			var s = interpolate(t, t1, t2);
			var invs = 1.0 - s;
			var v1 = track.values[ti];
			var v2 = track.values[ti + 1];
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
