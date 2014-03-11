package wings.w2d.shapes;

import kha.Painter;
import kha.Color;

class CrossShape extends Shape {

	public function new(x:Float, y:Float, w:Float, h:Float, color:Int = 0xff000000) {
		super(x, y);

		this.w = w;
		this.h = h;
		this.color = color;
	}

	public override function render(painter:Painter) {

		painter.setColor(Color.fromValue(color));

		painter.drawLine(_x, _y, _x + w, _y + h, 2);
		painter.drawLine(_x + w, _y, _x, _y + h, 2);

		super.render(painter);
	}
}
