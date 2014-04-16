package wings.w2d.shapes;

import kha.Painter;
import kha.Color;

class PolyShape extends Shape {

	var sides:Int;

	public function new(x:Float, y:Float, w:Float, h:Float, color:Int = 0xffffffff, sides:Int = 3, rotation:Float = 0) {
		super(x, y);

		this.w = w;
		this.h = h;
		this.color = color;
		this.sides = sides;
		this.rotation = rotation;
	}

	public override function render(painter:Painter) {

		painter.setColor(Color.fromValue(color));
		
		// TODO: proper coords & w:h ratio
		if (rotation == 0) {	// Facing down
			painter.fillTriangle(_x - w / 2, _y - h / 4, _x + w / 2, _y - h / 4, _x, _y + h / 4);
		}
		else if (rotation == 90) {
			painter.fillTriangle(_x + w / 4, _y - h / 2, _x + w / 4, _y + h / 2, _x - w / 4, _y);
		}
		else if (rotation == 180) {
			painter.fillTriangle(_x - w / 2, _y + h / 4, _x + w / 2, _y + h / 4, _x, _y - h / 4);
		}
		else if (rotation == 270) {
			painter.fillTriangle(_x - w / 4, _y - h / 2, _x - w / 4, _y + h / 2, _x + w / 4, _y);
		}

		super.render(painter);
	}
}
