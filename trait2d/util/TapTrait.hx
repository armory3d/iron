package wings.trait2d.util;

import wings.core.IUpdateable;
import wings.core.Trait;
import wings.trait.Transform;
import wings.trait.Input;

class TapTrait extends Trait implements IUpdateable {

	@inject
	var transform:Transform;

	@inject
	var input:Input;

	public var onTap:Void->Void;

	var propagated:Bool = false;

	public function new(onTap:Void->Void) {
		super();

		this.onTap = onTap;
	}

	public function update() {

		var test = transform.hitTest(input.x, input.y);

    	if (input.moved) {
	    	if (test && !propagated) {
	    		propagated = true;
				transform.a = transform.a - 0.2;
			}
			else if (!test && propagated) {
				propagated = false;
				if (transform.a <= 0.8) transform.a = transform.a + 0.2;
			}
		}

		if (test && input.released) {
			onTap();
		}
	}
}
