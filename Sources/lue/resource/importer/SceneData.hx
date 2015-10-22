package lue.resource.importer;

import haxe.Json;
import lue.resource.importer.SceneFormat;

class SceneData {

	public var data:TSceneFormat;
	
	//public var bones:Array<TNode> = [];

	public function new(str:String) {
		data = Json.parse(str);

		//for (n in data.nodes) {
		//	setParents(n);
		//}
	}

	// function setParents(node:TNode) {
	// 	if (node.nodes == null) return;

	// 	for (n in node.nodes) {
	// 		n.parent = node;
	// 		setParents(n);
	// 	}
	// }

	// public function getNode(name:String):TNode { 
	// 	var res:TNode = null; 
	// 	traverseNodes(function(it:TNode) { 
	// 		if (it.name == name) { res = it; }
	// 	});
	// 	return res; 
	// }

	// public function traverseNodes(callback:TNode->Void) {
	// 	for (i in 0...data.nodes.length) {
	// 		traverseNodesStep(data.nodes[i], callback);
	// 	}
	// }
	
	// public function traverseNodesStep(node:TNode, callback:TNode->Void) {
	// 	callback(node);

	// 	if (node.nodes == null) return;
		
	// 	for (i in 0...node.nodes.length) {
	// 		traverseNodesStep(node.nodes[i], callback);
	// 	}
	// }

	public function getGeometryResource(id:String):TGeometryResource {
		for (go in data.geometry_resources) {
			if (go.id == id) return go;
		}
		return null;
	}

	public function getCameraObject(id:String):TCameraResource {
		for (co in data.camera_resources) {
			if (co.id == id) return co;
		}
		return null;
	}

	public function getLightObject(id:String):TLightResource {
		for (lo in data.light_resources) {
			if (lo.id == id) return lo;
		}
		return null;
	}

	// public function getMaterial(id:String):TMaterial {
	// 	for (m in data.materials) {
	// 		if (m.id == id) return m;
	// 	}
	// 	return null;
	// }

	public static function getVertexArray(mesh:TMesh, attrib:String):TVertexArray {
		for (va in mesh.vertex_arrays) {
			if (va.attrib == attrib) {
				return va;
			}
		}
		return null;
	}
}
