package wings.w2d.shape;

import kha.Painter;
import kha.Color;

class CrossShape extends Shape {

	public function new(x:Float, y:Float, w:Float, h:Float, color:Int = 0xff000000) {
		super(x, y);

		this.w = w;
		this.h = h;
		this.color = Color.fromValue(color);
	}

	public override function render(painter:Painter) {

		painter.setColor(abs.color);

		painter.drawLine(abs.x, abs.y, abs.x + w, abs.y + h, 2);
		painter.drawLine(abs.x + w, abs.y, abs.x, abs.y + h, 2);

		super.render(painter);
	}
}
