package wings.w2d.ui;

import wings.wxd.events.TapEvent;
import wings.w2d.ui.layouts.ListLayout;
import wings.w2d.shapes.RectShape;
import wings.w2d.Text2D;

class ListButton extends Button {

	var layout:ListLayout;

	public function new(title:String, w:Int, h:Int, color:Int) {
		super(title, w, h, color, onTap);

		layout = new ListLayout();
		layout.y = h;
	}

	public function addChild2(child:Object2D) {
		layout.addChild(child);
	}

	function onTap() {
		if (layout.parent == null) super.addChild(layout);
		else super.removeChild(layout);
	}
}
