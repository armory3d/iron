package iron.sys;

import kha.Scheduler;

class Time {

	public static var total(get, null):Float;
	public static var delta(default, null):Float = 0;
	public static var deltaModifier = 1.0;
	
	static var last:Float;

	public function new() {
		onActivate();
	}
	
	public static inline function onActivate() {
		last = Scheduler.time();
	}
	
	public static inline function update() {
		delta = (Scheduler.time() - last) * deltaModifier;
		last = Scheduler.time();
	}

	// public static inline function getSeconds():Int {
		// return Std.int(Date.now().getTime() / 1000);
	// }

	static function get_total():Float {
		return Scheduler.time();
	}
}
