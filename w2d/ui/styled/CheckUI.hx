package wings.w2d.ui;

import wings.w2d.shape.RectShape;
import wings.w2d.shape.CrossShape;
import wings.wxd.event.TapEvent;
import wings.w2d.Text2D;

class CheckUI extends ButtonUI {

	var checked:Bool;
	var onTap:Void->Void;

	var cross:CrossShape;

	public function new(title:String, onTap:Void->Void, checked:Bool = false) {
		super(title, _onTap, 0xff806787);

		this.onTap = onTap;
		this.checked = checked;

		// Checkbox
		addChild(new RectShape(240, 10, 15, 15));
		cross = new CrossShape(242, 12, 11, 11);
		if (checked) addChild(cross);
	}

	function _onTap() {
		checked = !checked;

		if (cross.parent == null) addChild(cross);
		else removeChild(cross);

		onTap();
	}
}
