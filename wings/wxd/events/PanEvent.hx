package wings.wxd.events;

import wings.w2d.Object2D;
import wings.math.Rect;
import wings.wxd.Input;

class PanEvent extends UpdateEvent {

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

		if (Input.touch) {

			// Move pos
			rect.x += Input.deltaX * power * reverse;
			rect.y += Input.deltaY * power * reverse;
		}
	}

	function _update() {

	}
}