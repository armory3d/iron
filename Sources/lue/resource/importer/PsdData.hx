package lue.resource.importer;

import haxe.Json;
import kha.Image;
import lue.sys.Assets;
import lue.resource.importer.PsdFormat;

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

	public function getLeft(layer:TPsdLayer):Float {
		return layer.x - layer.pinX * format.w + layer.pinX * lue.Root.w;
	}

	public function getTop(layer:TPsdLayer):Float {
		return layer.y - layer.pinY * format.h + layer.pinY * lue.Root.h;
	}

	public function drawLayer(g:kha.graphics2.Graphics, layer:TPsdLayer, x:Float, y:Float, scale:Float = 1) {
		g.drawScaledSubImage(texture, layer.packedOrigin.x, layer.packedOrigin.y, layer.w, layer.h,
						   	 x, y, layer.w * scale, layer.h * scale);
	}
}
