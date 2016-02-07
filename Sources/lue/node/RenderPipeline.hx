package lue.node;

import kha.Color;
import kha.graphics4.Graphics;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.CompareMode;
import kha.graphics4.CullMode;
import lue.resource.Resource;
import lue.resource.CameraResource;
import lue.resource.ShaderResource;
import lue.resource.MaterialResource;

class RenderPipeline {

	var camera:CameraNode;
	var resource:CameraResource;
	var clearColor:Color;

	var frameRenderTarget:Graphics;
	var currentRenderTarget:Graphics;
	var bindParams:Array<String>;

	static var screenAlignedVB:VertexBuffer = null;
	static var screenAlignedIB:IndexBuffer = null;

	var stageCommands:Array<Array<String>->Node->LightNode->Void>;
	var stageParams:Array<Array<String>>;

	var cachedQuadContexts:Map<String, CachedQuadContext> = new Map();

	public function new(camera:CameraNode) {
		this.camera = camera;
		resource = camera.resource;

		cacheStageCommands();

		clearColor = Color.fromFloats(resource.resource.clear_color[0], resource.resource.clear_color[1], resource.resource.clear_color[2], resource.resource.clear_color[3]);

		if (screenAlignedVB == null) createScreenAlignedData();
	}

	static function createScreenAlignedData() {
		var data = [-1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0];
		var indices = [0, 1, 2, 0, 2, 3];

		// TODO: Mandatory vertex data names and sizes
		// pos=2
		screenAlignedVB = new VertexBuffer(Std.int(data.length / ShaderResource.getScreenAlignedQuadStructureLength()),
										   ShaderResource.createScreenAlignedQuadStructure(), Usage.StaticUsage);
		var vertices = screenAlignedVB.lock();
		
		for (i in 0...vertices.length) {
			vertices.set(i, data[i]);
		}
		screenAlignedVB.unlock();

		screenAlignedIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = screenAlignedIB.lock();

		for (i in 0...id.length) {
			id[i] = indices[i];
		}
		screenAlignedIB.unlock();
	}

	public function renderFrame(g:Graphics, root:Node, lights:Array<LightNode>) {
		frameRenderTarget = g;
		currentRenderTarget = g;

		var light = lights[0];
		/*if (light.V == null)*/ { light.buildMatrices(); }	

		for (i in 0...stageCommands.length) {
			stageCommands[i](stageParams[i], root, light);
		}
	}

	function setTarget(params:Array<String>, root:Node, light:LightNode) {
    	var target = params[0];
    	if (target == "") {
    		currentRenderTarget = frameRenderTarget;
    		begin(currentRenderTarget);
    	}
		else {
			var rt = resource.pipeline.renderTargets.get(target);
			currentRenderTarget = rt.image.g4;
			begin(currentRenderTarget, rt.additionalImages);
		}
		bindParams = null;
    }

    function clearTarget(params:Array<String>, root:Node, light:LightNode) {
    	currentRenderTarget.clear(clearColor, 1, null);
    }

    function drawGeometry(params:Array<String>, root:Node, light:LightNode) {
		var context = params[0];
		var g = currentRenderTarget;
		// TODO: resource.resource.draw_calls_sort
		root.render(g, context, camera, light, bindParams);
		end(g);
    }

    function bindTarget(params:Array<String>, root:Node, light:LightNode) {
    	bindParams = params;
    }

    function drawQuad(params:Array<String>, root:Node, light:LightNode) {
    	var handle = params[0];
    	var cc:CachedQuadContext = cachedQuadContexts.get(handle);
		if (cc == null) {
			var matPath = handle.split("/");
			var res = Resource.getMaterial(matPath[0], matPath[1]);
			cc = new CachedQuadContext();
			cc.materialContext = res.getContext(matPath[2]);
			cc.context = res.shader.getContext(matPath[2]);
			cachedQuadContexts.set(handle, cc);
		}

		var materialContext = cc.materialContext;
		var context = cc.context;
		
		var g = currentRenderTarget;		
		g.setPipeline(context.pipeState);

		ModelNode.setConstants(g, context, null, camera, light, bindParams);
		ModelNode.setMaterialConstants(g, context, materialContext);

		g.setVertexBuffer(screenAlignedVB);
		g.setIndexBuffer(screenAlignedIB);
		g.drawIndexedVertices();
		
		end(g);
    }

	inline function begin(g:Graphics, additionalRenderTargets:Array<kha.Canvas> = null) {
		#if !python
		g.begin(additionalRenderTargets);
		#end
	}

	inline function end(g:Graphics) {
		#if !python
		g.end();
		#end
	}

    function cacheStageCommands() {
    	stageCommands = [];
    	stageParams = [];
    	for (stage in resource.pipeline.resource.stages) {
    		
    		stageParams.push(stage.params);
			
			if (stage.command == "set_target") {
				stageCommands.push(setTarget);
			}
			else if (stage.command == "clear_target") {
				stageCommands.push(clearTarget);
			}
			else if (stage.command == "draw_geometry") {
				stageCommands.push(drawGeometry);
			}
			else if (stage.command == "bind_target") {
				stageCommands.push(bindTarget);
			}
			else if (stage.command == "draw_quad") {
				stageCommands.push(drawQuad);
			}
		}
    }
}

class CachedQuadContext {
	public var materialContext:MaterialContext;
	public var context:ShaderContext;
	public function new() {}
}
