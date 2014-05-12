package wings.w2d.ui.popup;

class YesNoPopup extends Popup {

	public function new(title:String, onYesTap:Void->Void) {
		super(title);

		var yesButton = new Button("Yes", 100, 30, onYesTap);
		yesButton.x = 260;
		yesButton.y = 250;
		yesButton.forcedInput = true;
		addChild(yesButton);

		var noButton = new Button("No", 100, 30, onNoTap);
		noButton.x = 140;
		noButton.y = 250;
		noButton.forcedInput = true;
		addChild(noButton);
	}

	function onNoTap() {
		closePopup();
	}
}
