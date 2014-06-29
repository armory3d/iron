package wings.sys.net;

#if flash
import flash.events.Event;
import flash.net.URLRequest;
#end

class ImageLoader {

	#if flash
	var loader:flash.display.Loader;
	#end
	var loadHandler:kha.Image->Void;

	public function new() {
		#if flash
		flash.system.Security.loadPolicyFile("https://fbcdn-profile-a.akamaihd.net/crossdomain.xml");
		#end
	}

	public function get(url:String, handler:kha.Image->Void) {
		loadHandler = handler;

		#if flash
		var request:URLRequest = new URLRequest(url);

		loader = new flash.display.Loader();
		loader.load(request);

		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
		#end
	}

	#if flash
	function onComplete(e:Event) {
		loadHandler(kha.flash.Image.fromBitmap(e.currentTarget.content, false));
	    e.currentTarget.removeEventListener(Event.COMPLETE, onComplete);
	}
	#end
}
