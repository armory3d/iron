package wings.w2d.physics;

// Unfinished

import nape.phys.BodyType;
import nape.shape.Polygon;

class Body {

	public var body:nape.phys.Body;

	public function new(item:Object2D /*, type:BodyType = BodyType.DYNAMIC*/) {
		body = new nape.phys.Body(BodyType.DYNAMIC);
		body.userData.item = item;

		var shape:Polygon = new Polygon(Polygon.box(item.w, item.h));
		body.shapes.add(shape);
	}
}
