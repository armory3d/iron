package iron.sys;

import haxe.ds.ObjectMap;

class Tween {
	public static inline var LINEAR = 0;
	public static inline var EXPO_OUT = 1;
	public static inline var DEFAULT = 1;
	static var eases:Array<Float->Float> = [easeLinear, easeExpoOut];

	static var anims:Array<Anim> = [];
	static var map:ObjectMap<Dynamic, Anim> = new ObjectMap();

	public static function to(target:Dynamic, time:Float, props:Dynamic, f:Void->Void = null, delay = 0.0, type = DEFAULT) {
		// TODO: parse target props to float array
		
		var anim = new Anim(target, time, props, f, delay, type);
		anim._ease = eases[type];
		
		if (anim.target != null && anim.props != null) {
			anim._startProps = [];
			for (p in Reflect.fields(anim.props)) {
				var val:Float = Reflect.getProperty(anim.target, p);
				anim._startProps.push(val);
			}
		}

		anims.push(anim);
		if (target != null) map.set(target, anim);
	}

	public static function timer(delay:Float, f:Void->Void) {
		to(null, 0, null, f, delay);
	}

	public static function stop(target:Dynamic) {
		var anim = map.get(target);
		if (anim != null) anims.remove(anim);
	}

	public static function reset() {
		anims = [];
		map = new ObjectMap();
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

			a._currentTime += d; // Tween

			if (a.target != null) {

				var ps = Reflect.fields(a.props);
				for (i in 0...ps.length) {
					var p = ps[i];
					
					var startVal:Float = a._startProps[i];
					var targetVal:Float = Reflect.getProperty(a.props, p);

					var k = a._currentTime / a.time;
					if (k > 1) k = 1;
					var val:Float = startVal + (targetVal - startVal) * a._ease(k);
					Reflect.setProperty(a.target, p, val);
				}
			}

			if (a._currentTime >= a.time) { // Complete
				anims.splice(i, 1);
				i--;
				if (a.f != null) a.f();
			}
		}
	}

	static function easeLinear(k:Float):Float { return k; }
	static function easeExpoOut(k:Float):Float { return k == 1 ? 1 : (1 - Math.pow(2, -10 * k)); }
}

class Anim {
	public var target:Dynamic;
	public var time:Float;
	public var props:Dynamic;
	public var delay:Float;
	public var f:Void->Void;
	public var type:Int;
	public var _ease:Float->Float = null;
	public var _currentTime:Float = 0;
	public var _startProps:Array<Dynamic> = null;
	public function new(target:Dynamic, time:Float, props:Dynamic, f:Void->Void, delay:Float, type:Int) {
		this.target = target;
		this.time = time;
		this.props = props;
		this.delay = delay;
		this.f = f;
		this.type = type;
	}
}
