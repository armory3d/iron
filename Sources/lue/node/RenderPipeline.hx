package lue.node;

import kha.Color;
import kha.Scheduler;
import kha.graphics4.Graphics;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.CompareMode;
import kha.graphics4.CullMode;
import lue.resource.Resource;
import lue.resource.PipelineResource.RenderTarget; // Ping-pong
import lue.resource.CameraResource;
import lue.resource.ShaderResource;
import lue.resource.MaterialResource;
import lue.resource.SceneFormat;

class RenderPipeline {

	var camera:CameraNode;
	var resource:CameraResource;
	var clearColor:Color;

	var frameRenderTarget:Graphics;
	var currentRenderTarget:Graphics;
	var bindParams:Array<String>;

	static var screenAlignedVB:VertexBuffer = null;
	static var screenAlignedIB:IndexBuffer = null;
	static var decalVB:VertexBuffer = null;
	static var decalIB:IndexBuffer = null;

	var stageCommands:Array<Array<String>->Node->LightNode->Void>;
	var stageParams:Array<Array<String>>;
	var currentStageIndex = 0;

	// Quad and decals contexts
	var cachedShaderContexts:Map<String, CachedShaderContext> = new Map();
	
#if WITH_PROFILE
	var lastTime = 0.0;
	var frameTime = 0.0;
	var totalTime = 0.0;
	public static var frameTimeAvg = 0.0;
	var frames = 0;
#end

	public function new(camera:CameraNode) {
		this.camera = camera;
		resource = camera.resource;

		cacheStageCommands();

		clearColor = Color.fromFloats(resource.resource.clear_color[0], resource.resource.clear_color[1], resource.resource.clear_color[2], resource.resource.clear_color[3]);

		if (screenAlignedVB == null) createScreenAlignedData();
		if (decalVB == null) createDecalData();
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
	
	static function createDecalData() {
		var data = [
			-1.0,1.0,-1.0,-1.0,-1.0,-1.0,-1.0,-1.0,1.0,-1.0,1.0,1.0,-1.0,
			1.0,1.0,1.0,1.0,1.0,1.0,1.0,-1.0,-1.0,1.0,-1.0,1.0,1.0,1.0,1.0,-1.0,
			1.0,1.0,-1.0,-1.0,1.0,1.0,-1.0,-1.0,-1.0,-1.0,1.0,-1.0,-1.0,1.0,-1.0,
			1.0,-1.0,-1.0,1.0,-1.0,-1.0,-1.0,-1.0,1.0,-1.0,1.0,1.0,-1.0,1.0,-1.0,
			-1.0,1.0,-1.0,1.0,1.0,1.0,1.0,-1.0,1.0,1.0,-1.0,-1.0,1.0
		];
		var indices = [
			0,1,2,0,2,3,4,5,6,4,6,7,8,9,10,8,10,11,12,13,14,12,14,15,16,17,18,16,
			18,19,20,21,22,20,22,23
		];

		// pos=3
		decalVB = new VertexBuffer(Std.int(data.length / ShaderResource.getDecalStructureLength()),
										   ShaderResource.createDecalStructure(), Usage.StaticUsage);
		var vertices = decalVB.lock();
		
		for (i in 0...vertices.length) {
			vertices.set(i, data[i]);
		}
		decalVB.unlock();

		decalIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = decalIB.lock();

		for (i in 0...id.length) {
			id[i] = indices[i];
		}
		decalIB.unlock();
	}

	public function renderFrame(g:Graphics, root:Node, lights:Array<LightNode>) {
		frameRenderTarget = g;
		currentRenderTarget = g;

		var light = lights[0];
		/*if (light.V == null)*/ { light.buildMatrices(); }	

		for (i in 0...stageCommands.length) {
			currentStageIndex = i;
			stageCommands[i](stageParams[i], root, light);
		}
		
		// Timing
#if WITH_PROFILE
		totalTime += frameTime;
		frames++;
		if (totalTime > 1.0) {
			frameTimeAvg = totalTime / frames;
			totalTime = 0;
			frames = 0;
		}
		frameTime = Scheduler.realTime() - lastTime;
		lastTime = Scheduler.realTime();
#end
	}

	function setTarget(params:Array<String>, root:Node, light:LightNode) {
    	var target = params[0];
    	if (target == "") {
			// Ping-pong
			if (RenderTarget.is_last_two_targets_pong == true) {
				RenderTarget.is_pong = !RenderTarget.is_pong;
				RenderTarget.is_last_two_targets_pong = false;
			}
			
    		currentRenderTarget = frameRenderTarget;
    		begin(currentRenderTarget);
    	}
		else {			
			var colorBufIndex = -1; // Attach specific color buffer from MRT if number is appended
			var char = target.charAt(target.length - 1);
			if (char == "0") colorBufIndex = 0;
			else if (char == "1") colorBufIndex = 1;
			else if (char == "2") colorBufIndex = 2;
			else if (char == "3") colorBufIndex = 3;
			if (colorBufIndex >= 0) target = target.substr(0, target.length - 1);
			var rt = resource.pipeline.renderTargets.get(target);
			
			// Ping-pong
			if (rt.pong != null) {
				if (RenderTarget.is_last_target_pong) {
					RenderTarget.is_last_two_targets_pong = true;
					RenderTarget.is_pong = !RenderTarget.is_pong;
				}
				else RenderTarget.is_last_two_targets_pong = false;
				
				RenderTarget.last_pong_target_pong = RenderTarget.is_pong;
				if (RenderTarget.is_pong) rt = rt.pong;
				RenderTarget.is_last_target_pong = true;
			}		
			else {
				if (RenderTarget.is_last_two_targets_pong)
					RenderTarget.is_pong = !RenderTarget.is_pong;
				RenderTarget.is_last_target_pong = false;
				RenderTarget.is_last_two_targets_pong = false;
			}
			
			currentRenderTarget = colorBufIndex <= 0 ? rt.image.g4 : rt.additionalImages[colorBufIndex - 1].g4;
			begin(currentRenderTarget, colorBufIndex < 0 ? rt.additionalImages : null);
		}
		bindParams = null;
    }

    function clearTarget(params:Array<String>, root:Node, light:LightNode) {
		// TODO: use params
    	currentRenderTarget.clear(clearColor, 1, 0);
    }

    function drawGeometry(params:Array<String>, root:Node, light:LightNode) {
		var context = params[0];
		var g = currentRenderTarget;
		// TODO: resource.resource.draw_calls_sort
		root.render(g, context, camera, light, bindParams);
		end(g);
    }
	
	function drawDecals(params:Array<String>, root:Node, light:LightNode) {		
		var context = params[0];
		var g = currentRenderTarget;
		for (decal in RootNode.decals) {
			decal.renderDecal(g, context, camera, light, bindParams);
			g.setVertexBuffer(decalVB);
			g.setIndexBuffer(decalIB);
			g.drawIndexedVertices();
		}
		end(g);
    }

    function bindTarget(params:Array<String>, root:Node, light:LightNode) {
    	bindParams = params;
    }
	
	function drawShaderQuad(params:Array<String>, root:Node, light:LightNode) {
		var handle = params[0];
    	var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc == null) {
			var shaderPath = handle.split("/");
			var res = Resource.getShader(shaderPath[0], shaderPath[1]);
			cc = new CachedShaderContext();
			cc.materialContext = null;
			cc.context = res.getContext(shaderPath[2]);
			cachedShaderContexts.set(handle, cc);
		}
		drawQuad(cc, root, light);
	}
	
	function drawMaterialQuad(params:Array<String>, root:Node, light:LightNode) {
		var handle = params[0];
    	var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc == null) {
			var matPath = handle.split("/");
			var res = Resource.getMaterial(matPath[0], matPath[1]);
			cc = new CachedShaderContext();
			cc.materialContext = res.getContext(matPath[2]);
			cc.context = res.shader.getContext(matPath[2]);
			cachedShaderContexts.set(handle, cc);
		}
		drawQuad(cc, root, light);
	}

    function drawQuad(cc:CachedShaderContext, root:Node, light:LightNode) {
		var g = currentRenderTarget;		
		g.setPipeline(cc.context.pipeState);

		ModelNode.setConstants(g, cc.context, null, camera, light, bindParams);
		if (cc.materialContext != null) {
			ModelNode.setMaterialConstants(g, cc.context, cc.materialContext);
		}

		g.setVertexBuffer(screenAlignedVB);
		g.setIndexBuffer(screenAlignedIB);
		g.drawIndexedVertices();
		
		end(g);
    }
	
	function callFunction(params:Array<String>, root:Node, light:LightNode) {
		// TODO: cache
		var path = params[0];
		var dotIndex = path.lastIndexOf(".");
		var classPath = path.substr(0, dotIndex);
		var classType = Type.resolveClass(classPath);
		var funName = path.substr(dotIndex + 1);
		var stageData = resource.pipeline.resource.stages[currentStageIndex];
		// Call function
		if (stageData.returns_true == null && stageData.returns_false == null) {
			Reflect.callMethod(classType, Reflect.field(classType, funName), []);
		}
		// Branch function
		else {
			var result:Bool = Reflect.callMethod(classType, Reflect.field(classType, funName), []);
			// Nested commands
			var stages:Array<TPipelineStage> = null;
			if (result) stages = stageData.returns_true;
			else stages = stageData.returns_false;
			for (stage in stages) {
				// TODO: cache commands
				var commandFun = commandToFunction(stage.command);			
				commandFun(stage.params, root, light);
			}
		}
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
			stageCommands.push(commandToFunction(stage.command));
		}
    }
	
	function commandToFunction(command:String):Array<String>->Node->LightNode->Void {
		if (command == "set_target") {
			return setTarget;
		}
		else if (command == "clear_target") {
			return clearTarget;
		}
		else if (command == "draw_geometry") {
			return drawGeometry;
		}
		else if (command == "draw_decals") {
			return drawDecals;
		}
		else if (command == "bind_target") {
			return bindTarget;
		}
		else if (command == "draw_shader_quad") {
			return drawShaderQuad;
		}
		else if (command == "draw_material_quad") {
			return drawMaterialQuad;
		}
		else if (command == "call_function") {
			return callFunction;
		}
		return null;
	}
}

class CachedShaderContext {
	public var materialContext:MaterialContext;
	public var context:ShaderContext;
	public function new() {}
}
