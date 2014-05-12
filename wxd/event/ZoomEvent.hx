package wings.wxd.event;

import wings.w2d.Object2D;
import wings.math.Rect;
import wings.wxd.Input;

class ZoomEvent extends UpdateEvent {

	var rect:Rect;
	var power:Float;
	var minScale:Float;
	var maxScale:Float;
	var reverse:Int = 1;

	public function new(rect:Rect, power:Float = 1, reversed:Bool = false,
						minScale:Float = 1, maxScale:Float = 1) {
		super(_update);

		this.rect = rect;
		this.power = power;
		this.minScale = minScale;
		this.maxScale = maxScale;

		// Flip axes
		if (reversed) reverse = -1;
	}

	override public function update() {

		if (Input.wheel != 0) {
			if (Std.is(parent, Object2D)) {

				// Scale by wheel
				var oldScale = rect.scale;
				rect.scale += Input.wheel / 200 * power * reverse;

				// Clamp
				if (rect.scale < minScale) rect.scale = minScale;
				else if (rect.scale > maxScale) rect.scale = maxScale;
				
				// Move pos
				var obj:Object2D = cast(parent);

				rect.x += (obj.w * oldScale - obj.w * rect.scale) / 2;
				rect.y += (obj.h * oldScale - obj.h * rect.scale) / 2;


				// TODO: unify with pan event
				//if (stayOnScreen) {
					if (reverse == -1) {
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
				//}
			}
		}
	}

	function _update() {

	}
}