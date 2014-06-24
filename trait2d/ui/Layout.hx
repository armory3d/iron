package wings.trait2d.ui;

import wings.core.Trait;
import wings.trait.Transform;

enum LayoutType {
	Vertical; Horizontal;
}

class Layout extends Trait {

	var transforms:Array<Transform> = [];

	var type:LayoutType;
	var spacing:Float;

	public function new(type:LayoutType, spacing:Float = 0) {
		super();

		this.type = type;
		this.spacing = spacing;
	}

	@injectAdd({desc:true,sibl:false})
    public function addTransform(trait:Transform) {

    	// Align only direct children
    	if (trait.item.parentItem == item) {

			var last = transforms.length > 0 ? transforms[transforms.length - 1] : null;

			if (type == LayoutType.Vertical) {
				if (last != null) trait.y = last.y + last.h + spacing;
			}
			else if (type == LayoutType.Horizontal) {
				if (last != null) trait.x = last.x + last.w + spacing;
			}

			transforms.push(trait);
		}
    }
}