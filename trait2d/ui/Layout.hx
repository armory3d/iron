package wings.trait2d.ui;

import kha.Painter;

import wings.core.Trait;
import wings.trait.Transform;

enum LayoutType {
	Vertical; Horizontal;
}

class Layout extends Trait {

	public var transform:Transform;

	var type:LayoutType;
	var spacing:Float;

	public function new(type:LayoutType, spacing:Float = 0) {
		super();

		this.type = type;
		this.spacing = spacing;
	}

	@injectAdd({desc:true,sibl:true})
    public function addTransform(trait:Transform) {

    	if (trait.item == item) {
    		transform = trait;
    	}
    	else {
    		trait.y = transform.absh + spacing;
    		transform.updateSize();
    	}
    }
}
