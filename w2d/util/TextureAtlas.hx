package wings.w2d.util;

// Based on spritesheet library
// https://github.com/jgranick/spritesheet/

import haxe.Json;
import kha.Image;
import wings.wxd.Assets;
import wings.w2d.Image2D;
import wings.math.Rect;

class TextureAtlas {

    var texture:Image;
	var frames:Array<TPFrame>;

	public function new(data:String) {

		var json = Json.parse(data);
        frames = json.frames;

        texture = Assets.getImage(json.meta.image);
	}

    public function getImage(name:String):Image2D {
        var frame = getFrameByName(name).frame;

        var img = new Image2D(texture, 0, 0);
        img.source.x = frame.x;
        img.source.y = frame.y;
        img.source.w = frame.w;
        img.source.h = frame.h;
        img.w = frame.w;
        img.h = frame.h;
        return img;
    }

    public function getSource(name:String):Rect {
        var frame = getFrameByName(name).frame;
        
        return new Rect(null, frame.x, frame.y, frame.w, frame.h);
    }

    public function getFrameByName(name:String):TPFrame {
        for (f in frames) {
            if (f.filename == name) return f;
        }

        return null;
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
