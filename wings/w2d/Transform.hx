package wings.w2d;

import kha.Color;
import kha.Rotation;
import kha.math.Vector2;

class Transform {

	public var changed:Bool;

	public var x(default, set):Float;
	public var y(default, set):Float;

	public var rotation(default, set):Rotation;

	public var w(default, set):Float;
	public var h(default, set):Float;

	public var scaleX(default, set):Float;
	public var scaleY(default, set):Float;

	// Blending
	public var color(default, set):Color;

	public function new() {
		
		reset();
	}

	public function reset() {

		x = y = w = h = 0;

		color = Color.fromValue(0xffffffff);
		
		rotation = new Rotation(new Vector2(0, 0), 0);

		changed = true;
	}

	public function hitTest(x:Float, y:Float):Bool {
		if (x >= this.x && x <= this.x + w &&
			y >= this.y && y <= this.y + h) {
			return true;
		}

		return false;
	}

	inline function set_x(f:Float):Float {
		changed = true;
		return x = f;
	}

	inline function set_y(f:Float):Float {
		changed = true;
		return y = f;
	}

	inline function set_rotation(r:Rotation):Rotation {
		changed = true;
		return rotation = r;
	}

	inline function set_w(f:Float):Float {
		changed = true;
		return w = f;
	}

	inline function set_h(f:Float):Float {
		changed = true;
		return h = f;
	}

	inline function set_scaleX(f:Float):Float {
		changed = true;
		return scaleX = f;
	}

	inline function set_scaleY(f:Float):Float {
		changed = true;
		return scaleY = f;
	}

	inline function set_color(c:Color):Color {
		changed = true;
		return color = c;
	}
}
