package wings.wxd.event;

class UpdateEvent extends Event {

	var onUpdate:Void->Void;

	public function new(onUpdate:Void->Void) {
		super();

		this.onUpdate = onUpdate;
	}

	override public function update() {
		onUpdate();
	}
}
