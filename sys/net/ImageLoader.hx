package fox.sys.net;

#if flash
import flash.events.Event;
import flash.net.URLRequest;
import flash.system.LoaderContext;
#end

class ImageLoader {

	#if flash
	var loader:flash.display.Loader;
	#end
	var loadHandler:kha.Image->Void;

	public function new() {
		
	}

	public function get(url:String, handler:kha.Image->Void) {
		loadHandler = handler;

		#if flash
		var request:URLRequest = new URLRequest(url);

		loader = new flash.display.Loader();
        var lc:LoaderContext = new LoaderContext();
        lc.checkPolicyFile = true;
		loader.load(request, lc);

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
