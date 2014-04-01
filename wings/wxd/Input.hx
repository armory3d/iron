package wings.wxd;

class Input {
	
	public static var started(default, default):Bool;
	public static var touch(default, null):Bool;
	public static var released(default, default):Bool;

	public static var startedAlt(default, default):Bool;
	public static var touchAlt(default, null):Bool;
	public static var releasedAlt(default, default):Bool;

	public static var moved(default, default):Bool;

	public static var preventRelease(default, default):Bool;
	public static var preventReleaseAlt(default, default):Bool;

	public static var x(default, null):Float;
	public static var y(default, null):Float;

	public static var deltaX(default, default):Float;
	public static var deltaY(default, default):Float;
	
	public static var left:Bool;
	public static var right:Bool;
	public static var up:Bool;
	public static var down:Bool;

	public function new() {
		reset();
	}

	public static function reset() {
		x = 0;
		y = 0;

		deltaX = 0;
		deltaY = 0;

		started = false;
		touch = false;
		released = false;

		startedAlt = false;
		touchAlt = false;
		releasedAlt = false;

		moved = false;

		preventRelease = false;
		preventReleaseAlt = false;

		left = right = up = down = false;
	}
	
	public static function onTouchBegin() {
		touch = true;
		started = true;
	}
	
	public static function onTouchEnd() {
		touch = false;

		if (!preventRelease) released = true;
		else preventRelease = false;
	}

	public static function onTouchAltBegin() {
		touchAlt = true;
		startedAlt = true;
	}
	
	public static function onTouchAltEnd() {
		touchAlt = false;
		
		if (!preventReleaseAlt) releasedAlt = true;
		else preventReleaseAlt = false;
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
	
	public static function update(_x:Float, _y:Float) {
		// TODO: check first frame delta
		deltaX = _x - x;
		deltaY = _y - y;

		x = _x;
		y = _y;
		moved = true;
	}
}
