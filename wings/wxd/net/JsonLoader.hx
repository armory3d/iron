package wings.wxd.loaders;

import haxe.Json;
import flash.events.Event;
import flash.errors.Error;
import flash.events.SecurityErrorEvent;
import flash.events.IOErrorEvent;
import flash.net.URLRequestHeader;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLLoaderDataFormat;

class JsonLoader {
	static var loader:URLLoader;
	static var request:URLRequest;

	static var onCompleteHandler:Dynamic->Void;

	public function new() {
		
	}

	public static function get(url:String, handler:Dynamic->Void) {
		onCompleteHandler = handler;

		initRequest(url);
		load();
	}

	public static function post(url:String, data:Dynamic, handler:Dynamic->Void) {
		onCompleteHandler = handler;

		initRequest(url);
		
		request.method = URLRequestMethod.POST;
		request.data = Json.stringify(data);
		
		load();
	}

	static function load() {
		try {
			loader.load(request);
		}
		catch (e:Dynamic) {
			trace("Connection failed" + e);
		}
	}

	static function initRequest(url:String) {
		request = new URLRequest(url);
		loader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.TEXT;
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
		loader.addEventListener(Event.COMPLETE, onComplete);

		var headers:Array<URLRequestHeader> = new Array();
		headers.push(new URLRequestHeader("Authorization", "Basic YWRtaW46"));
		headers.push(new URLRequestHeader("Content-Type", "application/json"));
		request.requestHeaders = headers;
		request.contentType = "application/json";
	}

	static function onSecurityError(e:SecurityErrorEvent) {
		trace("Security error");
	}

	static function onIOError(e:IOErrorEvent) {
		trace("IO Error " + e.toString());
    }

	static function onComplete(e:Event) {
    	if (loader.data == "") onCompleteHandler(null);
    	else onCompleteHandler(Json.parse(loader.data));
    }
}
