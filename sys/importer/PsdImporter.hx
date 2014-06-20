package wings.sys.importer;

import haxe.Json;
import kha.Image;

import wings.sys.Assets;

class PsdImporter {

	var texture:Image;
	var format:TPsdFormat;

	public function new(data:String) {
		format = Json.parse(data);

        //texture = Assets.getImage(format.name);
	}

	public function getLayers():Array<TPsdLayer> {
		return format.layers;
	}
}

typedef TPsdFormat = {
	width:Int,
	height:Int,
	resolution:Int,
	name:String,
	path:String,
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
