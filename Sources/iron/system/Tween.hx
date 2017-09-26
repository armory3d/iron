package iron.system;

class Tween {
	static var eases:Array<Float->Float> = [easeLinear, easeExpoOut];
	static var anims:Array<TAnim> = [];

	public static function to(anim:TAnim):TAnim {
		anim._time = 0;
		if (anim.ease == null) anim.ease = Ease.Linear;
		
		if (anim.target != null && anim.props != null) {

			anim._comps = []; anim._x = []; anim._y = []; anim._z = []; anim._w = []; anim._normalize = [];
			for (p in Reflect.fields(anim.props)) {
				var val:Dynamic = Reflect.getProperty(anim.target, p);
				if (Std.is(val, iron.math.Vec4) || Std.is(val, iron.math.Quat)) {
					anim._comps.push(4);
					anim._x.push(val.x);
					anim._y.push(val.y);
					anim._z.push(val.z);
					anim._w.push(val.w);
					anim._normalize.push(Std.is(val, iron.math.Quat));
				}
				else {
					anim._comps.push(1);
					anim._x.push(val);
					anim._y.push(0);
					anim._z.push(0);
					anim._w.push(0);
				}
			}
		}

		anims.push(anim);
		return anim;
	}

	public static function timer(delay:Float, done:Void->Void):TAnim {
		return to({ target: null, props: null, duration: 0, delay: delay, done: done });
	}

	public static function stop(anim:TAnim) {
		anims.remove(anim);
	}

	public static function reset() {
		anims = [];
	}

	public static function update() {
		var d = Time.delta;
		var i = anims.length;
		while (i-- > 0 && anims.length > 0) {
			var a = anims[i];

			if (a.delay > 0) { // Delay
				a.delay -= d;
				if (a.delay > 0) continue;
			}

			a._time += d; // Tween

			if (a.target != null) {

				if (Std.is(a.target, iron.object.Transform)) a.target.dirty = true;

				// Way too much Reflect trickery..
				var ps = Reflect.fields(a.props);
				for (i in 0...ps.length) {
					var p = ps[i];
					var k = a._time / a.duration;
					if (k > 1) k = 1;

					if (a._comps[i] == 1) {
						var fromVal:Float = a._x[i];
						var toVal:Float = Reflect.getProperty(a.props, p);
						var val:Float = fromVal + (toVal - fromVal) * eases[a.ease](k);
						Reflect.setProperty(a.target, p, val);
					}
					else { // _comps[i] == 4
						var obj = Reflect.getProperty(a.props, p);
						var toX:Float = Reflect.getProperty(obj, "x");
						var toY:Float = Reflect.getProperty(obj, "y");
						var toZ:Float = Reflect.getProperty(obj, "z");
						var toW:Float = Reflect.getProperty(obj, "w");
						if (a._normalize[i]) {
							var qdot = (a._x[i] * toX) + (a._y[i] * toY) + (a._z[i] * toZ) + (a._w[i] * toW);
							if (qdot < 0.0) {
								toX = -toX; toY = -toY; toZ = -toZ; toW = -toW;
							}
						}
						var x:Float = a._x[i] + (toX - a._x[i]) * eases[a.ease](k);
						var y:Float = a._y[i] + (toY - a._y[i]) * eases[a.ease](k);
						var z:Float = a._z[i] + (toZ - a._z[i]) * eases[a.ease](k);
						var w:Float = a._w[i] + (toW - a._w[i]) * eases[a.ease](k);
						if (a._normalize[i]) {
							var l = Math.sqrt(x * x + y * y + z * z + w * w);
							if (l > 0.0) {
								l = 1.0 / l;
								x *= l; y *= l; z *= l; w *= l;
							}
						}
						var t = Reflect.getProperty(a.target, p);
						Reflect.setProperty(t, "x", x);
						Reflect.setProperty(t, "y", y);
						Reflect.setProperty(t, "z", z);
						Reflect.setProperty(t, "w", w);
					}
				}
			}

			if (a.tick != null) a.tick();
			
			if (a._time >= a.duration) { // Complete
				anims.splice(i, 1);
				i--;
				if (a.done != null) a.done();
			}
		}
	}

	static function easeLinear(k:Float):Float { return k; }
	static function easeExpoOut(k:Float):Float { return k == 1 ? 1 : (1 - Math.pow(2, -10 * k)); }
}

typedef TAnim = {
	var target:Dynamic;
	var props:Dynamic;
	var duration:Float;
	@:optional var done:Void->Void;
	@:optional var tick:Void->Void;
	@:optional var delay:Null<Float>;
	@:optional var ease:Null<Ease>;
	// Internal
	@:optional var _time:Null<Float>;
	@:optional var _comps:Array<Int>;
	@:optional var _x:Array<Float>;
	@:optional var _y:Array<Float>;
	@:optional var _z:Array<Float>;
	@:optional var _w:Array<Float>;
	@:optional var _normalize:Array<Bool>;
}

@:enum abstract Ease(Int) from Int to Int {
	var Linear = 0;
	var ExpoOut = 1;
}
