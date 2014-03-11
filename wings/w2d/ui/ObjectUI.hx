package wings.w2d.ui;

import wings.w2d.shapes.RectShape;

class ObjectUI extends RectShape {

	var lineRect:RectShape;

	public function new(startColor:Int = 0xff1a1a1a) {
		super(0, 0, 300, 35, 0xff1a1a1a);

		// Start
		addChild(new RectShape(0, 0, 3, 35, startColor));

		// Line
		lineRect = new RectShape(2, 34, 298, 1, 0xff343434);
		addChild(lineRect);
	}
}
