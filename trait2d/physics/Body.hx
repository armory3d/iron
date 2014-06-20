package wings.trait2d.physics;

import nape.phys.BodyType;
import nape.shape.Polygon;

class Body {

	public var body:nape.phys.Body;

	public function new(object:Object /*, type:BodyType = BodyType.DYNAMIC*/) {
		body = new nape.phys.Body(BodyType.DYNAMIC);
		body.userData.item = object;

		var shape:Polygon = new Polygon(Polygon.box(object.transform.w, object.transform.h));
		body.shapes.add(shape);
	}
}
