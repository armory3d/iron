package wings.w2d.shape;

import kha.Painter;
import kha.Color;

class RectShape extends Shape {

	public function new(x:Float, y:Float, w:Float, h:Float, color:Int = 0xffffffff) {
		super(x, y);

		this.w = w;
		this.h = h;
		this.color = Color.fromValue(color);
	}

	public override function render(painter:Painter) {

		if (!visible) return;

		painter.setColor(abs.color);
		painter.fillRect(abs.x /* * parent.scaleX*/, abs.y /* * parent.scaleY*/,
						 w * abs.scaleX, h * abs.scaleY);

		super.render(painter);
	}
}
