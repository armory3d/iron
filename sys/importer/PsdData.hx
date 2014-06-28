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

	public function getLayer(name:String):TPsdLayer {
		for (i in 0...format.layers.length) {
			if (format.layers[i].name == name) {
				return format.layers[i];
			}
		}

		return null;
	}

	public inline function getStrings():Array<String> {
		return format.EN;
	}
}

typedef TPsdFormat = {
	width:Int,
	height:Int,
	name:String,
	layers:Array<TPsdLayer>,
	EN:Array<String>,
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
	group:Int,
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
