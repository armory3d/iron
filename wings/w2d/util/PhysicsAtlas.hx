package wings.w2d.util;

// Imports data from PhysicsEditor

import haxe.Json;
import wings.math.Tri2;
import wings.math.Vec2;

class PhysicsAtlas {

    public var nodes:Array<PENode>;
    public var shapes:Array<Tri2>;

	public function new(data:String) {

        // Parse nodes
		var json = Json.parse(data);
        nodes = json.nodes;

        // Store all shapes
        shapes = new Array();
        for (i in 0...nodes.length) {
            var s = nodes[i].shape;
            shapes.push(new Tri2(new Vec2(s[0], s[1]),
                                 new Vec2(s[2], s[3]),
                                 new Vec2(s[4], s[5])));
        }
	}
}

typedef PENode = {

    var density:Float;
    var friction:Float;
    var bounce:Float;
    var filter:PEFilter;
    var shape:Array<Int>;
}

typedef PEFilter = {

    var categoryBits:Int;
    var maskBits:Int;
}
