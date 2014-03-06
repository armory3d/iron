package wings.w2d.shapes;

import kha.Painter;
import kha.Color;

class CircleShape extends Shape {

	var radius:Float;

	public function new(x:Float = 0, y:Float = 0, radius:Float, color:Int) {
		super(x, y);

		this.w = radius * 2;
		this.h = radius * 2;
		this.radius = radius;
		this.color = color;
	}

	public override function render(painter:Painter) {

		painter.setColor(Color.fromValue(color));

		var triangles = 20;
		var twoPi = 2.0 * 3.14159;

		var x1 = _x, y1 = _y;
		var x2, y2;
		var x3, y3;

		for(i in 1...(triangles + 1)) { 

			x2 = radius * Math.cos((i - 1) *  twoPi / triangles) + x1; 
			y2 = radius * Math.sin((i - 1) * twoPi / triangles) + y1;

			x3 = radius * Math.cos(i *  twoPi / triangles) + x1; 
			y3 = radius * Math.sin(i * twoPi / triangles) + y1;

			painter.fillTriangle(x1, y1, x2, y2, x3, y3);
		}

		super.render(painter);
	}
}
