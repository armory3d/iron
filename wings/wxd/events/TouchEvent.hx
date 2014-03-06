package wings.wxd.events;

import wings.wxd.Input;

class TouchEvent extends UpdateEvent {

	public function new(onUpdate:Void->Void) {
		super(onUpdate);
	}

	override public function update() {
		if (Input.touch) {
			if (parent.hitTest(Input.x, Input.y)) {
				onUpdate();
			}
		}
	}
}
