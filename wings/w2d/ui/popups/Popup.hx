package wings.w2d.ui.popups;

import wings.w2d.Object2D;
import wings.w2d.Text2D;
import wings.w2d.shapes.RectShape;
import wings.w2d.ui.Button;
import wings.wxd.Input;
import wings.wxd.Act;
import wings.wxd.Pos;

class Popup extends Object2D {

	public function new(title:String, font:kha.Font) {
		super();

		this.x = 300;
		this.y = Pos.h;

		addChild(new RectShape(0, 0, 500, 300, 0xff444444));

		addChild(new Text2D(title, font, 250, 30, 0xffffffff, TextAlign.Center));

		var okButton = new Button("OK", 100, 30, onOkTap);
		okButton.x = 200;
		okButton.y = 250;
		addChild(okButton);

		Act.tween(this, 0.2, {y: 300}).ease(motion.easing.Cubic.easeOut);
	}

	public override function update() {
		super.update();

		// TODO: Prevent any other input activity
		
	}

	function onOkTap() {
		Act.tween(this, 0.2, {y: Pos.h + 100}).ease(motion.easing.Cubic.easeOut).onComplete(onPopupComplete);
	}

	function onPopupComplete() {
		remove();
	}
}
