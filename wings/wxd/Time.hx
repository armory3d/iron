package wings.wxd;

import kha.Scheduler;

class Time {
	public static var delta(default, null):Int;
	static var last:Int;

	public function new() {
		onActivate();
	}
	
	public static inline function onActivate() {
		last = Std.int(Scheduler.time() * 1000);
		//last = Std.int(haxe.Timer.stamp() * 1000);
	}
	
	public static inline function update() {
		delta = Std.int(Scheduler.time() * 1000) - last;
		last = Std.int(Scheduler.time() * 1000);
	}
}
