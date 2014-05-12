package wings.w2d.ui;

import wings.w2d.shape.RectShape;
import wings.w2d.shape.PolyShape;
import wings.w2d.ui.layout.ListLayout;
import wings.wxd.event.UpdateEvent;
import wings.wxd.event.TapEvent;
import wings.wxd.Input;
import wings.w2d.Text2D;
import wings.Root;

class ComboEntryUI extends RectShape {

	var comboUI:ComboUI;
	var state:Int;

	public function new(title:String, state:Int, comboUI:ComboUI) {
		super(0, 0, 100, 35);
		this.comboUI = comboUI;
		this.state = state;

		// Line
		addChild(new RectShape(0, 34, 100, 1, 0xffdddddd));

		addChild(new Text2D(title, Theme.FONT, 10, 10, 0xff000000));

		addEvent(new TapEvent(onTap));
	}

	function onTap() {
		comboUI.setState(state);
		Input.released = false;
	}
}

class ComboUI extends ButtonUI {

	var state:Int;
	var states:Array<String>;
	var onTap:Int->Void;

	var comboBox:ListLayout;
	var stateText:Text2D;

	public function new(title:String, onTap:Int->Void, states:Array<String>, state:Int = 0) {
		super(title, _onTap, 0xff1ed36f);

		this.onTap = onTap;
		this.states = states;
		this.state = state;

		// Arrows
		addChild(new PolyShape(275, 12, 9, 9, 0xffffffff, 3, 180));
		addChild(new PolyShape(275, 21, 10, 10));

		// State
		stateText = new Text2D(states[state], Theme.FONT, 200, 10, 0xffe5e5e5);
		addChild(stateText);

		// Combo box
		comboBox = new ListLayout();
		for (i in 0...states.length) {
			comboBox.addChild(new ComboEntryUI(states[i], i, this));
		}

		addEvent(new UpdateEvent(onUpdate));
	}

	function onUpdate() {
		// Hide combo box when clicking outside
		if (Input.started && comboBox.parent != null) {
			if (!comboBox.hitTest(Input.x, Input.y)) {
				Root.removeChild2D(comboBox);
				Input.preventRelease = true;
			}
		}
	}

	function _onTap() {
		// Show combo box
		if (comboBox.parent == null) {
			comboBox.x = abs.x + w - comboBox.w;
			comboBox.y = abs.y;
			Root.addChild2D(comboBox);
		}
		else Root.removeChild2D(comboBox);
	}

	public function setState(state:Int) {
		this.state = state;
		stateText.text = states[state];

		// Hide combo box
		if (comboBox.parent != null) Root.removeChild2D(comboBox);

		// Propagate event
		onTap(state);
	}
}
