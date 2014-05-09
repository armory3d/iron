package wings.w2d.ui;

import wings.w2d.Text2D;

class Label extends Text2D {

	public function new(text:String, x:Float, y:Float, color:Int = 0xff000000, align:TextAlign = null) {

		super(text, Theme.Font18, x, y, color, align);
	}
}
