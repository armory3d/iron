package wings.w2d.ui.popup;

class OkPopup extends Popup {

	public function new(title:String) {
		super(title);

		var okButton = new Button("OK", 100, 30, onOkTap);
		okButton.x = 200;
		okButton.y = 250;
		okButton.forcedInput = true;
		addChild(okButton);
	}

	function onOkTap() {
		closePopup();
	}
}
