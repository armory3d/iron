package wings.w2d.ui;

class StateButton extends Button {

	var states:Array<String>;
	var currentState:Int;
	var onTap:Int->Void;

	public function new(states:Array<String>, w:Int, h:Int, color:Int, onTap:Int->Void, defaultState:Int = 0) {
		this.states = states;
		this.onTap = onTap;
		currentState = defaultState;
		super(states[currentState], w, h, color, _onTap);
	}

	function _onTap() {
		currentState++;
		if (currentState >= states.length) currentState = 0;
		text.text = states[currentState];

		onTap(currentState);
	}
}
