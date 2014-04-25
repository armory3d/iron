package wings.w2d.ui;

import wings.w2d.Object2D;
import wings.w2d.shapes.RectShape;
import wings.w2d.Text2D;

class Button extends Tapable {

	public function new(title:String, w:Float, h:Float, onTap:Void->Void) {

		super(onTap);

		// Rect
		addChild(new RectShape(0, 0, w, h, 0xffeeeeee));

		// Title
		addChild(new Text2D(title, Theme.FONT, w / 2, h / 3.5, 0xff000000, TextAlign.Center));
	}
}
