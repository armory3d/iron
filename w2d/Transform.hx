package wings.w2d;

import kha.Color;
import kha.Rotation;
import kha.math.Vector2;
import wings.math.Rect;
import wings.w2d.Object2D;

class Transform extends Rect {

	public var changed:Bool;

	public var rotation(default, set):Rotation;

	// Blending
	public var color(default, set):Color;
	public var r(get, set):Float;
	public var g(get, set):Float;
	public var b(get, set):Float;
	public var a(get, set):Float;

	public function new(parent:Object2D) {
		super(parent);
		reset();
	}

	public function reset() {

		x = y = w = h = 0;

		scaleX = scaleY = 1;

		color = Color.fromValue(0xffffffff);
		
		rotation = new Rotation(new Vector2(0, 0), 0);

		changed = true;
	}

	override function set_x(f:Float):Float {
		changed = true;
		return x = f;
	}

	override function set_y(f:Float):Float {
		changed = true;
		return y = f;
	}

	inline function set_rotation(r:Rotation):Rotation {
		changed = true;
		return rotation = r;
	}

	override function set_w(f:Float):Float {
		changed = true;
		return w = f;
	}

	override function set_h(f:Float):Float {
		changed = true;
		return h = f;
	}

	override function set_scaleX(f:Float):Float {
		changed = true;
		return scaleX = f;
	}

	override function set_scaleY(f:Float):Float {
		changed = true;
		return scaleY = f;
	}

	inline function set_color(c:Color):Color {
		changed = true;
		return color = c;
	}

	inline function get_r():Float {
		return color.R;
	}

	inline function set_r(f:Float):Float {
		changed = true;
		return color.R = f;
	}

	inline function get_g():Float {
		return color.G;
	}

	inline function set_g(f:Float):Float {
		changed = true;
		return color.G = f;
	}

	inline function get_b():Float {
		return color.B;
	}

	inline function set_b(f:Float):Float {
		changed = true;
		return color.B = f;
	}

	inline function get_a():Float {
		return color.A;
	}

	inline function set_a(f:Float):Float {
		changed = true;
		return color.A = f;
	}
}
