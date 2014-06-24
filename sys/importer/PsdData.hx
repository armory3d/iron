package wings.sys.importer;

import haxe.Json;
import kha.Image;

import wings.sys.Assets;

class PsdData {

	public var texture:Image;
	public var format:TPsdFormat;

	public function new(data:String, metaOnly:Bool = false) {
		format = Json.parse(data);
        if (!metaOnly) texture = Assets.getImage(format.name + "_atlas");
	}

	public inline function getLayers():Array<TPsdLayer> {
		return format.layers;
	}

	public inline function getStrings():Array<String> {
		return format.strings;
	}
}

typedef TPsdFormat = {
	width:Int,
	height:Int,
	resolution:Int,
	name:String,
	path:String,
	strings:Array<String>,
	layers:Array<TPsdLayer>,
	atlas:TPsdAtlas,
}

typedef TPsdLayer = {
	name:String,
	left:Int,
	top:Int,
	width:Int,
	height:Int,
	pinX:Float,
	pinY:Float,
	layer_index:Int,
	packedOrigin:TPsdPackedOrigin,
}

typedef TPsdPackedOrigin = {
	x:Int,
	y:Int,
}

typedef TPsdAtlas = {
	width:Int,
	height:Int,
}
