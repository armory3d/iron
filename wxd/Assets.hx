package wings.wxd;

import kha.Loader;
import kha.Image;
import kha.graphics.Texture;
import kha.Sound;
import kha.Music;
import kha.Font;
import kha.FontStyle;
import kha.Blob;

class Assets  {
	
	public static var PREFIX:String = "assets/";

	public function new() {
	}
	
	public static inline function getImage(name:String):Image {
		return Loader.the.getImage(name);
	}

	public static inline function getTexture(name:String):Texture {
		return cast(Loader.the.getImage(name), Texture);
	}

	public static inline function getSound(name:String):Sound {
		return Loader.the.getSound(name);
	}

	public static inline function getMusic(name:String):Music {
		return Loader.the.getMusic(name);
	}

	// TODO: set styles
	public static inline function getFont(name:String, size:Int):Font {
		return Loader.the.loadFont(name, new FontStyle(false, false, false), size);
	}

	public static inline function getBlob(name:String):Blob {
		return Loader.the.getBlob(name);
	}

	public static inline function getString(name:String):String {
		return Loader.the.getBlob(name).toString();
	}

	public static inline function getShader(name:String):Blob {
		return Loader.the.getShader(name);
	}
}
