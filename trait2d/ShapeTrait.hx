package wings.trait2d;

import kha.Painter;

import wings.core.Trait;
import wings.core.IRenderable2D;
import wings.trait.Transform;

enum ShapeType {
	Rect;
}

class ShapeTrait extends Trait implements IRenderable2D {

	public var transform:Transform;

	var type:ShapeType;

	public function new(type:ShapeType) {
		super();

		this.type = type;
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;
    }

	public function render(painter:Painter) {

		painter.setColor(transform.color);
		painter.fillRect(transform.absx, transform.absy, transform.w, transform.h);		
	}
}
