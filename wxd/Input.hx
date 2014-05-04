package wings.wxd;

class Input {

	public static var enabled:Bool;
	public static var forced:Bool;
	
	static var _started:Bool;
	static var _touch:Bool;
	static var _released:Bool;
	public static var started(get, set):Bool;
	public static var touch(get, set):Bool;
	public static var released(get, set):Bool;

	static var _startedAlt:Bool;
	static var _touchAlt:Bool;
	static var _releasedAlt:Bool;
	public static var startedAlt(get, set):Bool;
	public static var touchAlt(get, set):Bool;
	public static var releasedAlt(get, set):Bool;

	static var _moved:Bool;
	public static var moved(get, set):Bool;

	static var _wheel:Int;
	public static var wheel(get, set):Int;

	public static var preventRelease(default, default):Bool;
	public static var preventReleaseAlt(default, default):Bool;

	public static var x(default, default):Float;
	public static var y(default, default):Float;

	public static var deltaX(default, default):Float;
	public static var deltaY(default, default):Float;
	
	// Keys
	public static var left:Bool;
	public static var right:Bool;
	public static var up:Bool;
	public static var down:Bool;

	public function new() {
		reset();
		enabled = true;
		forced = false;
	}

	public static function update() {
		// TODO: make setters private
		released = false;
		started = false;
		releasedAlt = false;
		startedAlt = false;
		moved = false;
		deltaX = 0;
		deltaY = 0;
		wheel = 0;
	}

	public static function reset() {
		//x = 0;
		//y = 0;

		deltaX = 0;
		deltaY = 0;

		_started = false;
		_touch = false;
		_released = false;

		_startedAlt = false;
		_touchAlt = false;
		_releasedAlt = false;

		_moved = false;

		_wheel = 0;

		preventRelease = false;
		preventReleaseAlt = false;

		left = right = up = down = false;
	}
	
	public static function onTouchBegin(_x:Float, _y:Float) {
		_touch = true;
		_started = true;

		x = _x;
		y = _y;
	}
	
	public static function onTouchEnd(_x:Float, _y:Float) {
		_touch = false;

		if (!preventRelease) _released = true;
		else preventRelease = false;

		x = _x;
		y = _y;
	}

	public static function onTouchAltBegin(_x:Float, _y:Float) {
		_touchAlt = true;
		_startedAlt = true;

		x = _x;
		y = _y;
	}
	
	public static function onTouchAltEnd(_x:Float, _y:Float) {
		_touchAlt = false;
		
		if (!preventReleaseAlt) _releasedAlt = true;
		else preventReleaseAlt = false;

		x = _x;
		y = _y;
	}

	public static function onButtonDown(button:kha.Button) {
		if (button == kha.Button.LEFT) left = true;
		else if (button == kha.Button.RIGHT) right = true;
		else if (button == kha.Button.UP) up = true;
		else if (button == kha.Button.DOWN) down = true;
	}

	public static function onButtonUp(button:kha.Button) {
		if (button == kha.Button.LEFT) left = false;
		else if (button == kha.Button.RIGHT) right = false;
		else if (button == kha.Button.UP) up = false;
		else if (button == kha.Button.DOWN) down = false;
	}

	public static function onWheel(delta:Int) {
		_wheel = delta;
	}
	
	public static function onMove(_x:Float, _y:Float) {
		// TODO: check first frame delta
		deltaX = _x - x;
		deltaY = _y - y;

		//#if cpp
		//deltaX *= -1;
		//deltaY *= -1;
		//#end

		x = _x;
		y = _y;
		_moved = true;
	}

	static inline function get_started():Bool {
		if (!enabled && !forced) return false;
		else return _started;
	}

	static inline function get_touch():Bool {
		if (!enabled && !forced) return false;
		else return _touch;
	}

	static inline function get_released():Bool {
		if (!enabled && !forced) return false;
		else return _released;
	}

	static inline function get_startedAlt():Bool {
		if (!enabled && !forced) return false;
		else return _startedAlt;
	}

	static inline function get_touchAlt():Bool {
		if (!enabled && !forced) return false;
		else return _touchAlt;
	}

	static inline function get_releasedAlt():Bool {
		if (!enabled && !forced) return false;
		else return _releasedAlt;
	}

	static inline function get_moved():Bool {
		if (!enabled && !forced) return false;
		else return _moved;
	}

	static inline function get_wheel():Int {
		if (!enabled && !forced) return 0;
		else return _wheel;
	}

	static inline function set_started(b:Bool):Bool { return _started = b; }
	static inline function set_touch(b:Bool):Bool { return _touch = b; }
	static inline function set_released(b:Bool):Bool { return _released = b; }
	static inline function set_startedAlt(b:Bool):Bool { return _startedAlt = b; }
	static inline function set_touchAlt(b:Bool):Bool { return _touchAlt = b; }
	static inline function set_releasedAlt(b:Bool):Bool { return _releasedAlt = b; }
	static inline function set_moved(b:Bool):Bool { return _moved = b; }
	static inline function set_wheel(i:Int):Int { return _wheel = i; }
}
