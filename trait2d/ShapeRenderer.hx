package wings.trait2d;

import wings.core.Trait;
import wings.core.IRenderable2D;
import wings.trait.Transform;

enum ShapeType {
	Rect;
}

class ShapeRenderer extends Trait implements IRenderable2D {

	public var transform:Transform;

	var type:ShapeType;

	public function new(type:ShapeType = null) {
		if (type == null) type = ShapeType.Rect;

		super();

		this.type = type;
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;
    }

	public function render(g:kha.graphics2.Graphics) {

		g.color = transform.color;
		g.fillRect(transform.absx, transform.absy, transform.w, transform.h);		
	}
}
