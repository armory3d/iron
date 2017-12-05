package iron.math;

class Vec3 {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function length() {
		return Math.sqrt(x * x + y * y + z * z);
	}
}
