package lue;

import lue.node.Node;
import lue.node.CameraNode;
import lue.math.Vec3;

class Ut {

	public function new() { }

	public static function getNodeIntersection(node:Node, camera:CameraNode, x:Int, y:Int):Vec3 {
		return lue.math.RayCaster.getIntersect(node.transform, x, y, camera);
	}
}
