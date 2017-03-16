package iron.system;

class Input {

	public static var x(default, null) = 0.0;
	public static var y(default, null) = 0.0;
	public static var down(default, null) = false;
	public static var down2(default, null) = false;
	public static var started(default, null) = false;
	public static var started2(default, null) = false;
	public static var released(default, null) = false;
	public static var released2(default, null) = false;
	public static var moved(default, null) = false;
	public static var occupied = false;

	public static var movementX(default, null) = 0.0;
	public static var movementY(default, null) = 0.0;
	public static var wheelDelta(default, null) = 0;
	// static var lastX = 0.0;
	// static var lastY = 0.0;

	public function new() {
		kha.input.Mouse.get().notify(downListener, upListener, moveListener, wheelListener);
	}

	public static function end() {
		started = false;
		started2 = false;
		released = false;
		released2 = false;
		moved = false;
		movementX = 0;
		movementY = 0;
		wheelDelta = 0;
	}

	public static function reset() {
		down = false;
		down2 = false;
		occupied = false;
		end();
	}
	
	public static function downListener(_index:Int, _x:Float, _y:Float) {
		if (_index == 0) {
			down = true;
			started = true;
		}
		else {
			down2 = true;
			started2 = true;
		}

		x = _x ;
		y = _y ;
	}
	
	public static function upListener(_index:Int, _x:Float, _y:Float) {
		if (_index == 0) {
			down = false;
			released = true;
		}
		else {
			down2 = false;
			released = true;
		}

		x = _x;
		y = _y;
	}
	
	public static function moveListener(_x:Int, _y:Int, _movementX:Int, _movementY:Int) {
		movementX = _movementX;
		movementY = _movementY;
		// movementX = _x - lastX;
		// movementY = _y - lastY;
		// lastX = _x;
		// lastY = _y;

		x = _x;
		y = _y;

		moved = true;
	}

	public static function wheelListener(_delta:Int) {
		wheelDelta = _delta;
	}
}
