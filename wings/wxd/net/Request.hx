package wings.wxd.net;

#if flash
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLLoaderDataFormat;
import flash.errors.Error;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.HTTPStatusEvent;
import flash.events.SecurityErrorEvent;
#else
import haxe.Http;
#end

class Request {

	// Event handlers
	public var onData:String->Void;
	public var onError:String->Void;
	public var onStatus:Int->Void;

	#if flash
	var loader:URLLoader;
	var request:URLRequest;
	#else
	var request:Http;
	#end

	public function new(url:String, dataHandler:String->Void = null, errorHandler:String->Void = null,
						statusHandler:Int->Void = null) {
		initRequest(url);

		onData = dataHandler;
		onError = errorHandler;
		onStatus = statusHandler;
	}

	public function get() {
		
		#if flash
		load();
		#else
		
		#if cpp
		cpp.vm.Thread.create(asyncGet);
		#else
		asyncGet();
		#end
		
		#end
	}

	public function post(data:String) {

		#if flash
		request.method = URLRequestMethod.POST;
		request.contentType = "plain/text";
		request.data = data;

		load();
		#else
		request.setPostData(data);
		request.setHeader("Content-Type", "plain/text");

		#if cpp
		cpp.vm.Thread.create(asyncPost);
		#else
		asyncPost();
		#end

		#end
	}

	#if flash
	function initRequest(url:String) {
		request = new URLRequest(url);
		loader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.TEXT;
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
	}

	function load() {
		try {
			loader.load(request);
		}
		catch (e:Dynamic) {
			trace("Connection failed");
		}
	}

	function securityErrorHandler(e:SecurityErrorEvent) {
		trace("Security error");
	}

	function ioErrorHandler(e:IOErrorEvent) {
		if (onError != null) onError(e.toString());
    }

    function completeHandler(data:Event) {
		if (onData != null) onData(loader.data);
    }

	function httpStatusHandler(e:HTTPStatusEvent) {
		if (onStatus != null) onStatus(e.status);
	}
	#else
	function initRequest(url:String) {
		request = new Http(url);
		request.onError = errorHandler;
		request.onData = dataHandler;
		request.onStatus = statusHandler;
	}

	function errorHandler(e:String) {
		if (onError != null) onError(e);
    }
	
	function dataHandler(data:String) {
		if (onData != null) onData(loader.data);
    }

	function statusHandler(e:Int) {
		if (onStatus != null) onStatus(e);
	}

	function asyncGet() {
		try {
			request.request(false);
		}
		catch (e:Dynamic) {
			trace("Connection failed");
		}
	}

	function asyncPost() {
		try {
			request.request(true);
		}
		catch (e:Dynamic) {
			trace("Connection failed");
		}
	}
	#end
}
