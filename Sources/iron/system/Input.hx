package iron.system;

class Input {

	public static var x(default, null):Float = 0;
	public static var y(default, null):Float = 0;
	public static var touch(default, null) = false;
	public static var touch2(default, null) = false;
	public static var started(default, null) = false;
	public static var started2(default, null) = false;
	public static var released(default, null) = false;
	public static var released2(default, null) = false;
	public static var moved(default, null) = false;
	public static var occupied = false;

	public static var deltaX(default, null):Float = 0;
	public static var deltaY(default, null):Float = 0;

	public function new() {
		kha.input.Mouse.get().notify(downListener, upListener, moveListener, null);
	}

	public static function end() {
		released = false;
		released2 = false;
		started = false;
		started2 = false;
		moved = false;
		deltaX = 0;
		deltaY = 0;
	}

	public static function reset() {
		started = false;
		started2 = false;
		touch = false;
		touch2 = false;
		released = false;
		released2 = false;
		moved = false;
		occupied = false;
		deltaX = 0;
		deltaY = 0;
	}
	
	public static function downListener(_index:Int, _x:Float, _y:Float) {
		if (_index == 0) {
			touch = true;
			started = true;
		}
		else {
			touch2 = true;
			started2 = true;
		}

		x = _x ;
		y = _y ;
	}
	
	public static function upListener(_index:Int, _x:Float, _y:Float) {
		if (_index == 0) {
			touch = false;
			released = true;
		}
		else {
			touch2 = false;
			released = true;
		}

		x = _x ;
		y = _y ;
	}
	
	public static function moveListener(_x:Int, _y:Int, movementX:Int, movementY:Int) {
		deltaX = _x - x;
		deltaY = _y - y;

		x = _x ;
		y = _y ;

		moved = true;
	}
}
