package wings.trait.ui;

import kha.Painter;

import wings.core.Trait;
import wings.core.IRenderTrait;

class Button extends Trait implements IRenderTrait {

	public var transform:Transform;

	var onTap:Void->Void;

	public function new(onTap:Void->Void) {
		super();

		this.onTap = onTap;
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;
        transform.w = 100;
        transform.h = 50;
    }

	public function render(painter:Painter) {
		painter.setColor(transform.color);
		painter.fillRect(transform.absx, transform.absy, transform.w, transform.h);		
	}
}
