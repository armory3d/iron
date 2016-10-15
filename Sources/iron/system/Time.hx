package iron.system;

class Time {

	public static inline var step = 1 / 60;	
	public static inline var delta = 1 / 60;	

	public static inline function time():Float {
		return kha.Scheduler.time();
	}
}
