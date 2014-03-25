package wings.w2d;

import kha.Painter;
import kha.Image;
import kha.Font;
import kha.Color;

enum TextAlign {
	Left; Center; Right;
}

class Text2D extends Object2D {

	public var text(default, set):String;
	var font:Font;
	var align:TextAlign;

	public function new(text:String, font:Font, x:Float = 0, y:Float = 0, color:Int = 0xff000000,
						align:TextAlign = null) {
		if (align == null) align = TextAlign.Left;

		super();

		this.font = font;
		this.text = text;
		this.color = Color.fromValue(color);
		this.align = align;

		this.x = x;
		this.y = y;

		w = font.stringWidth(text);
		h = font.getHeight();
	}

	function set_text(s:String):String {
		text = s;
		w = font.stringWidth(text);
		return s;
	}

	public override function render(painter:Painter) {
		super.render(painter);
		
		painter.setColor(color);
		painter.setFont(font);
		
		// Draw text
		if (align == TextAlign.Left) painter.drawString(text, abs.x, abs.y);
		else if (align == TextAlign.Center) painter.drawString(text, abs.x - w / 2, abs.y);
		else painter.drawString(text, abs.x - w, abs.y);
	}
}
