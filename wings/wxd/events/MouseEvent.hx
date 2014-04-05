package wings.wxd.events;

import wings.w2d.Object2D;
import wings.wxd.Input;

enum MouseType {
	Over;
}

class MouseEvent extends UpdateEvent {

	var type:MouseType;
	var propagated:Bool;
	var onEvent:Bool->Void;

	public function new(onEvent:Bool->Void, type:MouseType = null) {
		if (type == null) type = MouseType.Over;
		super(_update);

		this.type = type;
		this.onEvent = onEvent;
		propagated = false;
	}

	override public function update() {
		// TODO: input.x is 0 in first frame
		if (parent.forcedInput) Input.forced = true;

		if (Input.moved) {
			if ((type == MouseType.Over)) {
				if (Std.is(parent, Object2D)) {
					var p = cast(parent, Object2D);
					var test = p.hitTest(Input.x, Input.y) && Input.x != 0;
					if (test && !propagated) {
						onEvent(true);
						propagated = true;
					}
					else if (!test && propagated) {
						onEvent(false);
						propagated = false;
					}
				}
			}
		}

		if (parent.forcedInput) Input.forced = false;
	}

	function _update() {

	}
}
