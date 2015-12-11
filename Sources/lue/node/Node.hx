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

	public var id:String = "";
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

	public function getChild(id:String):Node {
		if (this.id == id) {
			return this;
		}
		else {
			for (c in children) {
				var r = c.getChild(id);
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
		traverseNodes(resource, name, parent, resource.nodes);
		return parent;
	}

	static function traverseNodes(resource:TSceneFormat, name:String, parent:Node, nodes:Array<TNode>) {
		for (n in nodes) {
			var node:Node = null;
			
			if (n.type == "camera_node") {
				node = Eg.addCameraNode(Resource.getCamera(name, n.object_ref), parent);
			}
			else if (n.type == "light_node") {
				node = Eg.addLightNode(Resource.getLight(name, n.object_ref), parent);	
			}
			else if (n.type == "geometry_node") {
				var materials:Array<MaterialResource> = [];
				for (ref in n.material_refs) {
					materials.push(Resource.getMaterial(name, ref));
				}

				var ref = n.object_ref.split("/");
				var object_file = "";
				var object_ref = "";
				if (ref.length == 2) { // File reference
					object_file = ref[0];
					object_ref = ref[1];
				}
				else { // Local geometry resource
					object_file = name;
					object_ref = n.object_ref;
				}
				node = Eg.addModelNode(Resource.getModel(object_file, object_ref, resource.nodes), materials, parent);
				
				// Attach particle system
				if (n.particle_refs != null && n.particle_refs.length > 0) {
					cast(node, ModelNode).setupParticleSystem(name, n.particle_refs[0]);
				}
			}
			else if (n.type == "node") {
				node = Eg.addNode(parent);
			}

			if (node != null) {
				node.id = n.id;
				createTraits(n, node);
				generateTranform(n, node.transform);

				traverseNodes(resource, name, node, n.nodes);
			}
		}
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

		if (node.type == "camera_node") { // TODO: remove
        	transform.rot.inverse(transform.rot);
		}
	}

	static function createTraits(n:TNode, node:Node) {
		for (t in n.traits) {
			if (t.type == "Script") {
				var s:Array<String> = t.class_name.split(":");

				// First one is trait name
				var traitName = s[0];

				// Parse arguments if any
				var args:Dynamic = [];
				for (i in 1...s.length) {
					parseTraitArgument(args, s[i]);
				}
				
				Eg.addNodeTrait(node, createTraitClassInstance(traitName, args));
			}
		}
	}

	static function parseTraitArgument(args:Dynamic, str:String) {
		if (str == "true") { // Bool
			args.push(true);
		}
		else if (str == "false") {
			args.push(false);
		}
		else if (str.charAt(0) == "'") { // String
			args.push(StringTools.replace(str, "'", ""));
		}
		else if (str.charAt(0) == "[") { // Array
			// Remove [] and recursively parse into array,
			// then append into parent
			str = StringTools.replace(str, "[", "");
			str = StringTools.replace(str, "]", "");
			str = StringTools.replace(str, " ", "");
			var childArgs:Dynamic = [];
			var s = str.split(",");
			for (childStr in s) {
				parseTraitArgument(childArgs, childStr);
			}
			args.push(childArgs);
		}
		else { // Float
			args.push(Std.parseFloat(str));
		}
	}

	static function createTraitClassInstance(traitName:String, args:Dynamic):Dynamic {
		var cname = Type.resolveClass("game." + traitName);
		if (cname == null) cname = Type.resolveClass("lue.trait." + traitName);
		if (cname == null) cname = Type.resolveClass("cycles.trait." + traitName);
		
		return Type.createInstance(cname, args);
	}
}
