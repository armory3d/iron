package wings.w2d.shapes;

import kha.Painter;
import kha.Color;

class PolyShape extends Shape {

	var sides:Int;

	public function new(x:Float, y:Float, w:Float, h:Float, color:Int = 0xffffffff, sides:Int = 3, rotation:Float = 0) {
		super(x, y);

		this.w = w;
		this.h = h;
		this.rel.color = kha.Color.fromValue(color);
		this.sides = sides;
		this.rotation.angle = rotation;
	}

	public override function render(painter:Painter) {

		painter.setColor(color);
		
		// TODO: proper coords & w:h ratio
		if (rotation.angle == 0) {	// Facing down
			painter.fillTriangle(abs.x - w / 2, abs.y - h / 4, abs.x + w / 2, abs.y - h / 4, abs.x, abs.y + h / 4);
		}
		else if (rotation.angle == 90) {
			painter.fillTriangle(abs.x + w / 4, abs.y - h / 2, abs.x + w / 4, abs.y + h / 2, abs.x - w / 4, abs.y);
		}
		else if (rotation.angle == 180) {
			painter.fillTriangle(abs.x - w / 2, abs.y + h / 4, abs.x + w / 2, abs.y + h / 4, abs.x, abs.y - h / 4);
		}
		else if (rotation.angle == 270) {
			painter.fillTriangle(abs.x - w / 4, abs.y - h / 2, abs.x - w / 4, abs.y + h / 2, abs.x + w / 4, abs.y);
		}

		super.render(painter);
	}
}
