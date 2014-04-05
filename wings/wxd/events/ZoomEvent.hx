package wings.wxd.events;

import wings.w2d.Object2D;
import wings.math.Rect;
import wings.wxd.Input;

class ZoomEvent extends UpdateEvent {

	var rect:Rect;
	var power:Float;
	var reverse:Int = 1;

	public function new(rect:Rect, power:Float = 1, reversed:Bool = false) {
		super(_update);

		this.rect = rect;
		this.power = power;

		// Flip axes
		if (reversed) reverse = -1;
	}

	override public function update() {

		if (Input.wheel != 0) {
			if (Std.is(parent, Object2D)) {

				// Scale by wheel
				var oldScale = rect.scale;
				rect.scale += Input.wheel / 200 * power * reverse;
				
				// Move pos
				var obj:Object2D = cast(parent);

				rect.x += (obj.w * oldScale - obj.w * rect.scale) / 4;
				rect.y += (obj.h * oldScale - obj.h * rect.scale) / 4;
			}
		}
	}

	function _update() {

	}
}