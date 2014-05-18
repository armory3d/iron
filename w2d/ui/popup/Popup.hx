package wings.w2d.ui.popup;

import wings.Root;
import wings.w2d.Object2D;
import wings.w2d.Text2D;
import wings.w2d.shape.RectShape;
import wings.w2d.ui.Button;
import wings.wxd.Input;
import wings.wxd.Act;
import wings.wxd.Pos;

class Popup extends Object2D {

	var background:RectShape;

	public function new(title:String, width:Int = 500, height:Int = 300, backgroundColor:Int = 0xffffffff) {
		super();

		//background = new RectShape(0, 0, Pos.w, Pos.h, 0xff000000);
		//Root.addChild2D(background);

		addChild(new RectShape(0, 0, width, 70, 0xff00aeef));
		addChild(new RectShape(0, h, w, height - 70, backgroundColor));

		addChild(new Text2D(title, Theme.Font32, width / 2, 30, 0xffffffff, TextAlign.Center));


		this.x = Pos.w / 2 - w / 2;
		this.y = Pos.h / 2 - h / 2;


		//background.a = 0;
		a = 0;
		//Act.tween(background, 0.15, {a: 0.3}).ease(motion.easing.Cubic.easeOut);
		Act.tween(this, 0.15, {a: 1}).ease(motion.easing.Cubic.easeOut);

		//Prevent any other input activity
		Input.enabled = false;

		/*
		// Copy render texture
		var tex = copy(painter.renderTexture);

		// Render horizontal blur into texture
		Sys.graphics.renderToTexture(tex);
		tex.shader = 3;
		draw(tex);

		// Render vertical blur into texture
		tex.shader = 4;
		draw(tex);

		// Render blurred texture into backbuffer
		Sys.graphics.renderToBackbuffer();
		*/
	}

	public override function update() {
		super.update();
	}

	function onPopupComplete() {
		remove();
		//Root.removeChild2D(background);
		Input.enabled = true;
	}

	function closePopup() {
		//Act.tween(background, 0.1, {a: 0}).ease(motion.easing.Cubic.easeOut);
		Act.tween(this, 0.1, {a: 0}).ease(motion.easing.Cubic.easeOut).onComplete(onPopupComplete);
	}
}
