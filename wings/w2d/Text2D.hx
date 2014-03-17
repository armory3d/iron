package wings.w2d;

import kha.Painter;
import kha.Image;
import kha.Font;
import wings.wxd.Color;

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
		this.color = color;
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
		
		painter.setColor(_color);
		painter.setFont(font);
		
		// Draw text
		if (align == TextAlign.Left) painter.drawString(text, _x, _y);
		else if (align == TextAlign.Center) painter.drawString(text, _x - w / 2, _y);
		else painter.drawString(text, _x - w, _y);
	}
}
