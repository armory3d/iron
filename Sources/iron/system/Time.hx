package iron.system;

class Time {

	public static var step(get, never):Float;
	static inline function get_step() { return 1 / 60; }

	public static var scale = 1.0;
	public static var delta(get, never):Float;
	static inline function get_delta() { return (1 / 60) * scale; }

	static var last = 0.0;
	public static var realDelta = 0.0;
	public static inline function time():Float { return kha.Scheduler.time(); }
	public static inline function realTime():Float { return kha.Scheduler.realTime(); }

	public static function update() {
		realDelta = realTime() - last;
		last = realTime();
	}
}
