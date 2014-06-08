package wings.trait2d.ui;

import kha.Painter;

import wings.core.Trait;
import wings.core.IUpdateable;
import wings.core.IRenderable2D;
import wings.sys.Input;
import wings.trait.Transform;

class Button extends Trait implements IUpdateable implements IRenderable2D {

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

    public function update() {
    	if (Input.released && transform.hitTest(Input.x, Input.y)) {
    		Input.released = false;
    		onTap();
    	}
    }

	public function render(painter:Painter) {
		painter.setColor(transform.color);
		painter.fillRect(transform.absx, transform.absy, transform.w, transform.h);		
	}
}
