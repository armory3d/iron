package lue;

import lue.trait.Trait;
import lue.node.Node;
import lue.node.ModelNode;
import lue.node.LightNode;
import lue.node.CameraNode;
import lue.resource.Resource;
import lue.resource.ModelResource;
import lue.resource.LightResource;
import lue.resource.CameraResource;
import lue.resource.MaterialResource;
import lue.resource.ShaderResource;

class Eg {

	public static var root:Node;

	public function new() {
		reset();
	}

	public static function reset() {
		Node.reset();
        root = new Node();
    }

	// Resources
	public static inline function getModelResource(name:String, id:String = ""):ModelResource {
		return Resource.getModel(name, id);
	}

	public static inline function getLightResource(name:String, id:String = ""):LightResource {
		return Resource.getLight(name, id);
	}

	public static inline function getCameraResource(name:String, id:String = ""):CameraResource {
		return Resource.getCamera(name, id);
	}

	public static inline function getMaterialResource(name:String, id:String = ""):MaterialResource {
		return Resource.getMaterial(name, id);
	}

	public static inline function getShaderResource(name:String, id:String = ""):ShaderResource {
		return Resource.getShader(name, id);
	}

	// Nodes
	public static function addNode(parent:Node = null):Node {
		var node = new Node();
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function addModelNode(resource:ModelResource, material:MaterialResource, parent:Node = null):ModelNode {
		var node = new ModelNode(resource, material);
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function addLightNode(resource:LightResource, parent:Node = null):LightNode {
		var node = new LightNode(resource);
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function addCameraNode(resource:CameraResource, parent:Node = null):CameraNode {
		var node = new CameraNode(resource);
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function removeNode(node:Node) {
		if (node.parent == null) return;
		Std.is(node, ModelNode) ? Node.models.remove(cast node) : Std.is(node, LightNode) ? Node.lights.remove(cast node) : Node.cameras.remove(cast node);
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
		root.render(g, camera, Node.lights[0]);
		camera.end(g);
    }
}
