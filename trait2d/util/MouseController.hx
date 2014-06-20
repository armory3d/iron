package wings.trait2d.util;

import wings.sys.Input;
import wings.core.IUpdateable;
import wings.core.Trait;
import wings.trait.Transform;

class MouseController extends Trait implements IUpdateable {

	@inject
	public var transform:Transform;

	public function new() {
		super();
	}

	public function update() {

		transform.x = Input.x;
		transform.y = Input.y;
	}
}
