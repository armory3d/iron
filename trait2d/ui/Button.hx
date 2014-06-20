package wings.trait2d.ui;

import kha.Painter;

import wings.core.Trait;
import wings.core.IUpdateable;
import wings.core.IRenderable2D;
import wings.trait.Transform;
import wings.trait.Input;

class Button extends Trait implements IUpdateable implements IRenderable2D {

	public var transform:Transform;

	@inject
	var input:Input;

	var text:String;
	var font:kha.Font;
	var onTap:Void->Void;

	var propagated:Bool = false;

	public function new(text:String, font:kha.Font, onTap:Void->Void) {
		super();

		this.text = text;
		this.font = font;
		this.onTap = onTap;
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;
        transform.val = 0xff4a86e8;
    }

    public function update() {

    	var test = transform.hitTest(input.x, input.y);

    	if (input.moved) {
	    	if (test && !propagated) {
	    		propagated = true;
				transform.a = transform.a - 0.2;
			}
			else if (!test && propagated) {
				propagated = false;
				if (transform.a <= 0.8) transform.a = transform.a + 0.2;
			}
		}

		if (test && input.released) {
			onTap();
		}
    }

	public function render(painter:Painter) {
		painter.setColor(transform.color);
		painter.opacity = transform.a;
		painter.fillRect(transform.absx, transform.absy, transform.w, transform.h);


		var strW = font.stringWidth(text);
		var strH = font.getHeight();

		painter.setColor(kha.Color.White);
		painter.setFont(font);
		painter.drawString(text, transform.absx + transform.w / 2 - strW / 2,
								 transform.absy + transform.h / 2 - strH / 2);
	}
}
