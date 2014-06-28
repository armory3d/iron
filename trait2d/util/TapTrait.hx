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
	var started:Bool = false;

	public function new(onTap:Void->Void) {
		super();

		this.onTap = onTap;
	}

	public function update() {

		var hitTest = transform.hitTest(input.x, input.y);

    	if (input.moved) {
	    	if (hitTest && !propagated) {
	    		propagated = true;
				transform.a = transform.a - 0.2;
			}
			else if (!hitTest && propagated) {
				propagated = false;
				if (transform.a <= 0.8) transform.a = transform.a + 0.2;
			}
		}

		if (hitTest && input.started) {
			started = true;
		}
		else if (hitTest && input.released && started) {
			if (onTap != null) onTap();
			started = false;
		}
	}
}
