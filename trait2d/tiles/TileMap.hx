package fox.trait2d.tiles;

import kha.Image;

import fox.Root;
import fox.core.Trait;
import fox.core.IRenderable2D;

class TileMap extends Trait implements IRenderable2D {

	public var transform:Transform;

	var layers:Array<TileLayer>;

	var tilesheet:TileSheet;
	var tileW:Int;
	var tileH:Int;
	var tilesX:Int;
	var tilesY:Int;

	var drawX:Int;
	var drawY:Int;

	var image:Image;

	function new(layers:Array<TileLayer>, tilesheet:TileSheet) {
		super();

		this.layers = layers;
		this.tilesheet = tilesheet;

		// Tilesheet data
		tileW = tilesheet.tileW;
		tileH = tilesheet.tileH;
		tilesX = tilesheet.tilesX;
		tilesY = tilesheet.tilesY;

		// How many tiles to draw
		drawX = Std.int(Root.w / tileW);
		drawY = Std.int(Root.h / tileH);

		// Texture
		image = tilesheet.image;
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.w = layers[0].w * tileW;
		transform.h = layers[0].h * tileH;
    }

	public function render(g:kha.graphics2.Graphics) {
		g.color = transform.color;
		g.opacity = transform.a;

		// First visible tile
		var firstTileX:Int = Std.int(Math.abs(transform.absx) / tileW);
		var firstTileY:Int = Std.int(Math.abs(transform.absy) / tileH);
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
				var targetX:Float = transform.absx + (j % layers[i].w) * tileW /** abs.scaleX*/;
				var targetY:Float = transform.absy + Std.int(j / layers[i].w) * tileH /** abs.scaleY*/;

				// TODO: temporary check
				// Tile not visible
				if (targetX + (tileW /** abs.scaleX*/) < 0 || targetY + (tileH /** abs.scaleY*/) < 0 ||
					targetX > Root.w || targetY > Root.h) {
					j++;
					continue;
				}
				
				// Draw tile
				g.drawScaledSubImage(image, frameX, frameY, tileW, tileH, targetX, targetY,
								     (tileW /* * abs.scaleX*/) + 1, (tileH /* * abs.scaleY*/) + 1); // TODO: Fix seams correctly
			
				j++;
			}
		}
	}

	// Tiled Map Editor
	public static function fromTiled(json:String, tilesheet:TileSheet):TileMap {

		var data:Format = haxe.Json.parse(json);

		var layers = new Array<TileLayer>();

		for (i in 0...data.layers.length) {
			layers.push(new TileLayer(data.layers[i].data, data.layers[i].width, data.layers[i].height));
		}
		
		return new TileMap(layers, tilesheet);
	}
}
