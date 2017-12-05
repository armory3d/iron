package iron.math;

class Vec2 {
	public var x:Float;
	public var y:Float;

	public function new(x:Float = 0.0, y:Float = 0.0) {
		this.x = x;
		this.y = y;
	}

	public static inline function distance2df(v1x:Float, v1y:Float, v2x:Float, v2y:Float):Float {
		var vx = v1x - v2x;
		var vy = v1y - v2y;
		return Math.sqrt(vx * vx + vy * vy);
	}

	public inline function length() {
		return Math.sqrt(x * x + y * y);
	}
}
