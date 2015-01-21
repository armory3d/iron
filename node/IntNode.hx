package fox.node;

class IntNode extends Node {

	public var i:Int;

	public function new() {
		super();
	}

	public static function create(_i:Int) {
		var n = new BoolNode();
		n.i = _i;
		return n;
	}
}
