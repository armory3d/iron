package wings.w2d.ui;
import wings.services.Pos;

class SwitchUI extends RectUI {
	var onSwitchTap:Void->Void;
	var state(default, null):Int;
	var stateText:TextItem;
	var states:Array<String>;
	
	public function new(text:String, onSwitchTap:Void->Void, state:Int = 0, states:Array<String> = null) {
		super(onSwitchTapped);
		this.onSwitchTap = onSwitchTap;

		// Set states
		this.state = state;
		if (states == null) {
			this.states = new Array();
			this.states.push("Off");
			this.states.push("On");
		}
		else {
			this.states = states;
		}

		// Text
		addChild(new TextItem(text, Pos.x(0.05), Pos.x(0.046), Pos.x(Theme.UI_TEXT_SIZE),
							 Theme.UI_TEXT_COLOR[Theme.THEME]));

		// State text
		stateText = new TextItem(this.states[state], Pos.x(0.95), Pos.x(0.046), Pos.x(Theme.UI_TEXT_SIZE),
								 Theme.TITLE_ARROW_COLOR[Theme.THEME], 1, TextItem.ALIGN_RIGHT);
		addChild(stateText);
	}

	public function setState(state:Int) {
		this.state = state;
		if (state > states.length - 1) state = 0;

		stateText.text = states[state];
	}

	function onSwitchTapped() {
		state++;
		if (state > states.length - 1) state = 0;

		stateText.text = states[state];

		if (onSwitchTap != null) onSwitchTap();
	}
}
