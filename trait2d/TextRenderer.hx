package fox.trait2d;

import kha.Font;
import kha.Painter;

import fox.core.Trait;
import fox.core.IRenderable2D;
import fox.trait.Transform;

enum TextAlign {
	Left; Center; Right;
}

class TextRenderer extends Trait implements IRenderable2D {

	public var transform:Transform;

	var font:Font;

	public var text(get, set):String;
	var texts:Array<String>;
	
	var align:TextAlign;
	var widths:Array<Float>;

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

        updateTransform();
    }

    function updateTransform() {
    	transform.w = font.stringWidth(text);
		transform.h = font.getHeight() * texts.length;

		transform.modified = true;
		transform.update();
    }

	public function render(g:kha.graphics2.Graphics) {
		g.color = transform.color;
		g.font = font;

		g.drawString(texts[0], transform.absx, transform.absy, transform.scale.x, transform.scale.y);

		// Multi-line
		for (i in 1...texts.length) {

			var textX = 0.0;

			if (align == TextAlign.Left) {
				textX = transform.absx;
			}
			else if (align == TextAlign.Center) {
				textX = transform.absx + (widths[0] - widths[i]) / 2;
			}
			else {
				textX = transform.absx + (widths[0] - widths[i]);
			}

			g.drawString(texts[i], textX, transform.absy + i * font.getHeight(), transform.scale.x, transform.scale.y);
		}
	}

	function set_text(s:String):String {
		texts = s.split("\n");
		
		if (transform != null) {
			updateTransform();
		}
		
		widths = [];
		for (t in texts) {
			widths.push(font.stringWidth(t));
		}

		return s;
	}

	function get_text():String {
		return texts[0];
	}
}
