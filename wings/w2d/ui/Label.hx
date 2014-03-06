package wings.w2d.ui;

import wings.w2d.Text2D;
import wings.w2d.shapes.RectShape;

class Label extends RectShape {

	public var text:Text2D;

	public function new(title:String, w:Int, h:Int) {
		super(0, 0, w, h, 0xffffffff);

		text = new Text2D(title, Theme.FONT, 0, 0, 0xff000000);
		addChild(text);
	}
}
