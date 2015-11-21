package lue.node;

import kha.graphics4.Graphics;
import lue.math.Mat4;
import lue.trait.Trait;
import lue.resource.importer.SceneFormat;
import lue.resource.Resource;
import lue.resource.MaterialResource;

class Node {

	public static var models:Array<ModelNode>;
	public static var lights:Array<LightNode>;
	public static var cameras:Array<CameraNode>;

	public var name:String = "";
	public var parent:Node;

	public var children:Array<Node> = [];
	public var traits:Array<Trait> = [];

	public var transform:Transform;

	public function new() {
		transform = new Transform(this);
	}

	public static function reset() {
		models = [];
		lights = [];
		cameras = [];
	}

	public function addChild(o:Node) {
		children.push(o);
		o.parent = this;
	}

	public function removeChild(o:Node) {
		// Remove children of o
		while (o.children.length > 0) o.removeChild(o.children[0]);

		// Remove traits
		while (o.traits.length > 0) o.removeTrait(o.traits[0]);

		children.remove(o);
		o.parent = null;
	}

	public function getChild(name:String):Node {
		if (this.name == name) {
			return this;
		}
		else {
			for (c in children) {
				var r = c.getChild(name);
				if (r != null) {
					return r;
				}
			}
		}
		return null;
	}

	public function addTrait(t:Trait) {
		traits.push(t);
		t.node = this;

		if (t._add != null) { t._add(); t._add = null; }
	}

	public function removeTrait(t:Trait) {
		if (t._init != null) App.removeInit(t._init);
		if (t._update != null) App.removeUpdate(t._update);
		if (t._render != null) App.removeRender(t._render);
		if (t._render2D != null) App.removeRender2D(t._render2D);
		if (t._remove != null) { t._remove(); t._remove = null; }

		traits.remove(t);
		t.node = null;
	}

	public function getTrait(c:Class<Trait>):Dynamic {
		for (t in traits) {
			if (Type.getClass(t) == c) {
				return t;
			}
		}
		return null;
	}

	public function render(g:Graphics, context:String, camera:CameraNode, light:LightNode, bindParams:Array<String>) {
		for (c in children) c.render(g, context, camera, light, bindParams);
	}

	public static function addScene(name:String, parent:Node):Node {
		var resource:TSceneFormat = Resource.getSceneResource(name);

		for (n in resource.nodes) {
			var node:Node = null;
			
			if (n.type == "camera_node") {
				node = Eg.addCameraNode(Resource.getCamera(name, n.object_ref));
			}
			else if (n.type == "light_node") {
				node = Eg.addLightNode(Resource.getLight(name, n.object_ref));	
			}
			else if (n.type == "geometry_node") {
				var materials:Array<MaterialResource> = [];
				for (ref in n.material_refs) {
					materials.push(Resource.getMaterial(name, ref));
				}

				node = Eg.addModelNode(Resource.getModel(name, n.object_ref), materials);	
			}

			generateTranform(n, node.transform);
		}
		
		return parent;
	}

	static function generateTranform(node:TNode, transform:Transform) {
		var mat = new Mat4(node.transform.values);
		transform.pos.x = mat._41;
		transform.pos.y = mat._42;
		transform.pos.z = mat._43;
		var rotation = mat.getQuat();
		transform.rot.set(rotation.x, rotation.y, rotation.z, rotation.w);
		var vs = mat.getScale();
		transform.scale.x = vs.x;
		transform.scale.y = vs.y;
		transform.scale.z = vs.z;

		//if (node.type == "camera_node") { // TODO: remove
        //	transform.rot.inverse(transform.rot);
		//}
	}
}
