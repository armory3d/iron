package wings.w2d.util;

import wings.math.Tri2;
import wings.math.Vec2;

class Helper {

	static function sign(p1:Vec2, p2:Vec2, p3:Vec2):Float {
	  return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
	}

	public static function pointInTriangle(point:Vec2, triangle:Tri2):Bool {
	  var b1, b2, b3:Bool;

	  b1 = sign(point, triangle.v1, triangle.v2) < 0.0;
	  b2 = sign(point, triangle.v2, triangle.v3) < 0.0;
	  b3 = sign(point, triangle.v3, triangle.v1) < 0.0;

	  return ((b1 == b2) && (b2 == b3));
	}
}