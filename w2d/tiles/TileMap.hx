package wings.w2d.tiles;

import kha.Painter;
import kha.Image;
import wings.wxd.Pos;

class TileMap extends Object2D {

	var layers:Array<Layer>;

	var tilesheet:Tilesheet;
	var tileW:Int;
	var tileH:Int;
	var tilesX:Int;
	var tilesY:Int;

	var drawX:Int;
	var drawY:Int;

	var image:Image;

	public function new(layers:Array<Layer>, tilesheet:Tilesheet) {
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

		painter.setColor(abs.color);
		painter.opacity = abs.a;

		// First visible tile
		var firstTileX:Int = Std.int(Math.abs(abs.x) / tileW);
		var firstTileY:Int = Std.int(Math.abs(abs.y) / tileH);
		var firstTile:Int = firstTileY * tilesX + firstTileX;

		// Draw layers
		for (i in 0...layers.length) {

			var currentTileX:Int = 0;
			var currentTileY:Int = 0;

			// Draw tiles
			var j:Int = 0;//firstTile;
			while (j < layers[i].tiles.length) {

				currentTileX++;

				// Next row
				if (currentTileX >= drawX) {
					currentTileX = 0;
					currentTileY++;
					//j += tilesX - drawX;
				}

				// Last row
				if (currentTileY > drawY) {
					//break;
				}

				// Empty tile
				if (layers[i].tiles[j] == 0) { 
					j++;
					continue;
				}

				// Actual frame on tileset
				var frame:Int = layers[i].tiles[j] - 1;
				
				// Pos on tileset
				var posX:Int = frame % tilesX;
				var posY:Int = Std.int(frame / tilesX);

				var frameX:Int = posX * tileW;
				var frameY:Int = posY * tileH;

				// Pos on screen
				var targetX:Float = abs.x + (j % layers[i].w) * tileW * abs.scaleX;
				var targetY:Float = abs.y + Std.int(j / layers[i].w) * tileH * abs.scaleY;

				// TODO: temporary check
				// Tile not visible
				if (targetX + (tileW * abs.scaleX) < 0 || targetY + (tileH * abs.scaleY) < 0 ||
					targetX > Pos.w || targetY > Pos.h) {
					j++;
					continue;
				}
				
				// Draw tile
				painter.drawImage2(image, frameX, frameY, tileW, tileH, targetX, targetY,
								   tileW * abs.scaleX, tileH * abs.scaleY);
			
				j++;
			}
		}
	}
}
