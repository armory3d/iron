package wings.w2d.shapes;

import wings.w2d.Object2D;

class Shape extends Object2D {

	public var color:Int;

	public function new(x:Float = 0, y:Float = 0) {
		super();

		this.x = x;
		this.y = y;
	}
}
