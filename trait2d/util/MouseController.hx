package fox.trait2d.util;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.trait.Transform;
import fox.trait.Input;

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
