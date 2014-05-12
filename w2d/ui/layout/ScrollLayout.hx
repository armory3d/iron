package wings.w2d.ui.layout;

import wings.w2d.ui.layout.ListLayout;
import wings.wxd.Input;

class ScrollLayout extends ListLayout {

	var size:Float;

	public function new(size:Float, spacing:Float = 0, type:ListType = null) {
		super(spacing, type);

		this.size = size;

	}

	public override function addChild(child:Object2D) {
		super.addChild(child);
	}

	public override function update() {
		super.update();

		// Wheel scrolling
		if (Input.wheel != 0 && hitTest(Input.x, Input.y)) {

			// Move elements
			for (i in 0...children.length) {

				if (type == ListType.Vertical) {
					children[i].y -= Input.wheel;

					// Hide elements outside of view
					if (children[i].y > size || children[i].y < 0) {
						children[i].visible = false;
					}
					else {
						children[i].visible = true;
					}
				}
				else {
					// TODO: unify with vertical
					children[i].x -= Input.wheel;

					if (children[i].x > size || children[i].x < 0) {
						children[i].visible = false;
					}
					else {
						children[i].visible = true;
					}
				}
			}

			// TODO: proper wheel control
			Input.wheel = 0;
		}
	}
}
