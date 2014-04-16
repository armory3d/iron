package wings.w2d.animation;

import kha.Image;

class Tilesheet {

	public var image:Image;

	public var tileW:Int;
	public var tileH:Int;

	public var tilesW:Int;
	public var tilesH:Int;

	public function new(image:Image, tileW:Int, tileH:Int) {
		this.image = image;
		
		this.tileW = tileW;
		this.tileH = tileH;

		tilesW = Std.int(image.width / tileW);
		tilesH = Std.int(image.height / tileH);
	}
}
