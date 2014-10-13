package fox.sys;

import kha.StorageFile;

class StorageData /*implements Dynamic<String>*/ {

	public var values:Array<Dynamic> = new Array();

	public function new() {

	}
}

class Storage {
	
	// In Flash, storage file is flushed at exit
	static var file:StorageFile;
	static var data:StorageData;
	
	public function new() {
		file = kha.Storage.defaultFile();
		data = file.readObject();

		if (data == null) data = new StorageData();
		save();
	}
	
	public static function save() {
		file.writeObject(data);
	}

	public static function clear() {
		data = new StorageData();
		save();
	}

	public static function setValue(pos:EnumValue, value:Dynamic) {

		// Get index
		var p = Type.enumIndex(pos);

		// Extend array
		while (p > data.values.length) data.values.push("");

		// Set value
		data.values[p] = value;
		save();
	}

	public static function getValue(pos:EnumValue):Dynamic {

		return data.values[Type.enumIndex(pos)];
	}
}
