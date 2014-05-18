package wings.w2d.ui.popup;

class YesNoPopup extends Popup {

	public function new(title:String, onYesTap:Void->Void) {
		super(title);

		var yesButton = new Button("Yes", 150, 45, onYesTap);
		yesButton.x = 235;
		yesButton.y = 235;
		yesButton.forcedInput = true;
		addChild(yesButton);

		var noButton = new Button("No", 100, 30, onNoTap);
		noButton.x = 115;
		noButton.y = 250;
		noButton.forcedInput = true;
		addChild(noButton);
	}

	function onNoTap() {
		closePopup();
	}
}
