package wings.sys;

class Input {
	
	public static var started:Bool;
	public static var touch:Bool;
	public static var released:Bool;

	public static var startedAlt:Bool;
	public static var touchAlt:Bool;
	public static var releasedAlt:Bool;

	public static var moved:Bool;

	public static var wheel:Int;

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

		started = false;
		touch = false;
		released = false;

		startedAlt = false;
		touchAlt = false;
		releasedAlt = false;

		moved = false;

		wheel = 0;

		left = right = up = down = false;
	}
	
	public static function onTouchBegin(_x:Float, _y:Float) {
		touch = true;
		started = true;

		x = _x;
		y = _y;
	}
	
	public static function onTouchEnd(_x:Float, _y:Float) {
		touch = false;

		x = _x;
		y = _y;
	}

	public static function onTouchAltBegin(_x:Float, _y:Float) {
		touchAlt = true;
		startedAlt = true;

		x = _x;
		y = _y;
	}
	
	public static function onTouchAltEnd(_x:Float, _y:Float) {
		touchAlt = false;

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
		wheel = delta;
	}
	
	public static function onMove(_x:Float, _y:Float) {
		// TODO: check first frame delta
		deltaX = _x - x;
		deltaY = _y - y;

		x = _x;
		y = _y;
		moved = true;
	}
}
