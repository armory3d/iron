package wings.trait.ui;

import kha.Painter;

import wings.core.Trait;

enum LayoutType {
	Vertical; Horizontal;
}

class Layout extends Trait {

	public var transform:Transform;

	var type:LayoutType;

	public function new(type:LayoutType) {
		super();

		this.type = type;
	}

	@injectAdd({desc:true,sibl:true})
    public function addTransform(trait:Transform) {
    	if (trait.item == item) {
    		transform = trait;
    	}
    	else {
    		trait.y = transform.h;
    	}
    }
}
