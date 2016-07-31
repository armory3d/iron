package iron;

import iron.Trait;
import iron.node.Node;
import iron.node.RootNode;
import iron.node.ModelNode;
import iron.node.LightNode;
import iron.node.CameraNode;
import iron.node.SpeakerNode;
import iron.node.DecalNode;
import iron.resource.Resource;
import iron.resource.ModelResource;
import iron.resource.LightResource;
import iron.resource.CameraResource;
import iron.resource.MaterialResource;
import iron.resource.ShaderResource;
import iron.resource.SceneFormat;

class Eg {

	public static var root:RootNode;

	public function new() {
		reset();
	}

	public static function reset() {
		RootNode.reset();
        root = new RootNode();
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

	public static function addModelNode(resource:ModelResource, materials:Array<MaterialResource>, parent:Node = null):ModelNode {
		var node = new ModelNode(resource, materials);
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

	public static function addSpeakerNode(resource:TSpeakerResource, parent:Node = null):SpeakerNode {
		var node = new SpeakerNode(resource);
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}
	
	public static function addDecalNode(material:MaterialResource, parent:Node = null):DecalNode {
		var node = new DecalNode(material);
		parent != null ? parent.addChild(node) : root.addChild(node);
		return node;
	}

	public static function addScene(name:String, parent:Node = null):Node {
		return RootNode.addScene(name, parent == null ? addNode() : parent);
	}
	
	public static function parseNode(sceneName:String, nodeName:String, parent:Node = null):Node {
		return RootNode.parseNode(sceneName, nodeName, parent);
	}

	public static function removeNode(node:Node) {
		node.remove();
	}

	public static function setNodeTransform(node:Node, x:Float = 0, y:Float = 0, z:Float = 0, rX:Float = 0, rY:Float = 0, rZ:Float = 0, sX:Float = 1, sY:Float = 1, sZ:Float = 1) {
		node.transform.set(x, y, z, rX, rY, rZ, sX, sY, sZ);
	}

	public static function addNodeTrait(node:Node, trait:Trait) {
		node.addTrait(trait);
	}

   	// Render
    public static function render(g:kha.graphics4.Graphics, camera:CameraNode) {
		camera.renderFrame(g, root, RootNode.lights);
    }

    // Animation
    public static function setupAnimation(node:Node, startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
    	node.setupAnimation(startTrack, names, starts, ends, speeds, loops, reflects);
    }

    public static function setAnimationParams(node:Node, delta:Float) {
    	node.setAnimationParams(delta);
    }
}
