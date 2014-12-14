package fox.trait2d.physics;

import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.shape.Shape;
import fox.trait.Transform;

class Body extends fox.core.Trait {

	public static inline var TYPE_BOX = 0;
	public static inline var TYPE_CIRCLE = 1;

	public var body:nape.phys.Body;
	public var shapeType:Int;

	var space:Space;
	var transform:Transform;

	public function new(type:BodyType = null, shapeType:Int = TYPE_BOX) {
		super();

		if (type == null) type = BodyType.DYNAMIC;
		this.shapeType = shapeType;
		
		body = new nape.phys.Body(type);
	}

	@injectAdd({asc:true,sibl:true})
	function addSpace(trait:Space) {
		space = trait;

		if (transform != null) init();
	}

	@injectAdd
	function addTransform(trait:Transform) {
		transform = trait;

		if (space != null) init();
	}

	function init() {
		
		body.userData.item = transform;

		var mat = new nape.phys.Material(0, 1, 2, 1);
		
		var shape:Shape = null;
		if (shapeType == TYPE_BOX) shape = new Polygon(Polygon.box(transform.w, transform.h), mat);
		else if (shapeType == TYPE_CIRCLE) shape = new Circle(transform.w / 2, mat);
		
		body.shapes.add(shape);

		body.position.x = transform.x + transform.w / 2;
		body.position.y = transform.y + transform.h / 2;
		
		space.space.bodies.add(body);
	}
}
