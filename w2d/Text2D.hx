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

	// TODO: use origin instead
	var textAlign:TextAlign;

	public function new(text:String, font:Font, x:Float = 0, y:Float = 0, color:Int = 0xff000000,
						align:TextAlign = null) {
		if (align == null) align = TextAlign.Left;

		super();

		this.font = font;
		this.textAlign = align;
		this.text = text;
		this.color = Color.fromValue(color);

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

	override function get_w():Float {
		if (textAlign == TextAlign.Left) return abs.w;
		else if (textAlign == TextAlign.Center) return abs.w / 2;
		else return 0;
	}

	public override function render(painter:Painter) {
		super.render(painter);
		
		painter.setColor(abs.color);
		painter.setFont(font);
		
		// Draw text
		var posX = 0.0;
		if (textAlign == TextAlign.Left) posX = abs.x;
		else if (textAlign == TextAlign.Center) posX = abs.x - abs.w / 2;
		else posX = abs.x - abs.w;

		painter.drawString(text, posX, abs.y, abs.scaleX, abs.scaleY);
	}
}
