package wings.w2d.ui;
import wings.w2d.Item;
import wings.w2d.ui.layouts.Layout;
import wings.w2d.shapes.RoundItem;
import wings.services.Pos;

class ButtonUI extends RectUI {
	var onTap:Void->Void;
	
	public function new(text:String, onTap:Void->Void, caption:String = null, fading:Bool = false) {
		this.onTap = onTap;

		if (fading) super(onFade);
		else super(onTap);

		// Arrow
		/*var s:Sprite = new Sprite();
		s.graphics.lineStyle(Pos.x(0.007), 0xcccccc);
		s.graphics.moveTo(0, 0);
		s.graphics.lineTo(Pos.x(0.02), Pos.x(0.02));
		s.graphics.lineTo(0, Pos.x(0.04));
		s.x = w - Pos.x(0.05) - s.width;
		s.y = Pos.x(0.053);
		addChild(s);*/

		// Text
		addChild(new TextItem(text, Pos.x(0.05), Pos.x(0.046), Pos.x(Theme.UI_TEXT_SIZE),
							 Theme.UI_TEXT_COLOR[Theme.THEME]));

		// Caption
		if (caption != null) {
			addChild(new TextItem(caption, Pos.x(0.9), Pos.x(0.046), Pos.x(Theme.UI_TEXT_SIZE),
							 	 Theme.UI_LINE_COLOR[Theme.THEME], 1, TextItem.ALIGN_RIGHT));
		}
	}

	function onFade() {
		if (onTap != null)
		{
			/*if (layout != null) layout.transition(onIconTap);
			else*/ cast(owner.owner.owner, Layout).transition(onTap);	// TODO: local layout variable
		}
	}
}
