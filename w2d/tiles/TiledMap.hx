package wings.w2d.tiles;

import kha.Painter;
import kha.Image;
import wings.wxd.Pos;

// Tiled Map Editor

class TiledMap extends TileMap {

	var data:Format;

	public function new(json:String, tilesheet:Tilesheet) {
		super();

		data = haxe.Json.parse(json);

		var layers = new Array<Layer>();

		for (i in 0...data.layers.length) {
			layers.push(new Layer(data.layers[i].data, data.layers[i].width, data.layers[i].height));
		}

		super(layers, tilesheet);
	}
}
