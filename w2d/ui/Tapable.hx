package wings.w2d.ui;

import wings.w2d.Object2D;
import wings.wxd.event.MouseEvent;
import wings.wxd.event.TapEvent;

class Tapable extends Object2D {

	public function new(onTap:Void->Void) {

		super();

		addEvent(new MouseEvent(onMouseOver));
		//addEvent(new TapEvent(onTapStarted));
		//addEvent(new TapEvent(onTapReleased));
		addEvent(new TapEvent(onTap));
	}

	function onMouseOver(b:Bool) {
		if (b) {
			color = kha.Color.fromFloats(color.R, color.G, color.B, color.A - 0.1);
			//kha.Loader.the.setHandCursor();
		}
		else {
			color = kha.Color.fromFloats(color.R, color.G, color.B, color.A + 0.1);
			//kha.Loader.the.setNormalCursor();
		}
	}
}
