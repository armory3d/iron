package fox.node;

class ObjectNode extends Node {

	// Inputs
	var positionNode:VectorNode;
	var rotationNode:VectorNode;
	var scaleNode:VectorNode;

	// Outputs

	// Variables
	var object:fox.core.Object;

	var position:Vector;
	var rotation:Vector;
	var scale:Vector;

	public function new() {
		super();
	}

	public override function update() {
		object.transform.pos.set(position.x, position.y, position.z);
		object.transform.modified = true;
	}
}
