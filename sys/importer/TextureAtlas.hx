package fox.sys.importer;

// Based on spritesheet library
// https://github.com/jgranick/spritesheet/

import haxe.Json;
import kha.Image;

import fox.sys.Assets;
import fox.math.Rect;

class TextureAtlas {

    var texture:Image;
	var frames:Array<TPFrame>;

	public function new(data:String) {

		var json = Json.parse(data);
        frames = json.frames;

        texture = Assets.getImage(json.meta.image);
	}

    public function getFrameByName(name:String):TPFrame {
        for (f in frames) {
            if (f.filename == name) return f;
        }

        return null;
    }

    public inline function getRect(name:String):Rect {
        var rect = getFrameByName(name).frame;
        return new Rect(rect.x, rect.y, rect.w, rect.h);
    }
}

typedef TPFrame = {

    var filename:String;
    var frame:TPRect;
    var rotated:Bool;
    var trimmed:Bool;
    var spriteSourceSize:TPRect;
    var sourceSize:TPSize;
}

typedef TPRect = {

    var x:Int;
    var y:Int;
    var w:Int;
    var h:Int;
}

typedef TPSize = {

    var w:Int;
    var h:Int;
}

typedef TPMeta = {

    var app:String;
    var version:String;
    var image:String;
    var format:String;
    var size:TPSize;
    var scale:String;
    var smartupdate:String;
}
