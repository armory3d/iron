package iron.system;

class Tween {
	static var eases:Array<Float->Float> = [easeLinear, easeExpoOut];
	static var anims:Array<TAnim> = [];
	static var map:haxe.ds.ObjectMap<Dynamic, TAnim> = new haxe.ds.ObjectMap();
	static var comps = ['x', 'y', 'z', 'w'];

	public static function to(anim:TAnim) {
		anim._time = 0;
		if (anim.ease == null) anim.ease = Ease.Linear;
		
		if (anim.target != null && anim.props != null) {

			anim._comps = []; anim._x = []; anim._y = []; anim._z = []; anim._w = [];
			for (p in Reflect.fields(anim.props)) {
				var val:Dynamic = Reflect.getProperty(anim.target, p);
				if (Std.is(val, iron.math.Vec4) || Std.is(val, iron.math.Quat)) {
					anim._comps.push(4);
					anim._x.push(val.x);
					anim._y.push(val.y);
					anim._z.push(val.z);
					anim._w.push(val.w);
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
		if (anim.target != null) map.set(anim.target, anim);
	}

	public static function timer(delay:Float, done:Void->Void) {
		to({ target: null, props: null, duration: 0, delay: delay, done: done });
	}

	public static function stop(target:Dynamic) {
		var anim = map.get(target);
		if (anim != null) anims.remove(anim);
	}

	public static function reset() {
		anims = [];
		map = new haxe.ds.ObjectMap();
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
					else {
						for (j in 0...a._comps[i]) {
							var fromVal:Float = j == 0 ? a._x[i] : j == 1 ? a._y[i] : j == 2 ? a._z[i] : a._w[i];
							var obj = Reflect.getProperty(a.props, p);
							var toVal:Float = Reflect.getProperty(obj, comps[j]);
							var val:Float = fromVal + (toVal - fromVal) * eases[a.ease](k);
							var t = Reflect.getProperty(a.target, p);
							Reflect.setProperty(t, comps[j], val);
						}
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
	@:optional var delay:Float;
	@:optional var ease:Ease;
	// Internal
	@:optional var _time:Float;
	@:optional var _comps:Array<Int>;
	@:optional var _x:Array<Float>;
	@:optional var _y:Array<Float>;
	@:optional var _z:Array<Float>;
	@:optional var _w:Array<Float>;
}

@:enum abstract Ease(Int) from Int to Int {
	var Linear = 0;
	var ExpoOut = 1;
}
