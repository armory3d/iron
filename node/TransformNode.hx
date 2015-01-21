package fox.node;

class TransformNode extends Node {

	public static inline var _position = 0; // Vector
	public static inline var _rotation = 1; // Vector
	public static inline var _scale = 2; // Vector

	public var transform:fox.trait.Transform;

	public function new() {
		super();
	}

	public override function update() {
		super.update();
		
		transform.pos.set(inputs[_position].inputs[VectorNode._x].f,
						  inputs[_position].inputs[VectorNode._y].f,
						  inputs[_position].inputs[VectorNode._z].f);

		transform.rot.initRotate(inputs[_rotation].inputs[VectorNode._x].f,
						  		 inputs[_rotation].inputs[VectorNode._y].f,
						  		 inputs[_rotation].inputs[VectorNode._z].f);

		transform.scale.set(inputs[_scale].inputs[VectorNode._x].f,
						  	inputs[_scale].inputs[VectorNode._y].f,
						  	inputs[_scale].inputs[VectorNode._z].f);

		transform.modified = true;
	}

	public static function create(positionX:Float, positionY:Float, positionZ:Float,
								  rotationX:Float, rotationY:Float, rotationZ:Float,
								  scaleX:Float, scaleY:Float, scaleZ:Float):TransformNode {
		var n = new TransformNode();
		n.inputs.push(VectorNode.create(positionX, positionY, positionZ));
		n.inputs.push(VectorNode.create(rotationX, rotationY, rotationZ));
		n.inputs.push(VectorNode.create(scaleX, scaleY, scaleZ));
		return n;
	}
}
