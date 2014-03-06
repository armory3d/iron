package wings.w2d.ui;

import wings.wxd.events.TapEvent;
import wings.w2d.shapes.RectShape;
import wings.w2d.Text2D;

class Button extends RectShape {

	public var text:Text2D;

	public function new(title:String, w:Int, h:Int, color:Int, onTap:Void->Void) {
		super(0, 0, w, h, color);

		text = new Text2D(title, Theme.FONT, 0, 0, 0xffffffff);
		addChild(text);

		addEvent(new TapEvent(onTap));
	}
}
