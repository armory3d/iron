package wings.w2d.tiles;

// Tiled Map Editor
// TMX JSON
typedef Format = {
	version:Int,
	width:Int,
	height:Int,
	tilewidth:Int,
	tileheight:Int,
	orientation:Int,
	tilesets:Array<Tileset>,
	properties:Array<Property>,
	layers:Array<Layer>
};

typedef Tileset = {
	firstgid:Int,
	image:String,
	imagewidth:Int,
	imageheight:Int,
	margin:Int,
	name:String,
	properties:Array<Property>,
	spacing:Int,
	tilewidth:Int,
	tileheight:Int
};

typedef Property = {

};

typedef Layer = {
	data:Array<Int>,
	x:Int,
	y:Int,
	width:Int,
	height:Int,
	name:String,
	type:String,
	opacity:Float,
	visible:Bool
};
