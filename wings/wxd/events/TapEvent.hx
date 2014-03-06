package wings.wxd.events;

import wings.w2d.Object2D;
import wings.wxd.Input;

class TapEvent extends UpdateEvent {

	var touched:Bool;

	public function new(onEvent:Void->Void) {
		super(onEvent);

		touched = false;
	}

	override public function update() {
		if (Input.touch && !touched) {
			if (Std.is(parent, Object2D)) {
				var p = cast(parent, Object2D);
				if (p.hitTest(Input.x, Input.y)) {
					touched = true;
					onUpdate();
				}
			}
		}
		else if (!Input.touch) touched = false;
	}
}
