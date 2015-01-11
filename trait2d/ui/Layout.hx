package fox.trait2d.ui;

import fox.core.Trait;
import fox.trait.Transform;

enum LayoutType {
	Vertical; Horizontal;
}

class Layout extends Trait {

	var transforms:Array<Transform> = [];

	var type:LayoutType;
	var spacing:Float = 0;
	var offsetSpacing:Float = 0;
	var offset:Float = 0;
	var lastOffset:Float = 0;

	public function new(type:LayoutType, spacing:Float = 0, offsetSpacing:Float = 0) {
		super();

		this.type = type;
		this.spacing = spacing;	// Next item
		this.offsetSpacing = offsetSpacing; // Next row/column
	}

	@injectAdd({desc:true,sibl:false})
    public function addTransform(trait:Transform) {

    	// Align only direct children
    	if (trait.item.parentItem == item) {

			var last = transforms.length > 0 ? transforms[transforms.length - 1] : null;

			if (last != null) {
				if (type == LayoutType.Vertical) {
					trait.x += offset;

					if (lastOffset != offset) {
						lastOffset = offset;
					}
					else {
						trait.y = last.y + last.h + spacing;
					}
				}
				else if (type == LayoutType.Horizontal) {
					trait.y += offset;

					if (lastOffset != offset) {
						lastOffset = offset;
					}
					else {
						trait.x = last.x + last.w + spacing;
					}
				}
			}

			transforms.push(trait);
		}
    }

    public function next() {
    	var last = transforms.length > 0 ? transforms[transforms.length - 1] : null;

		if (last != null) {
			if (type == LayoutType.Vertical) {
				offset += last.w + offsetSpacing;
			}
			else if (type == LayoutType.Horizontal) {
				offset += last.h + offsetSpacing;
			}
		}
    }
}
