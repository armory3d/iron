package wings.w2d.ui;
import wings.w2d.ui.popups.InputPopup;
import wings.Root;
import wings.services.Pos;

class InputUI extends RectUI {
	var onInputTap:String->Void;

	var state(default, null):String;
	var stateText:TextItem;
	
	public function new(text:String, onInputTap:String->Void, state:String = "")  {
		super(onInputTapped);
		this.onInputTap = onInputTap;

		// Set state
		if (state.length > 23) state = state.substr(0, 20) + "...";
		this.state = state;

		// Text
		addChild(new TextItem(text, Pos.x(0.05), Pos.x(0.046), Pos.x(Theme.UI_TEXT_SIZE),
							 Theme.UI_TEXT_COLOR[Theme.THEME]));

		// State text
		stateText = new TextItem(state, Pos.x(0.95), Pos.x(0.046), Pos.x(Theme.UI_TEXT_SIZE),
								 Theme.TITLE_ARROW_COLOR[Theme.THEME], 1, TextItem.ALIGN_RIGHT);
		addChild(stateText);
	}

	public function setState(state:String) {
		this.state = state;
		stateText.text = state;
	}

	public function onInputTapped() {
		Root.addChild(new InputPopup(onPopupOkTap, 16, "Tap to insert your nick", state));
	}

	function onPopupOkTap(s:String) {
		setState(s);
		
		if (onInputTap != null) onInputTap(state);
	}
}
