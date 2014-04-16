package wings.w2d.tiles;

import kha.Painter;
import kha.Image;
import wings.wxd.Pos;

class Map extends Object2D {

	var data:Format;
	var tilesheet:Image;

	public function new(json:String, tilesheet:Image, x:Int = 0, y:Int = 0) {
		super();

		data = haxe.Json.parse(json);
		this.tilesheet = tilesheet;

		this.x = x;
		this.y = y;
	}

	public override function render(painter:Painter) {
		super.render(painter);

		var tileW:Int = data.tilesets[0].tilewidth;
		var tileH:Int = data.tilesets[0].tileheight;

		var tilesW:Int = Std.int(tilesheet.width / tileW);
		var tilesH:Int = Std.int(tilesheet.height / tileH);

		// First visible tile
		var firstTileX:Int = Std.int(Math.abs(_x) / tileW);
		var firstTileY:Int = Std.int(Math.abs(_y) / tileH);
		var firstTile:Int = firstTileY * tilesW + firstTileX;

		// How many tiles to draw
		var tilesX:Int = Std.int(Pos.w / tileW);
		var tilesY:Int = Std.int(Pos.h / tileH);

		// Draw layers
		for (i in 0...data.layers.length) {

			var currentTileX:Int = 0;
			var currentTileY:Int = 0;

			// Draw tiles
			var j:Int = 0;//firstTile;
			while (j < data.layers[i].data.length) {


				// Next row
				currentTileX++;

				if (currentTileX >= tilesX) {
					currentTileX = 0;
					currentTileY++;
					//j += 50 - 21;//tilesW - tilesX;
				}

				// Last row
				if (currentTileY > tilesY) {
					//break;
				}

				// Empty tile
				if (data.layers[i].data[j] == 0) { j++; continue; }

				// Actual frame on tileset
				var frame:Int = data.layers[i].data[j] - 1;
				
				// Pos on tileset
				var posX:Int = Std.int(frame % tilesW);
				var posY:Int = Std.int(frame / tilesW);

				var frameX:Int = posX * tileW;
				var frameY:Int = posY * tileH;

				var targetX:Float = _x + Std.int(j % data.layers[i].width) * tileW;
				var targetY:Float = _y + Std.int(j / data.layers[i].width) * tileH;

				// Tile not visible
				//if (targetX + tileW < 0 || targetY + tileH < 0 || targetX > Pos.w || targetY > Pos.h) continue;
				
				painter.drawImage2(tilesheet, frameX, frameY, tileW, tileH, targetX, targetY, tileW, tileH);
			
				j++;
			}
		}
	}
}
