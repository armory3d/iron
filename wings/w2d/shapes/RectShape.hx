package wings.w2d.shapes;

import kha.Painter;
import kha.Color;

class RectShape extends Shape {

	public function new(x:Float = 0, y:Float = 0, w:Float, h:Float, color:Int = 0xffffffff) {
		super(x, y);

		this.w = w;
		this.h = h;
		this.color = color;
	}

	public override function render(painter:Painter) {

		painter.setColor(Color.fromValue(color));
		painter.fillRect(_x, _y, w, h);

		super.render(painter);
	}
}
