package fox.trait2d.effect;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.trait.Input;
import fox.trait.Transform;

class SlideTrait extends Trait implements IUpdateable {

	@inject
	var transform:Transform;

	@inject
	var input:Input;

	var slide:Bool = false;

	var size:Int;

	var lastDelta:Float = 0;

	public function new(size:Int) {
		super();

		this.size = size;
	}

	public function update() {
		
		if (input.started && input.y >= 1000) {
			slide = true;

			// Stop sliding effect
			motion.Actuate.stop(transform);
		}
		else if (input.released && slide) {
			slide = false;

			// Sliding effect
			var dist = lastDelta * 5;

			// Check bounds
			if (transform.x > 0 || transform.x < -size) {
				checkBounds();
			}
			// Slide
			else {
				var target = transform.x + dist;

				if (transform.x + dist > 0) target = 0;
				else if (transform.x + dist < -size) target = -size;

				motion.Actuate.tween(transform, 0.8, {x:target});
			}
		}

		if (slide) {
			lastDelta = input.deltaX;
			transform.x += input.deltaX;
		}
	}

	function checkBounds() {
		if (transform.x > 0) motion.Actuate.tween(transform, 0.4, {x:0});
		else if (transform.x < -size) motion.Actuate.tween(transform, 0.4, {x:-size});
	}
}
