package wings.w2d.tiles;

import kha.Painter;
import kha.Image;
import wings.wxd.Pos;

class Map extends Object2D {

	var data:Format;

	var tilesheet:Tilesheet;
	var tileW:Int;
	var tileH:Int;
	var tilesX:Int;
	var tilesY:Int;

	var drawX:Int;
	var drawY:Int;

	var image:Image;

	public function new(json:String, tilesheet:Tilesheet) {
		super();

		data = haxe.Json.parse(json);

		// Tilesheet data
		this.tilesheet = tilesheet;
		tileW = tilesheet.tileW;
		tileH = tilesheet.tileH;
		tilesX = tilesheet.tilesX;
		tilesY = tilesheet.tilesY;

		// How many tiles to draw
		drawX = Std.int(Pos.w / tileW);
		drawY = Std.int(Pos.h / tileH);

		// Map size
		w = data.layers[0].width * tileW;
		h = data.layers[0].height * tileH;

		// Texture
		image = tilesheet.image;
	}

	public override function render(painter:Painter) {
		super.render(painter);

		// First visible tile
		var firstTileX:Int = Std.int(Math.abs(abs.x) / tileW);
		var firstTileY:Int = Std.int(Math.abs(abs.y) / tileH);
		var firstTile:Int = firstTileY * tilesX + firstTileX;

		// Draw layers
		for (i in 0...data.layers.length) {

			var currentTileX:Int = 0;
			var currentTileY:Int = 0;

			// Draw tiles
			var j:Int = 0;//firstTile;
			while (j < data.layers[i].data.length) {

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
				if (data.layers[i].data[j] == 0) { 
					j++;
					continue;
				}

				// Actual frame on tileset
				var frame:Int = data.layers[i].data[j] - 1;
				
				// Pos on tileset
				var posX:Int = frame % tilesX;
				var posY:Int = Std.int(frame / tilesX);

				var frameX:Int = posX * tileW;
				var frameY:Int = posY * tileH;

				// Pos on screen
				var targetX:Float = abs.x + (j % data.layers[i].width) * tileW * abs.scaleX;
				var targetY:Float = abs.y + Std.int(j / data.layers[i].width) * tileH * abs.scaleY;

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
