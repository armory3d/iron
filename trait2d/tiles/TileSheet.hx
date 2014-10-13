package fox.trait2d.tiles;

import kha.Image;

class TileSheet {

	public var image:Image;

	public var tileW:Int;
	public var tileH:Int;

	public var tilesX:Int;
	public var tilesY:Int;

	public function new(image:Image, tileW:Int, tileH:Int) {
		this.image = image;
		
		this.tileW = tileW;
		this.tileH = tileH;

		tilesX = Std.int(image.width / tileW);
		tilesY = Std.int(image.height / tileH);
	}
}
