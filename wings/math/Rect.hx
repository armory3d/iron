package wings.math;

// Base transform
class Rect {

	public var x(default, set):Float;
	public var y(default, set):Float;

	public var w(default, set):Float;
	public var h(default, set):Float;

	public var scale(get, set):Float;
	public var scaleX(default, set):Float;
	public var scaleY(default, set):Float;

	public function new(x:Float = 0, y:Float = 0, w:Float = 0, h:Float = 0) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;

		scaleX = 1;
		scaleY = 1;
	}

	function set_x(f:Float):Float {
		return x = f;
	}

	function set_y(f:Float):Float {
		return y = f;
	}

	function set_w(f:Float):Float {
		return w = f;
	}

	function set_h(f:Float):Float {
		return h = f;
	}

	inline function get_scale():Float {
		return scaleX;
	}

	inline function set_scale(f:Float) {
		scaleX = f;
		scaleY = f;
		return f;
	}

	function set_scaleX(f:Float):Float {
		return scaleX = f;
	}

	function set_scaleY(f:Float):Float {
		return scaleY = f;
	}
}
