package iron.node;

import iron.math.Mat4;
import iron.resource.SceneFormat;
import iron.resource.Resource;
import iron.resource.MaterialResource;

class RootNode extends Node {

	public static var models:Array<ModelNode>;
	public static var lights:Array<LightNode>;
	public static var cameras:Array<CameraNode>;
	public static var speakers:Array<SpeakerNode>;
	public static var decals:Array<DecalNode>;

	public function new() {
		super();
	}

	public static function reset() {
		models = [];
		lights = [];
		cameras = [];
		speakers = [];
		decals = [];
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
		return RootNode.createNode(n, resource, sceneName, parent, null);
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
			if (n.material_refs.length == 0) {
				// No material, create empty node
				node = Eg.addNode(parent);
			}
			else {
				// Materials
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
			node.transform.size.set(n.dimensions[0], n.dimensions[1], n.dimensions[2]);
		}
		else if (n.type == "speaker_node") {
			node = Eg.addSpeakerNode(Resource.getSpeakerResourceById(resource.speaker_resources, n.object_ref), parent);	
		}
		else if (n.type == "decal_node") {
			var material:MaterialResource = null;
			if (n.material_refs != null && n.material_refs.length > 0) {
				material = Resource.getMaterial(name, n.material_refs[0]);
			}
			node = Eg.addDecalNode(material, parent);	
		}
		else if (n.type == "node") {
			node = Eg.addNode(parent);
		}

		if (node != null) {
			node.id = n.id;
			createTraits(n, node);
			generateTranform(n, node.transform);
		}
		
		return node;
	}

	static function generateTranform(node:TNode, transform:Transform) {
		transform.matrix = Mat4.fromArray(node.transform.values);
		transform.matrix.decompose(transform.pos, transform.rot, transform.scale);
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
		var cname = Type.resolveClass(traitName);
		if (cname == null) throw "Trait " + traitName + "not found.";
		return Type.createInstance(cname, args);
	}
}
