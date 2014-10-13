package fox.trait2d.util;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.trait.Transform;
import fox.trait.Input;

class TapTrait extends Trait implements IUpdateable {

	@inject
	var transform:Transform;

	@inject
	var input:Input;

	public var onTap:Dynamic;
	var args:Dynamic;

	var propagated:Bool = false;
	var started:Bool = false;

	public function new(onTap:Dynamic, args:Dynamic = null) {
		super();

		this.onTap = onTap;
		this.args = args;
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
			if (onTap != null) {
				if (args == null) onTap();
				else onTap(args);
			}
			started = false;
		}
	}
}
