package fox.node;

class ScaleValueNode extends FloatNode {

	public static inline var _factor = 0; // Float
	public static inline var _value = 1; // Float

	public function new() {
		super();
	}

	public override function update() {
		super.update();
		
		f = inputs[_value].f * inputs[_factor].f;
	}

	public static function create(factor:Float, value:Float) {
		var n = new ScaleValueNode();
		n.inputs.push(FloatNode.create(factor));
		n.inputs.push(FloatNode.create(value));
		return n;
	}
}
