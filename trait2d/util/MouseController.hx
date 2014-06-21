package wings.trait2d.util;

import wings.core.IUpdateable;
import wings.core.Trait;
import wings.trait.Transform;
import wings.trait.Input;

class MouseController extends Trait implements IUpdateable {

	@inject
	var transform:Transform;

	@inject
	var input:Input;

	public function new() {
		super();
	}

	public function update() {

		transform.x = input.x;
		transform.y = input.y;
	}
}
