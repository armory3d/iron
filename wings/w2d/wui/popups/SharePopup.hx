package wings.w2d.ui.popups;

import wings.services.Net;
import wings.services.Storage;

class SharePopup extends ChoicePopup
{
	var message:String;
	var url:String;
	
	public function new(title:String, message:String, url:String) 
	{
		super(title, ["Facebook", "Twitter", "Cancel"],
			  [onFacebookTap, onTwitterTap, onCancelTap]);

		this.message = message;
		this.url = url;
	}

	function onFacebookTap()
	{
		Storage.data.sharePointsGained = true;
		Storage.data.points += 500;
		Storage.data.pointsTotal += 500;
		Storage.save();
		Net.openURL("http://www.facebook.com/sharer.php?u=" + url + "&t=" + message);
	}

	function onTwitterTap()
	{
		Storage.data.sharePointsGained = true;
		Storage.data.points += 500;
		Storage.data.pointsTotal += 500;
		Storage.save();
		Net.openURL("http://twitter.com/share?text=" + message + "%20" + url);
	}
}
