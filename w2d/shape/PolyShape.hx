package wings.w2d.shape;

import kha.Painter;
import kha.Color;

class PolyShape extends Shape {

	var sides:Int;

	public function new(x:Float, y:Float, w:Float, h:Float, color:Int = 0xffffffff, sides:Int = 3, rotation:Float = 0) {
		super(x, y);

		this.w = w;
		this.h = h;
		this.rel.color = Color.fromValue(color);
		this.sides = sides;
		this.rotation.angle = rotation;
	}

	public override function render(painter:Painter) {

		painter.setColor(abs.color);
		
		var p1X = 0.0;
		var p1Y = 0.0;
		var p2X = 0.0;
		var p2Y = 0.0;
		var p3X = 0.0;
		var p3Y = 0.0;

		// TODO: proper coords & w:h ratio
		if (rotation.angle == 0) {	// Facing down
			p1X = abs.x - w / 2;
			p1Y = abs.y - h / 4;

			p2X = abs.x + w / 2;
			p2Y = abs.y - h / 4;

			p3X = abs.x;
			p3Y = abs.y + h / 4;
		}
		else if (rotation.angle == 90) {
			p1X = abs.x + w / 4;
			p1Y = abs.y - h / 2;

			p2X = abs.x + w / 4;
			p2Y = abs.y + h / 2;

			p3X = abs.x - w / 4;
			p3Y = abs.y;
		}
		else if (rotation.angle == 180) {
			p1X = abs.x - w / 2;
			p1Y = abs.y + h / 4;

			p2X = abs.x + w / 2;
			p2Y = abs.y + h / 4;

			p3X = abs.x;
			p3Y = abs.y - h / 4;
		}
		else if (rotation.angle == 270) {
			p1X = abs.x - w / 4;
			p1Y = abs.y - h / 2;

			p2X = abs.x - w / 4;
			p2Y = abs.y + h / 2;

			p3X = abs.x + w / 4;
			p3Y = abs.y;
		}

		painter.fillTriangle(p1X * abs.scaleX, p1Y * abs.scaleY,
							 p2X * abs.scaleX, p2Y * abs.scaleY,
							 p3X * abs.scaleX, p3Y * abs.scaleY);

		super.render(painter);
	}
}
