package fox.node;

class VectorNode extends Node {

	// Inputs
	var xNode:FloatNode;
	var yNode:FloatNode;
	var zNode:FloatNode;

	// Outputs
	var vectorOut:VectorNode;

	// Variables
	var v:Vector;

	public function new(x:Float, y:Float, z:Float) {
		super();

		v.x = x;
		v.y = y;
		v.z = z;
	}
}
