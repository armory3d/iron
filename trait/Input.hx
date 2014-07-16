package wings.trait;

import wings.core.Trait;

class Input extends Trait {

	public var layer:Int;

	public var x(get, never):Float;
	public var y(get, never):Float;
	public var touch(get, never):Bool;
	public var started(get, never):Bool;
	public var released(get, never):Bool;
	public var moved(get, never):Bool;

	public var deltaX(get, never):Float;
	public var deltaY(get, never):Float;

	public function new(layer:Int = 0) {
		super();

		this.layer = layer;
	}

	inline function get_x():Float { _layer == layer ? return _x : return 0; }

	inline function get_y():Float { _layer == layer ? return _y : return 0; }

	inline function get_touch():Bool { _layer == layer ? return _touch : return false; }

	inline function get_started():Bool { _layer == layer ? return _started : return false; }

	inline function get_released():Bool { _layer == layer ? return _released : return false; }

	inline function get_moved():Bool { _layer == layer ? return _moved : return true; }

	inline function get_deltaX():Float { _layer == layer ? return _deltaX : return 0; }

	inline function get_deltaY():Float { _layer == layer ? return _deltaY : return 0; }


	public static var _layer:Int = 0;
	
	public static var _started(default, null):Bool = false;
	public static var _touch(default, null):Bool = false;
	public static var _released(default, null):Bool = false;
	public static var _moved(default, null):Bool = false;

	public static var _x(default, null):Float;
	public static var _y(default, null):Float;

	public static var _deltaX(default, null):Float = 0;
	public static var _deltaY(default, null):Float = 0;

	public static function update() {
		// TODO: make setters private
		_released = false;
		_started = false;
		_moved = false;
		_deltaX = 0;
		_deltaY = 0;
	}

	public static function reset() {
		//_x = 0;
		//_y = 0;

		_deltaX = 0;
		_deltaY = 0;

		_started = false;
		_touch = false;
		_released = false;
		_moved = false;
	}
	
	public static function onTouchBegin(x:Float, y:Float) {
		_touch = true;
		_started = true;

		_x = x;
		_y = y;
	}
	
	public static function onTouchEnd(x:Float, y:Float) {
		_touch = false;
		_released = true;

		_x = x;
		_y = y;
	}
	
	public static function onMove(x:Float, y:Float) {
		_deltaX = x - _x;
		_deltaY = y - _y;

		_x = x;
		_y = y;

		_moved = true;
	}
}
