package wings.w2d.ui.popups;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.text.TextFieldType;
import wings.w2d.ui.Tapable;
import wings.services.Pos;

class InputPopup extends Popup
{
	var onTap:String->Void;
	var charLimit:Int;
	var insertText:String;
	var emptyText:String;

	public function new(onTap:String->Void, charLimit:Int = 16,
						insertText:String = "Tap to insert text", emptyText:String = "")
	{
		var yPosRel:Float = 0.5;
		super(insertText, 0.3, 200, yPosRel);
		textItem.textField.type = TextFieldType.INPUT;
		textItem.textField.mouseEnabled = true;
		textItem.textField.selectable = true;
		textItem.textField.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		textItem.textField.addEventListener(Event.CHANGE, onChange);
		this.onTap = onTap;
		this.charLimit = charLimit;
		this.insertText = insertText;
		this.emptyText = emptyText;
		offset = 0;

		// Lines
		graphics.beginFill(Theme.UI_LINE_COLOR[Theme.THEME]);
		graphics.drawRect(Pos.x(0.1), Pos.x(yPosRel + 0.15), Pos.x(0.8), 1);
		graphics.drawRect(Pos.x(0.5), Pos.x(yPosRel + 0.15), 1, Pos.x(0.15));
		graphics.endFill();

		// Text
		addChild(new TextItem("Cancel", Pos.x(0.3), Pos.x(yPosRel + 0.2), Pos.x(0.05), 0x007aff, 1, TextItem.ALIGN_CENTER));
		addChild(new TextItem("OK", Pos.x(0.7), Pos.x(yPosRel + 0.2), Pos.x(0.05), 0x007aff, 1, TextItem.ALIGN_CENTER));

		// Buttons
		addText("Cancel", 0.3, yPosRel + 0.2);
		addButton(onCancelTap, 0.1, yPosRel + 0.15);

		addText("OK", 0.7, yPosRel + 0.2);
		addButton(onOkTap, 0.5, yPosRel + 0.15);
	}

	function onFocusIn(e:FocusEvent)
	{
		textItem.textField.text = "";
	}

	function onChange(e:Event)
	{
		// Limit characters
		if (textItem.text.length >= charLimit) textItem.text = textItem.text.substr(0, charLimit);
	
		// Align to center
		textItem.alignText();
	}

	function onOkTap()
	{
		textItem.textField.removeEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		textItem.textField.removeEventListener(Event.CHANGE, onChange);
		remove();

		// Text is empty or not modified
		if (textItem.text == "" || textItem.text == insertText) textItem.text = emptyText;

		onTap(textItem.text);
	}
}
