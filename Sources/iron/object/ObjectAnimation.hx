package iron.object;

import kha.FastFloat;
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

	public override function update(delta:FastFloat) {
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

	inline function interpolateLinear(t:FastFloat, t1:FastFloat, t2:FastFloat, v1:FastFloat, v2:FastFloat):FastFloat {
		var s = (t - t1) / (t2 - t1);
		return (1.0 - s) * v1 + s * v2;
	}

	var s0:FastFloat = 0.0;
	var bezierFrameIndex = -1;
	inline function interpolateBezier(t:FastFloat, t1:FastFloat, t2:FastFloat, v1:FastFloat, v2:FastFloat, c1:FastFloat, c2:FastFloat, p1:FastFloat, p2:FastFloat):FastFloat {
		if (frameIndex != bezierFrameIndex) {
			bezierFrameIndex = frameIndex;
			s0 = (t - t1) / (t2 - t1);
		}
		var a:FastFloat = (t2 - 3 * c2 + 3 * c1 - t1) * (s0 * s0 * s0) + 3 * (c2 - 2 * c1 + t1) * (s0 * s0) + 3 * (c1 - t1) * s0 + t1 - t;
		var b:FastFloat = 3 * (t2 - 3 * c2 + 3 * c1 - t1) * (s0 * s0) + 6 * (c2 - 2 * c1 + t1) * s0 + 3 * (c1 - t1);
		var s:FastFloat = s0 - (a / b);
		s0 = s;
		return (1 - s) * (1 - s) * (1 - s) * v1 + 3 * s * (1 - s) * (1 - s) * p1 + 3 * (s * s) * (1 - s) * p2 + s * s * s * v2;
	}

	// inline function interpolateTcb():FastFloat { return 0.0; }

	override function isTrackEnd(track:TTrack):Bool {
		return speed > 0 ?
			frameIndex >= track.frames.length - 2 :
			frameIndex <= 0;
	}

	inline function checkFrameIndexT(frameValues:kha.arrays.Uint32Array, t:FastFloat):Bool {
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
				if (loop) rewind(track);
				else { frameIndex -= sign; paused = true; }
				return;
			}

			var ti = frameIndex;
			var t1 = track.frames[ti] * frameTime;
			var t2 = track.frames[ti + sign] * frameTime;
			var v1 = track.values[ti];
			var v2 = track.values[ti + sign];
			var v = 0.0;
			switch (track.curve) {
			case "linear": {
				v = interpolateLinear(t, t1, t2, v1, v2);
			}
			case "bezier": {
				var c1 = track.frames_control_plus[ti] * frameTime;
				var c2 = track.frames_control_minus[ti + sign] * frameTime;
				var p1 = track.values_control_plus[ti];
				var p2 = track.values_control_minus[ti + sign];
				v = interpolateBezier(t, t1, t2, v1, v2, c1, c2, p1, p2);
			}
			// case "tcb": v = interpolateTcb();
			}

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
