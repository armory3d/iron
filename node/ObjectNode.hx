package fox.node;

class ObjectNode extends Node {

	// Inputs
	public var positionNode:VectorNode;
	public var rotationNode:VectorNode;
	public var scaleNode:VectorNode;

	// Variables
	public var object:fox.core.Object;

	public function new() {
		super();
	}

	public override function update() {
		object.transform.pos.set(positionNode.xNode.f,
								 positionNode.yNode.f,
								 positionNode.zNode.f);
		object.transform.modified = true;
	}
}
