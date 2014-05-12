package wings.wxd.event;

import wings.w2d.Object2D;
import wings.wxd.Input;

enum TapType {
	Start; Touch; Release;
}

class TapEvent extends UpdateEvent {

	var type:TapType;

	var touchStarted:Bool;

	public function new(onEvent:Void->Void, type:TapType = null) {
		if (type == null) type = TapType.Release;
		super(onEvent);

		this.type = type;
		touchStarted = false;
	}

	override public function update() {
		if (parent.forcedInput) Input.forced = true;

		// Tap types
		if ((type == TapType.Release && Input.released && touchStarted) ||
			(type == TapType.Touch && Input.touch) ||
			(type == TapType.Start && Input.started)) {

			if (Std.is(parent, Object2D)) {
				var p = cast(parent, Object2D);
				if (p.hitTest(Input.x, Input.y)) {
					onUpdate();
				}
			}
		}

		// Release tap event only when touch starts over object
		// TODO: merge into one block
		if ((type == TapType.Release && Input.started && !touchStarted)) {
			if (Std.is(parent, Object2D)) {
				
				var p = cast(parent, Object2D);
				if (p.hitTest(Input.x, Input.y)) {
					touchStarted = true;
				}
				else touchStarted = false;
			}
		}

		if (parent.forcedInput) Input.forced = false;
	}
}
