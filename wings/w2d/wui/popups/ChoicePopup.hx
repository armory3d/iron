package wings.w2d.ui.popups;
import wings.w2d.ui.Tapable;
import wings.services.Pos;

class ChoicePopup extends Popup {
	
	public function new(text:String, choices:Array<String>, onTaps:Array<Void->Void>, fadeTime:Int = 100,
						addCancel:Bool = false) {
		var length:Int = choices.length - 1;
		if (addCancel) length++;
		
		var sizeRel:Float = 0.3 + length * 0.15;
		var offset:Float = Pos.x((sizeRel - 0.3) / 2);
		
		super(text, sizeRel, fadeTime);

		for (i in 0...choices.length) {
			addChoiceButton(choices[i], onTaps[i], i, offset);
		}

		if (addCancel) {
			addChoiceButton("Cancel", onCancelTap, choices.length, offset);
		}
	}

	function addChoiceButton(text:String, onTap:Void->Void, i:Int, offset:Float) {
		// Lines
		graphics.beginFill(Theme.UI_LINE_COLOR[Theme.THEME]);
		graphics.drawRect(Pos.x(0.1), Pos.x(0.85) + Pos.x(0.15) * i - offset, Pos.x(0.8), 1);
		graphics.endFill();

		// Text
		addChild(new TextItem(text, Pos.x(0.5), Pos.x(0.9) + Pos.x(0.15) * i - offset, Pos.x(0.05), 0x007aff, 1, TextItem.ALIGN_CENTER));

		// Button
		var button:Tapable = new Tapable(onTap, 0, 0.1);
		button.graphics.beginFill(0x000000, 1);
		button.graphics.drawRect(Pos.x(0.1), Pos.x(0.85) + Pos.x(0.15) * i - offset, Pos.x(0.8), Pos.x(0.15));
		button.graphics.endFill();
		addChild(button);
	}
}
