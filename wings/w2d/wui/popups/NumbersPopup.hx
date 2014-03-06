package wings.w2d.ui.popups;
import wings.w2d.ui.Tapable;
import wings.services.Pos;

class NumberButton
{
	var popup:NumbersPopup;
	var i:Int;

	public function new(popup:NumbersPopup, i:Int, x:Float, y:Float)
	{
		this.popup = popup;
		this.i = i;
		popup.addButton(onTap, x, y, 0.267);
	}

	function onTap()
	{
		popup.number += Std.string(i);
	}
}

class NumbersPopup extends Popup
{
	public var number(default, set):String;
	var onTap:String->Void;
	
	public function new(text:String, onTap:String->Void) 
	{
		var sizeRel:Float = 0.3 + 4 * 0.15;

		super(text, sizeRel);
		number = text;
		this.onTap = onTap;

		offset = Pos.x((sizeRel - 0.3) / 2);

		// Lines
		graphics.beginFill(Theme.UI_LINE_COLOR[Theme.THEME]);
		graphics.drawRect(Pos.x(0.1), Pos.x(0.85) - offset, Pos.x(0.8), 1);
		graphics.drawRect(Pos.x(0.1), Pos.x(0.85) + Pos.x(0.15) * 4 - offset, Pos.x(0.8), 1);
		graphics.drawRect(Pos.x(0.5), Pos.x(0.85) + Pos.x(0.15) * 4 - offset, 1, Pos.x(0.15));
		graphics.endFill();

		// Numbers
		addText("1", 0.25, 0.9 + 0.15 * 0);
		addText("2", 0.5, 0.9 + 0.15 * 0);
		addText("3", 0.75, 0.9 + 0.15 * 0);

		addText("4", 0.25, 0.9 + 0.15 * 1);
		addText("5", 0.5, 0.9 + 0.15 * 1);
		addText("6", 0.75, 0.9 + 0.15 * 1);

		addText("7", 0.25, 0.9 + 0.15 * 2);
		addText("8", 0.5, 0.9 + 0.15 * 2);
		addText("9", 0.75, 0.9 + 0.15 * 2);

		addText(".", 0.25, 0.9 + 0.15 * 3);
		addText("0", 0.5, 0.9 + 0.15 * 3);
		addText("DEL", 0.75, 0.9 + 0.15 * 3);

		new NumberButton(this, 1, 0.1 + 0.267 * 0, 0.85 + 0.15 * 0);
		new NumberButton(this, 2, 0.1 + 0.267 * 1, 0.85 + 0.15 * 0);
		new NumberButton(this, 3, 0.1 + 0.267 * 2, 0.85 + 0.15 * 0);

		new NumberButton(this, 4, 0.1 + 0.267 * 0, 0.85 + 0.15 * 1);
		new NumberButton(this, 5, 0.1 + 0.267 * 1, 0.85 + 0.15 * 1);
		new NumberButton(this, 6, 0.1 + 0.267 * 2, 0.85 + 0.15 * 1);

		new NumberButton(this, 7, 0.1 + 0.267 * 0, 0.85 + 0.15 * 2);
		new NumberButton(this, 8, 0.1 + 0.267 * 1, 0.85 + 0.15 * 2);
		new NumberButton(this, 9, 0.1 + 0.267 * 2, 0.85 + 0.15 * 2);

		addButton(onDotTap, 0.1 + 0.267 * 0, 0.85 + 0.15 * 3, 0.267);
		new NumberButton(this, 0, 0.1 + 0.267 * 1, 0.85 + 0.15 * 3);
		addButton(onDelTap, 0.1 + 0.267 * 2, 0.85 + 0.15 * 3, 0.267);

		// Buttons
		addText("Cancel", 0.3, 0.9 + 0.15 * 4);
		addButton(onCancelTap, 0.1, 0.85 + 0.15 * 4);

		addText("OK", 0.7, 0.9 + 0.15 * 4);
		addButton(onOkTap, 0.5, 0.85 + 0.15 * 4);
	}

	public function set_number(s:String):String
	{
		textItem.text = s;
		return number = s;
	}

	function onOkTap()
	{
		onCancelTap();
		onTap(number);
	}

	function onDotTap()
	{
		if (number.length > 0) number += ".";
	}

	function onDelTap()
	{
		if (number.length > 0) number = number.substr(0, number.length - 1);
	}
}
