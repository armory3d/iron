package wings.w2d.ui;

import wings.w2d.Object2D;
import wings.w2d.shape.RectShape;
import wings.w2d.Text2D;

class Button extends Tapable {

	public function new(title:String, w:Float, h:Float, onTap:Void->Void, x:Float = 0, y:Float = 0,
						forcedInput:Bool = false) {

		super(onTap);

		// Rect
		addChild(new RectShape(0, 0, w, h, 0xff4a86e8));

		// Title
		addChild(new Text2D(title, Theme.Fontb18, w / 2, h / 3.5, 0xffffffff, TextAlign.Center));

		this.forcedInput = forcedInput;
		this.x = x;
		this.y = y;
	}
}
