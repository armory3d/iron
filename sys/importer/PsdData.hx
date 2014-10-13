package fox.sys.importer;

import haxe.Json;
import kha.Image;

import fox.sys.Assets;

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

	public function getLayer(name:String, type:String = ""):TPsdLayer {
		for (i in 0...format.layers.length) {
			if (format.layers[i].name == name) {
				if (type == "" || (type == format.layers[i].type)) {
					return format.layers[i];
				}
			}
		}

		return null;
	}

	public function getGroup(id:Int):Array<TPsdLayer> {
		var group:Array<TPsdLayer> = [];

		for (j in 0...format.layers.length) {
			var i = format.layers.length - 1 - j;

			if (format.layers[i].group == id) {
				group.push(format.layers[i]);
			}
		}

		return group;
	}

	public function getElements(names:Array<String>):Array<TPsdLayer> {
		var group:Array<TPsdLayer> = [];

		for (j in 0...format.layers.length) {
			var i = format.layers.length - 1 - j;

			for (j in 0...names.length) {
				if (format.layers[i].name == names[j]) {
					group.push(format.layers[i]);
					//break; // Add all elements of the same name
				}
			}
		}

		return group;
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
	type:String,
	style:String,
	left:Int,
	top:Int,
	width:Int,
	height:Int,
	pinX:Float,
	pinY:Float,
	layer_index:Int,
	group:Int,
	autoAdd:Int,
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
