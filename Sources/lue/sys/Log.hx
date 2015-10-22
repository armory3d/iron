package lue.sys;

class Log {

	public function new() {

	}

	public static inline function trace(s:Dynamic) {
		#if js
		js.Browser.window.console.log(Std.string(s));
		#elseif cpp
		trace(s);
		#end
	}
}