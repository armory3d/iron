package wings.w2d.ui;

import wings.w2d.Object2D;
import wings.w2d.shapes.RectShape;
import wings.w2d.Text2D;

class Button extends Tapable {

	public function new(title:String, onTap:Void->Void) {

		super(onTap);

		// Rect
		addChild(new RectShape(0, 0, 100, 35, 0xffffffff));

		// Title
		addChild(new Text2D(title, Theme.FONT, 50, 10, 0xff000000, TextAlign.Center));
	}
}
