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
	public static var speakers:Array<SpeakerNode>;

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
		speakers = [];
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
		traverseNodes(resource, name, parent, resource.nodes, null);
		return parent;
	}

	static function traverseNodes(resource:TSceneFormat, name:String, parent:Node, nodes:Array<TNode>, parentNode:TNode) {
		for (n in nodes) {
			if (n.visible != null && n.visible == false) continue;
			
			var node = createNode(n, resource, name, parent, parentNode);
			if (node != null) {
				traverseNodes(resource, name, node, n.nodes, n);
			}
		}
	}
	
	public static function parseNode(sceneName:String, nodeName:String, parent:Node = null):Node {
		var resource:TSceneFormat = Resource.getSceneResource(sceneName);
		// TODO: traverse to find deeper nodes
		var n:TNode = null;
		for (node in resource.nodes) {
			if (node.id == nodeName) {
				n = node;
				break;
			}
		}
		if (n == null) return null;
		return Node.createNode(n, resource, sceneName, parent, null);
	}
	
	public static function createNode(n:TNode, resource:TSceneFormat, name:String, parent:Node, parentNode:TNode):Node {
		var node:Node = null;
			
		if (n.type == "camera_node") {
			node = Eg.addCameraNode(Resource.getCamera(name, n.object_ref), parent);
		}
		else if (n.type == "light_node") {
			node = Eg.addLightNode(Resource.getLight(name, n.object_ref), parent);	
		}
		else if (n.type == "geometry_node") {
			// Materials
			if (n.material_refs.length == 0) return null;
			var materials:Array<MaterialResource> = [];
			for (ref in n.material_refs) {
				materials.push(Resource.getMaterial(name, ref));
			}

			// Geometry reference
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

			// Bone nodes are stored in armature parent
			var boneNodes:Array<TNode> = null;
			if (parentNode != null && parentNode.bones_ref != null) {
				boneNodes = Resource.getSceneResource(parentNode.bones_ref).nodes;
			}

			node = Eg.addModelNode(Resource.getModel(object_file, object_ref, boneNodes), materials, parent);
			
			// Attach particle system
			if (n.particle_refs != null && n.particle_refs.length > 0) {
				cast(node, ModelNode).setupParticleSystem(name, n.particle_refs[0]);
			}
		}
		else if (n.type == "speaker_node") {
			node = Eg.addSpeakerNode(Resource.getSpeakerResourceById(resource.speaker_resources, n.object_ref), parent);	
		}
		else if (n.type == "node") {
			node = Eg.addNode(parent);
		}

		if (node != null) {
			node.id = n.id;
			createTraits(n, node);
			generateTranform(n, node.transform);
			node.transform.buildMatrix(); // Prevents first frame flicker
		}
		
		return node;
	}

	static function generateTranform(node:TNode, transform:Transform) {
		var mat = Mat4.fromArray(node.transform.values);
		mat.decompose(transform.pos, transform.rot, transform.scale);

		if (node.type == "camera_node") { // TODO: remove
        	transform.rot.inverse(transform.rot);
		}
	}

	static function createTraits(n:TNode, node:Node) {
		for (t in n.traits) {
			if (t.type == "Script") {
				// Assign arguments if any
				var args:Dynamic = [];
				if (t.parameters != null) args = t.parameters;
				Eg.addNodeTrait(node, createTraitClassInstance(t.class_name, args));
			}
		}
	}

	static function createTraitClassInstance(traitName:String, args:Dynamic):Dynamic {
		var cname = Type.resolveClass(Main.projectPackage + "." + traitName);
		if (cname == null) cname = Type.resolveClass(Main.projectPackage + ".node." + traitName);
		if (cname == null) cname = Type.resolveClass("lue.trait." + traitName);
		if (cname == null) cname = Type.resolveClass("cycles.trait." + traitName);
		return Type.createInstance(cname, args);
	}
}
