package fox.node;

class BoolNode extends Node {

	// Inputs

	// Outputs
	var boolOut:BoolNode;

	// Variables
	var b:Bool;

	public function new(b:Bool) {
		super();

		this.b = b;
	}
}
