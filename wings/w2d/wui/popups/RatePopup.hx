package wings.w2d.ui.popups;

import wings.services.Net;

class RatePopup extends ChoicePopup
{
	
	public function new() 
	{
		super("Do you like this app?", ["Love it", "Needs work", "Latter"],
			  [onLoveItTap, onNeedsWorkTap, onCancelTap]);
	}

	function onLoveItTap()
	{
		Net.openURL("https://itunes.apple.com/us/app/looply/id742110118?ls=1&mt=8");
		onCancelTap();
	}

	function onNeedsWorkTap()
	{
		Net.openURL("mailto:lubos.lenco@me.com");
		onCancelTap();
	}
}
