package lue;

import lue.trait.Trait;
import lue.node.Node;
import lue.node.ModelNode;
import lue.node.LightNode;
import lue.node.CameraNode;
import lue.resource.ModelResource;
import lue.resource.LightResource;
import lue.resource.CameraResource;
import lue.resource.MaterialResource;

class Eg {

	static var root:Node;
	static var models:Array<ModelNode>;
	static var lights:Array<LightNode>;
	static var cameras:Array<CameraNode>;

	public function new() {
		reset();
	}

	public static function reset() {
        root = new Node();
        models = [];
        lights = [];
        cameras = [];
    }

	// Resources
	public static function getModelResource(name:String, id:String = ""):ModelResource {
		return new ModelResource(name, id);
	}

	public static function getLightResource(name:String, id:String = ""):LightResource {
		return new LightResource(name, id);
	}

	public static function getCameraResource(name:String, id:String = ""):CameraResource {
		return new CameraResource(name, id);
	}

	public static function getMaterialResource(name:String, id:String = ""):MaterialResource {
		return new MaterialResource(name, id);
	}

	// Nodes
	public static function addNode(parent:Node = null):Node {
		var node = new Node();
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function addModelNode(resource:ModelResource, material:MaterialResource, parent:Node = null):ModelNode {
		var node = new ModelNode(resource, material);
		models.push(node);
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function addLightNode(resource:LightResource, parent:Node = null):LightNode {
		var node = new LightNode(resource);
		lights.push(node);
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function addCameraNode(resource:CameraResource, parent:Node = null):CameraNode {
		var node = new CameraNode(resource);
		cameras.push(node);
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function removeNode(node:Node) {
		if (node.parent == null) return;
		Std.is(node, ModelNode) ? models.remove(cast node) : Std.is(node, LightNode) ? lights.remove(cast node) : cameras.remove(cast node);
		node.parent.removeChild(node);
	}

	public static function setNodeTransform(node:Node, x:Float = 0, y:Float = 0, z:Float = 0, rX:Float = 0, rY:Float = 0, rZ:Float = 0, sX:Float = 1, sY:Float = 1, sZ:Float = 1) {
		node.transform.set(x, y, z, rX, rY, rZ, sX, sY, sZ);
	}

	public static function addNodeTrait(node:Node, trait:Trait) {
		node.addTrait(trait);
	}

   	// Render
    public static function render(g:kha.graphics4.Graphics, camera:CameraNode) {
		camera.begin(g);
		root.render(g, camera, lights[0]);
		camera.end(g);
    }
}
