package wings.wxd.event;

class RemoveEvent extends Event {

	var onRemove:Void->Void;

	public function new(onRemove:Void->Void) {
		super();

		this.onRemove = onRemove;
	}

	override public function update() {
		
	}
}