package wings.wxd;

class Log {

	public static var showTraces(default, set):Bool = false;

	static function set_showTraces(b:Bool):Bool {
		if (!b) clear();
		return showTraces = b;
	}

	public function new() {

	}

	public static function trace(message:String) {
		if (showTraces) {
            trace(message);
        }
	}

	public static function clear() {
		haxe.Log.clear();
	}
}