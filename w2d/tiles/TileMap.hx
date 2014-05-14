package wings.w2d.tiles;

import kha.Painter;
import kha.Image;
import wings.wxd.Pos;

class TileMap extends Object2D {

	var layers:Array<TileLayer>;

	var tilesheet:Tilesheet;
	var tileW:Int;
	var tileH:Int;
	var tilesX:Int;
	var tilesY:Int;

	var drawX:Int;
	var drawY:Int;

	var image:Image;

	function new(layers:Array<TileLayer>, tilesheet:Tilesheet) {
		super();

		this.layers = layers;
		this.tilesheet = tilesheet;

		// Tilesheet data
		tileW = tilesheet.tileW;
		tileH = tilesheet.tileH;
		tilesX = tilesheet.tilesX;
		tilesY = tilesheet.tilesY;

		// How many tiles to draw
		drawX = Std.int(Pos.w / tileW);
		drawY = Std.int(Pos.h / tileH);

		// Map size
		w = layers[0].w * tileW;
		h = layers[0].h * tileH;

		// Texture
		image = tilesheet.image;
	}

	public override function render(painter:Painter) {
		super.render(painter);

		
	}
}
