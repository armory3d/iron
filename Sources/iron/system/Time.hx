package iron.system;

class Time {

	public static inline var step = 1 / 60;	
	public static inline var delta = 1 / 60;	

	static var last = 0.0;
	public static var realDelta = 0.0;

	public static inline function time():Float { return kha.Scheduler.time(); }

	public static inline function realTime():Float { return kha.Scheduler.realTime(); }

	public static function update() {
		realDelta = realTime() - last;
		last = realTime();
	}
}
