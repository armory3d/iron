package iron.object;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;

class ObjectAnimation extends Animation {

	public var object:Object;
	var oactions:Array<TSceneFormat>;
	var oaction:TObj;

	public function new(object:Object, oactions:Array<TSceneFormat>) {
		this.object = object;
		this.oactions = oactions;
		isSkinned = false;
		super();
	}

	function getAction(action:String):TObj {
		for (a in oactions) if (a != null && a.objects[0].name == action) return a.objects[0];
		return null;
	}

	override public function play(action = '', onComplete:Void->Void = null, blendTime = 0.0, speed = 1.0, loop = true) {
		super.play(action, onComplete, blendTime, speed, loop);
		if (this.action == '' && oactions[0] != null) this.action = oactions[0].objects[0].name;
		oaction = getAction(this.action);
		if (oaction != null) {
			isSampled = oaction.sampled != null && oaction.sampled;
		}
	}

	public override function update(delta:Float) {
		if (!object.visible || object.culled || oaction == null) return;
		
		#if arm_debug
		Animation.beginProfile();
		#end

		super.update(delta);
		if (paused) return;
		if (!isSkinned) updateObjectAnim();

		#if arm_debug
		Animation.endProfile();
		#end
	}

	function updateObjectAnim() {
		if (isSampled) {
			updateTrack(oaction.anim);
			updateAnimSampled(oaction.anim, object.transform.world);
			object.transform.world.decompose(object.transform.loc, object.transform.rot, object.transform.scale);
			for (c in object.children) c.transform.buildMatrix();
		}
		else {
			updateAnimNonSampled(oaction.anim, object.transform);
			object.transform.buildMatrix();
		}
	}

	inline function interpolateLinear(t:Float, t1:Float, t2:Float):Float {
		return (t - t1) / (t2 - t1);
	}
	inline function interpolateBezier(t:Float, t1:Float, t2:Float) {
		// TODO: proper interpolation
		var k = interpolateLinear(t, t1, t2);
		// return k == 1 ? 1 : (1 - Math.pow(2, -10 * k));
		k = k * k * (3.0 - 2.0 * k); // Smoothstep
		return k;
	}
	inline function interpolateTcb() {}

	inline function checkFrameIndexT(frameValues:kha.arrays.Uint32Array, t:Float):Bool {
		return speed > 0 ?
			frameIndex < frameValues.length - 2 && t > frameValues[frameIndex + 1] * frameTime :
			frameIndex > 1 && t > frameValues[frameIndex - 1] * frameTime;
	}

	@:access(iron.object.Transform)
	function updateAnimNonSampled(anim:TAnimation, transform:Transform) {
		if (anim == null) return;
		
		var total = anim.end * frameTime - anim.begin * frameTime;

		if (anim.has_delta) {
			var t = transform;
			if (t.dloc == null) { t.dloc = new Vec4(); t.drot = new Quat(); t.dscale = new Vec4(); }
			t.dloc.set(0, 0, 0);
			t.dscale.set(0, 0, 0);
			t._deulerX = t._deulerY = t._deulerZ = 0.0;
		}

		for (track in anim.tracks) {

			if (frameIndex == -1) rewind(track);
			var sign = speed > 0 ? 1 : -1;

			// End of current time range
			var t = time + anim.begin * frameTime;
			while (checkFrameIndexT(track.frames, t)) frameIndex += sign;

			// No data for this track at current time
			if (frameIndex >= track.frames.length) continue;

			// End of track
			if (time > total) {
				if (onComplete != null) onComplete();
				rewind(track);
				return;
			}

			var ti = frameIndex;
			var t1 = track.frames[ti] * frameTime;
			var t2 = track.frames[ti + sign] * frameTime;
			var interpolate = interpolateLinear;
			switch (track.curve) {
			case "linear": interpolate = interpolateLinear;
			case "bezier": interpolate = interpolateBezier;
			// case "tcb": interpolate = interpolateTcb;
			}
			var s = interpolate(t, t1, t2);
			var invs = 1.0 - s;
			var v1 = track.values[ti];
			var v2 = track.values[ti + sign];
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
			// Delta
			case "dxloc": transform.dloc.x = v;
			case "dyloc": transform.dloc.y = v;
			case "dzloc": transform.dloc.z = v;
			case "dxrot": transform._deulerX = v;
			case "dyrot": transform._deulerY = v;
			case "dzrot": transform._deulerZ = v;
			case "dxscl": transform.dscale.x = v;
			case "dyscl": transform.dscale.y = v;
			case "dzscl": transform.dscale.z = v;
			}
		}
	}

	public override function totalFrames():Int { 
		if (oaction == null || oaction.anim == null) return 0;
		return oaction.anim.end - oaction.anim.begin;
	}
}
