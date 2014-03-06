package wings.w2d;

import kha.Painter;
import kha.Image;
import kha.Font;
import wings.wxd.Color;

class Text2D extends Object2D {

	public static inline var ALIGN_LEFT:Int = 0;
	public static inline var ALIGN_CENTER:Int = 1;
	public static inline var ALIGN_RIGHT:Int = 2;

	public var text(default, set):String;
	var font:Font;
	var color:Int;
	var align:Int;

	public function new(text:String, font:Font, x:Float = 0, y:Float = 0, color:Int = 0xff000000,
						align:Int = ALIGN_LEFT) {
		super();

		this.text = text;
		this.font = font;
		this.color = color;
		this.align = align;

		this.x = x;
		this.y = y;

		//w = text.length * 5.5;	// TODO: get text width
		h = 0;
	}

	function set_text(s:String):String {
		text = s;
		w = text.length * 23;
		return s;
	}

	public override function render(painter:Painter) {
		super.render(painter);

		var alpha:Int = Std.int(a / 255);
		
		painter.setColor(kha.Color.fromBytes(Color.r(color), Color.g(color), Color.b(color), alpha));
		//painter.setColor(kha.Color.fromValue(color));
		painter.setFont(font);
		
		if (align == ALIGN_LEFT) painter.drawString(text, _x, _y);
		else if (align == ALIGN_CENTER) painter.drawString(text, _x - w / 2, _y);
		else painter.drawString(text, _x - w, _y);
	}
}
