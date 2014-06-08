package wings.trait2d;

import kha.Font;
import kha.Painter;
import kha.Color;

import wings.core.Trait;
import wings.core.IRenderable2D;
import wings.trait.Transform;

enum TextAlign {
	Left; Center; Right;
}

class TextRenderer extends Trait implements IRenderable2D {

	public var transform:Transform;

	var font:Font;
	var text:String;
	var align:TextAlign;

	public function new(text:String, font:Font, align:TextAlign = null) {
		super();

		if (align == null) align = TextAlign.Left;

		this.font = font;
		this.text = text;
		this.align = align;
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.w = font.stringWidth(text);
		transform.h = font.getHeight();
    }

	public function render(painter:Painter) {
		painter.setColor(transform.color);
		painter.setFont(font);

		var textX = 0.0;

		if (align == TextAlign.Left) {
			textX = transform.absx;
		}
		else if (align == TextAlign.Center) {
			textX = transform.absx - transform.w / 2;
		}
		else {
			textX = transform.absx - transform.w;
		}

		painter.drawString(text, textX, transform.absy);
	}
}
