package wings.wxd;

class Storage {
	//static var data:kha.KeyValueStorage;
	
	public function new() {
		//data = kha.Storage.instance.getKeyValueStorage("data");
	}
	
	public static function set(key:String, value:Dynamic) {
		//if (data != null) data.set(key, value);
	}

	public static function get(key:String):Dynamic {
		/*if (data != null) return data.get(key);
		else*/ return 0;
	}
	
	public static function clear() {
		
	}
}
