package wings.w2d.ui.popups;

class OkPopup extends ChoicePopup
{
	var onOkTap:Void->Void;
	
	public function new(text:String, onOkTap:Void->Void = null) 
	{
		this.onOkTap = onOkTap;
		
		if (onOkTap == null) super(text, ["OK"], [onCancelTap]);
		else super(text, ["OK"], [onOkTapCall]);
	}

	function onOkTapCall()
	{
		onCancelTap();
		onOkTap();
	}
}
