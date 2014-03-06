package wings.w2d.ui.popups;
import wings.w2d.ui.Tapable;
import wings.services.Pos;

class YesNoPopup extends Popup
{
	var onTap:Void->Void;
	var onNoTap:Void->Void;
	
	public function new(text:String, onTap:Void->Void, onNoTap:Void->Void = null) 
	{
		super(text);
		this.onTap = onTap;
		this.onNoTap = onNoTap;
		offset = 0;

		// Lines
		graphics.beginFill(Theme.UI_LINE_COLOR[Theme.THEME]);
		graphics.drawRect(Pos.x(0.1), Pos.x(0.85), Pos.x(0.8), 1);
		graphics.drawRect(Pos.x(0.5), Pos.x(0.85), 1, Pos.x(0.15));
		graphics.endFill();

		// Text
		addChild(new TextItem("Cancel", Pos.x(0.3), Pos.x(0.9), Pos.x(0.05), 0x007aff, 1, TextItem.ALIGN_CENTER));
		addChild(new TextItem("OK", Pos.x(0.7), Pos.x(0.9), Pos.x(0.05), 0x007aff, 1, TextItem.ALIGN_CENTER));

		// Buttons
		addText("Cancel", 0.3, 0.9);
		if (onNoTap == null) addButton(onCancelTap, 0.1, 0.85);
		else addButton(onNoTapCall, 0.1, 0.85);

		addText("OK", 0.7, 0.9);
		addButton(onOkTap, 0.5, 0.85);
	}

	function onOkTap()
	{
		remove();
		onTap();
	}

	function onNoTapCall()
	{
		onCancelTap();
		onNoTap();
	}
}
