package wings.sys.net;

import flash.events.Event;
import flash.net.URLRequest;

class ImageLoader {

	var loader:flash.display.Loader;
	var loadHandler:kha.Image->Void;

	public function new() {
		flash.system.Security.loadPolicyFile("https://fbcdn-profile-a.akamaihd.net/crossdomain.xml");
	}

	public function get(url:String, handler:kha.Image->Void) {
		loadHandler = handler;
		var request:URLRequest = new URLRequest(url);

		loader = new flash.display.Loader();
		loader.load(request);

		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
	}

	function onComplete(e:Event) {
		loadHandler(kha.flash.Image.fromBitmap(e.currentTarget.content, false));
	    e.currentTarget.removeEventListener(Event.COMPLETE, onComplete);
	}
}
