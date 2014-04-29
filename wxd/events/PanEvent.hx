package wings.wxd.events;

import wings.w2d.Object2D;
import wings.math.Rect;
import wings.wxd.Input;

class PanEvent extends UpdateEvent {

	var rect:Rect;
	var power:Float;
	var reverse:Int = 1;
	var stayOnScreen:Bool;

	public function new(rect:Rect, power:Float = 1, reversed:Bool = false,
						stayOnScreen:Bool = false) {
		super(_update);

		this.rect = rect;
		this.power = power;
		this.stayOnScreen = stayOnScreen;

		// Flip axes
		if (reversed) reverse = -1;
	}

	override public function update() {

		if (Input.touch) {

			// Move pos
			rect.x += Input.deltaX * power * reverse * (1 + (1 - rect.scale)); // * rect.scale
			rect.y += Input.deltaY * power * reverse * (1 + (1 - rect.scale));

			if (stayOnScreen) {

				// TODO: unify
				// Out of bounds
				if (reverse == -1) {
					// TODO: proper bounds
					var w = cast(parent, wings.w2d.Image2D).image.width;
					var h = cast(parent, wings.w2d.Image2D).image.height;

					if (rect.x < 0) rect.x = 0;
					else if (rect.x + rect.w * rect.scale > w) rect.x = w - rect.w * rect.scale;

					if (rect.y < 0) rect.y = 0;
					else if (rect.y + rect.h * rect.scale > h) rect.y = h - rect.h * rect.scale;
				}
				else {
					var w = cast(parent, wings.w2d.Object2D).w;
					var h = cast(parent, wings.w2d.Object2D).h;

					if (rect.x > 0) rect.x = 0;
					else if (rect.x + w * rect.scale < Pos.w) rect.x = Pos.w - w * rect.scale;

					if (rect.y > 0) rect.y = 0;
					else if (rect.y + h * rect.scale < Pos.h) rect.y = Pos.h - h * rect.scale;
				}
			}
		}
	}

	function _update() {

	}
}