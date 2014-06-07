package wings.sys;

import kha.Scheduler;

class Time {

	public static var delta(default, null):Float;
	
	static var last:Float;

	public function new() {
		onActivate();
	}
	
	public static inline function onActivate() {
		last = Scheduler.time();
	}
	
	public static inline function update() {
		delta = Scheduler.time() - last;
		last = Scheduler.time();
	}

	public static inline function getSeconds():Int {
		return Std.int(Date.now().getTime() / 1000);
	}
}
