package wings.w2d.ui.popups;

import wings.Root;
import wings.w2d.Object2D;
import wings.w2d.Text2D;
import wings.w2d.shapes.RectShape;
import wings.w2d.ui.Button;
import wings.wxd.Input;
import wings.wxd.Act;
import wings.wxd.Pos;

class Popup extends Object2D {

	var background:RectShape;

	public function new(title:String, font:kha.Font) {
		super();

		this.x = 300;
		this.y = Pos.h;

		background = new RectShape(0, 0, Pos.w, Pos.h, 0xff000000);
		background.color.A = 0;
		Root.addChild2D(background);

		addChild(new RectShape(0, 0, 500, 300, 0xff444444));

		addChild(new Text2D(title, font, 250, 30, 0xffffffff, TextAlign.Center));

		var okButton = new Button("OK", 100, 30, onOkTap);
		okButton.x = 200;
		okButton.y = 250;
		okButton.forcedInput = true;
		addChild(okButton);

		Act.tween(background.color, 0.1, {A: 0.3}).ease(motion.easing.Cubic.easeOut);
		Act.tween(this, 0.1, {y: 150}).ease(motion.easing.Cubic.easeOut);

		//Prevent any other input activity
		Input.enabled = false;
	}

	public override function update() {
		super.update();
		background.rel.changed = true;
	}

	function onOkTap() {
		Act.tween(background.color, 0.1, {A: 0}).ease(motion.easing.Cubic.easeOut);
		Act.tween(this, 0.1, {y: Pos.h + 100}).ease(motion.easing.Cubic.easeOut).onComplete(onPopupComplete);
	}

	function onPopupComplete() {
		remove();
		Root.removeChild2D(background);
		Input.enabled = true;
	}
}
