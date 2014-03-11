package wings.wxd;

import kha.Loader;

class Net {

	public function new() {

	}

	public static function loadURL(url:String) {
		Loader.the.loadURL(url);
	}

}
