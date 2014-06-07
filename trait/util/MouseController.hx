package wings.trait.util;

import wings.sys.Input;
import wings.core.IUpdateTrait;
import wings.core.Trait;
import wings.trait.Transform;

class MouseController extends Trait implements IUpdateTrait {

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
