package lue.sys;

class Input {

	public static var x(default, null):Float = 0;
	public static var y(default, null):Float = 0;
	public static var touch(default, null):Bool = false;
	public static var started(default, null):Bool = false;
	public static var released(default, null):Bool = false;
	public static var moved(default, null):Bool = false;

	public static var deltaX(default, null):Float = 0;
	public static var deltaY(default, null):Float = 0;

	public function new() {
            kha.input.Mouse.get().notify(downListener, upListener, moveListener, null);
            //kha.input.Surface.get().notify(touchStartListener, touchEndListener, touchMoveListener);
	}

	public static function end() {
		released = false;
		started = false;
		moved = false;
		deltaX = 0;
		deltaY = 0;
	}

	public static function reset() {
		//x = 0;
		//y = 0;

		deltaX = 0;
		deltaY = 0;

		started = false;
		touch = false;
		released = false;
		moved = false;
	}
	
	public static function downListener(_index:Int, _x:Float, _y:Float) {
		touch = true;
		if (_index == 0) started = true;

		x = _x ;
		y = _y ;
	}
	
	public static function upListener(_index:Int, _x:Float, _y:Float) {
		touch = false;
		if (_index == 0) released = true;

		x = _x ;
		y = _y ;
	}
	
	//public static function moveListener(_x:Int, _y:Int, movementX:Int, movementY:Int) {
	public static function moveListener(_x:Int, _y:Int) {
		deltaX = _x - x;
		deltaY = _y - y;

		x = _x ;
		y = _y ;

		moved = true;
	}
}
