package lue.resource.importer;

typedef TPsdFormat = {
	var w:Int;
	var h:Int;
	var name:String;
	var layers:Array<TPsdLayer>;
	var EN:Array<String>;
	var atlas:TPsdAtlas;
}

typedef TPsdLayer = {
	var name:String;
	var type:String;
	var style:String;
	var x:Int;
	var y:Int;
	var w:Int;
	var h:Int;
	var pinX:Float;
	var pinY:Float;
	var layer_index:Int;
	var group:Int;
	var autoAdd:Int;
	var packedOrigin:TPsdPackedOrigin;
}

typedef TPsdPackedOrigin = {
	var x:Int;
	var y:Int;
}

typedef TPsdAtlas = {
	var w:Int;
	var h:Int;
}
