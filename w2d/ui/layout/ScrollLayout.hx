package wings.w2d.ui.layout;

import wings.w2d.ui.layout.ListLayout;
import wings.wxd.Input;

class ScrollLayout extends ListLayout {

	var size:Float;

	public function new(size:Float, spacing:Float = 0, type:LayoutType = null) {
		super(spacing, type);

		this.size = size;

	}

	public override function addChild(child:Object2D) {
		super.addChild(child);

		// Hide elements outside of view
		// TODO: merge with code in update
		if (type == LayoutType.Vertical) {
			var yy = child.y;
			var h = child.h;
			if (yy > size || yy + h < 0) {
				child.visible = false;
			}
		}
		else {
			var xx = child.x;
			var w = child.w;
			if (xx > size || xx + w < 0) {
				child.visible = false;
			}
		}
	}

	public override function update() {
		super.update();

		// Wheel scrolling
		if (Input.wheel != 0/* && hitTest(Input.x, Input.y)*/) {
			Input.wheel *= 5;

			// Scrolling bounds
			if (type == LayoutType.Vertical) {
				if (children[0].y + (Input.wheel * (-1)) > 0) {
					Input.wheel = Std.int(children[0].y);
				}
			}
			else {
				if (children[0].x + (Input.wheel * (-1)) > 0) {
					Input.wheel = Std.int(children[0].x);
				}
			}

			for (i in 0...children.length) {

				if (type == LayoutType.Vertical) {
					children[i].y -= Input.wheel;

					// Hide elements outside of view
					var yy = children[i].y;
					var h = children[i].h;
					if (yy > size || yy + h < 0) {
						children[i].visible = false;
					}
					else {
						children[i].visible = true;
					}
				}
				else {
					children[i].x -= Input.wheel;

					var xx = children[i].x;
					var w = children[i].w;
					if (xx > size || xx + w < 0) {
						children[i].visible = false;
					}
					else {
						children[i].visible = true;
					}
				}
			}

			// Prevent other scrolling activity
			Input.wheel = 0;
		}
	}
}
