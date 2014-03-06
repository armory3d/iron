package wings.w2d.ui;
import wings.w2d.Item;
import wings.w2d.ui.Theme;
import wings.services.Act;
import wings.services.Drawing;
import wings.services.Pos;

class ToggleUI extends RectUI {
	var onSwitchTap:Void->Void;
	var state(default, null):Bool;
	var toggle:Sprite;
	var toggleBg:Sprite;
	
	public function new(text:String, onSwitchTap:Void->Void, state:Bool = false) {
		super(onSwitchTapped);
		tap = Theme.SOUND_TOGGLE;
		this.onSwitchTap = onSwitchTap;

		// Set states
		this.state = state;

		// Text
		addChild(new TextItem(text, Pos.x(0.05), Pos.x(0.046), Pos.x(Theme.UI_TEXT_SIZE),
							 Theme.UI_TEXT_COLOR[Theme.THEME]));

		// Toggle Bg
		/*var f:Float = Pos.x(0.02);
		toggleBg = new Sprite();
		toggleBg.graphics.beginFill(0x000000);
		#if flash
		toggleBg.graphics.drawRect(-f*1.5 + 1, -f*2.2, f*3 - 2, f*4.4);
		#else
		toggleBg.graphics.drawRect(-f*1.5, -f*2.2, f*3, f*4.4);
		#end
		Drawing.drawArc(toggleBg.graphics, -f*1.5 + 1, -f*2.2, f*2.2, 180, 90);
		Drawing.drawArc(toggleBg.graphics, f*1.5 - 1, f*2.2, f*2.2, 180, -90);
		toggleBg.graphics.endFill();

		toggleBg.x = Pos.x(0.9);
		toggleBg.y = Pos.x(0.07);
		toggleBg.cacheAsBitmap = true;
		addChild(toggleBg);*/

		// Toggle
		/*toggle = new Sprite();

		toggle.graphics.beginFill(0x000000, 0.15);
		toggle.graphics.drawCircle(0, f*0.3, f*2);
		toggle.graphics.endFill();

		toggle.graphics.beginFill(0xffffff);
		toggle.graphics.drawCircle(0, 0, f*2);
		toggle.graphics.endFill();

		toggle.x = Pos.x(0.93);
		toggle.y = Pos.x(0.07);
		toggle.cacheAsBitmap = true;
		addChild(toggle);*/

		setState(state);
	}

	public function setState(state:Bool) {
		this.state = state;

		// Toggle
		if (state) {
			Act.tween(toggle, 0.2, {x: Pos.x(0.93)});

			//var ct:ColorTransform = new ColorTransform();
			//ct.color = 0x4cd864;
			//toggleBg.transform.colorTransform = ct;
		}
		else {
			Act.tween(toggle, 0.2, {x: Pos.x(0.87)});

			//var ct:ColorTransform = new ColorTransform();
			//ct.color = 0xe3e3e3;
			//toggleBg.transform.colorTransform = ct;
		}
	}

	function onSwitchTapped() {
		state = !state;
		setState(state);

		if (onSwitchTap != null) onSwitchTap();
	}
}
