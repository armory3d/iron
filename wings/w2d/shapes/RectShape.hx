package wings.w2d.shapes;

import kha.Painter;
import kha.Color;

class RectShape extends Shape {

	//public var shapeW:Float;
	//public var shapeH:Float;

	public function new(x:Float, y:Float, w:Float, h:Float, color:Int = 0xffffffff) {
		super(x, y);

		abs.w = w;
		abs.h = h;
		//shapeW = w;
		//shapeH = h;
		rel.color = Color.fromValue(color);
	}

	public override function render(painter:Painter) {

		painter.setColor(abs.color);
		painter.fillRect(abs.x * parent.scaleX, abs.y * parent.scaleY, w * scaleX, h * scaleY);

		super.render(painter);
	}
}
