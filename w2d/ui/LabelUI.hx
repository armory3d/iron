package wings.w2d.ui;

import wings.w2d.Text2D;

class LabelUI extends ObjectUI {

	public var text:Text2D;

	public function new(title:String) {
		super();

		text = new Text2D(title, Theme.FONT, 0, 0, 0xff000000);
		addChild(text);
	}
}
