package wings.w2d.ui;

import wings.wxd.events.TapEvent;
import wings.w2d.Text2D;

class ButtonUI extends ObjectUI {

	var text:Text2D;

	public function new(title:String, onTap:Void->Void, startColor:Int = 0xffe61d5f) {
		super(startColor);

		// Text
		text = new Text2D(title, Theme.FONT, 20, 10, 0xffe5e5e5);
		addChild(text);

		addEvent(new TapEvent(onTap));
	}

	public override function hitTest(x:Float, y:Float):Bool {
		if (x >= this._x && x <= this._x + shapeW &&
			y >= this._y && y <= this._y + shapeH) {
			return true;
		}

		return false;
	}
}
