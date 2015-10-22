package lue.sys;

import kha.StorageFile;

class Storage {
	
	static var file:StorageFile;
	static var data:Array<Dynamic>;
	
	public function new() {
		file = kha.Storage.defaultFile();
		data = file.readObject();

		if (data == null) data = [];
		save();
	}
	
	public static function save() {
		file.writeObject(data);
	}

	public static function clear() {
		data = [];
		save();
	}

	public static function setValue(pos:EnumValue, value:Dynamic) {

		// Get index
		var p = Type.enumIndex(pos);

		// Extend array
		while (p > data.length) data.push("");

		// Set value
		data[p] = value;
		save();
	}

	public static function getValue(pos:EnumValue):Dynamic {

		return data[Type.enumIndex(pos)];
	}
}
