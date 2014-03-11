package wings.wxd.events;

import wings.w2d.Object2D;
import wings.wxd.Input;

class TapEvent extends UpdateEvent {

	public static inline var TYPE_START = 0;
	public static inline var TYPE_TOUCH = 1;
	public static inline var TYPE_RELEASE = 2;

	var type:Int;

	public function new(onEvent:Void->Void, type:Int = TYPE_RELEASE) {
		super(onEvent);

		this.type = type;
	}

	override public function update() {
		if ((type == TYPE_RELEASE && Input.released) ||
			(type == TYPE_TOUCH && Input.touch) ||
			(type == TYPE_START && Input.started)) {

			if (Std.is(parent, Object2D)) {
				var p = cast(parent, Object2D);
				if (p.hitTest(Input.x, Input.y)) {
					onUpdate();
				}
			}
		}
	}
}
