package wings.w2d.ui;

import wings.wxd.Input;
import wings.wxd.events.UpdateEvent;
import wings.w2d.shapes.RectShape;
import wings.w2d.Text2D;

class Slider extends Object2D {

	var name:String;
	var onSlide:Float->Void;

	var rect:RectShape;

	var touched:Bool;

	public function new(name:String, onSlide:Float->Void, start:Float = 0) {
		super();

		this.name = name;
		this.onSlide = onSlide;

		addChild(new RectShape(0, 0, 100, 2, 0xffffffff));

		rect = new RectShape(start * 100 - 5, -4, 10, 10, 0xffffffff);
		rect.addEvent(new UpdateEvent(onUpdate));
		addChild(rect);

		addChild(new Text2D(name, Theme.FONT, 108, -5, 0xffffffff));
	}

	function onUpdate() {
		if (Input.touch) {
			if (rect.hitTest(Input.x, Input.y)) {
				touched = true;
			}
		}
		else touched = false;

		if (touched) {
			rect.x = Input.x - _x - 5;

			if (rect.x > 100 - 5) rect.x = 100 - 5;
			else if (rect.x < 0 - 5) rect.x = 0 - 5;

			onSlide((rect.x + 5) / 100);
		}
	}
}
