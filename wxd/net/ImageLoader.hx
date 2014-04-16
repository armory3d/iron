package wings.wxd.loaders;

import flash.events.Event;
import flash.net.URLRequest;

class ImageLoader {

	static var imgLoader:flash.display.Loader;
	static var onImageLoadedHandlers:Array<flash.display.Bitmap->Void> = new Array();

	public function new() {
		
	}

	public static function get(url:String, handler:flash.display.Bitmap->Void) {
		onImageLoadedHandlers.push(handler); // TODO: first handler doesnt have to be for first image
		var request:URLRequest = new URLRequest(url);

		imgLoader = new flash.display.Loader();
		imgLoader.load(request);

		imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
	}

	static function onComplete(e:Event) {
		onImageLoadedHandlers[0](e.target.content);
		onImageLoadedHandlers.splice(0, 1);

	    e.target.removeEventListener(Event.COMPLETE, onComplete);
	}
}
