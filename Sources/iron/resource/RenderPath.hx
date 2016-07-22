package iron.resource;

import kha.Color;
import kha.Scheduler;
import kha.graphics4.Graphics;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import iron.resource.SceneFormat;
import iron.resource.PipelineResource.RenderTarget; // Ping-pong
import iron.resource.MaterialResource.MaterialContext;
import iron.resource.ShaderResource.ShaderContext;
import iron.node.Node;
import iron.node.RootNode;
import iron.node.CameraNode;
import iron.node.LightNode;
import iron.node.ModelNode;

typedef TStageCommand = Array<String>->Node->Void;

class RenderPath {

	var camera:CameraNode;
	public var resource:CameraResource;

	var frameRenderTarget:Graphics;
	var currentRenderTarget:Graphics;
	public var currentRenderTargetW:Int;
	public var currentRenderTargetH:Int;
	var bindParams:Array<String>;

	static var screenAlignedVB:VertexBuffer = null;
	static var screenAlignedIB:IndexBuffer = null;
	static var decalVB:VertexBuffer = null;
	static var decalIB:IndexBuffer = null;
	static var skydomeVB:VertexBuffer = null;
	static var skydomeIB:IndexBuffer = null;

	var stageCommands:Array<TStageCommand>;
	var stageParams:Array<Array<String>>;
	var currentStageIndex = 0;
	var sorted:Bool;
	
	var lights:Array<LightNode>;
	public var currentLightIndex = 0;

	// Quad and decals contexts
	var cachedShaderContexts:Map<String, CachedShaderContext> = new Map();
	
#if WITH_PROFILE
	public static var drawCalls = 0;
	public var passNames:Array<String>;
	public var passTimes:Array<Float>;
	public var passEnabled:Array<Bool>;
	var currentPass:Int;
#end

	public function new(camera:CameraNode) {
		this.camera = camera;
		resource = camera.resource;

		cacheStageCommands();

		if (screenAlignedVB == null) createScreenAlignedData();
		if (decalVB == null) createDecalData();
		if (skydomeVB == null) createSkydomeData();
	}

	static function createScreenAlignedData() {
		var data = [-1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0];
		var indices = [0, 1, 2, 0, 2, 3];

		// TODO: Mandatory vertex data names and sizes
		// pos=2
		var struct = ShaderResource.createScreenAlignedQuadStructure();
		screenAlignedVB = new VertexBuffer(Std.int(data.length / Std.int(struct.byteSize() / 4)), struct, Usage.StaticUsage);
		var vertices = screenAlignedVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		screenAlignedVB.unlock();

		screenAlignedIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = screenAlignedIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
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
		var struct = ShaderResource.createDecalStructure();
		decalVB = new VertexBuffer(Std.int(data.length / Std.int(struct.byteSize() / 4)), struct, Usage.StaticUsage);
		var vertices = decalVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		decalVB.unlock();

		decalIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = decalIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		decalIB.unlock();
	}

	static function createSkydomeData() {
		// pos=3, nor=3
		var struct = ShaderResource.createSkydomeStructure();
		var structLength = Std.int(struct.byteSize() / 4);
		var pos = iron.resource.ConstData.skydomePos;
		var nor = iron.resource.ConstData.skydomeNor;
		skydomeVB = new VertexBuffer(Std.int(pos.length / 3), struct, Usage.StaticUsage);
		var vertices = skydomeVB.lock();
		for (i in 0...Std.int(vertices.length / structLength)) {
			vertices.set(i * structLength, pos[i * 3]);
			vertices.set(i * structLength + 1, pos[i * 3 + 1]);
			vertices.set(i * structLength + 2, pos[i * 3 + 2]);
			vertices.set(i * structLength + 3, -nor[i * 3]); // Flip to match quad
			vertices.set(i * structLength + 4, -nor[i * 3 + 1]);
			vertices.set(i * structLength + 5, -nor[i * 3 + 2]);
		}
		skydomeVB.unlock();

		var indices = iron.resource.ConstData.skydomeIndices;
		skydomeIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = skydomeIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		skydomeIB.unlock();
	}

	public function renderFrame(g:Graphics, root:Node, lights:Array<LightNode>) {
#if WITH_PROFILE
		drawCalls = 0;
		currentPass = 0;
#end

		frameRenderTarget = g;
		currentRenderTarget = g;
		currentRenderTargetW = iron.App.w;
		currentRenderTargetH = iron.App.h;
		sorted = false;

		this.lights = lights;
		currentLightIndex = 0;
		
		for (l in lights) l.buildMatrices(camera);

		for (i in 0...stageCommands.length) {
#if WITH_PROFILE
			var cmd = stageCommands[i];
			if (!passEnabled[currentPass]) {
				if (cmd == drawGeometry || cmd == drawSkydome || cmd == drawDecals || cmd == drawMaterialQuad || cmd == drawShaderQuad) {
					endPass();
				}
				continue;
			}
			var startTime = kha.Scheduler.realTime();
#end
			currentStageIndex = i;
			stageCommands[i](stageParams[i], root);

#if WITH_PROFILE
			if (cmd == drawGeometry || cmd == drawSkydome || cmd == drawDecals || cmd == drawMaterialQuad || cmd == drawShaderQuad) {
				passTimes[currentPass] = kha.Scheduler.realTime() - startTime;
				endPass();
			}
#end
		}
	}

#if WITH_PROFILE
	function endPass() {
		if (loopFinished) {
			currentPass++;
		}
	}
#end
	
	public static var lastPongRT:RenderTarget;
	var loopFinished = true;
	var drawPerformed = false;
	function setTarget(params:Array<String>, root:Node) {
		// Ping-pong
		if (lastPongRT != null && drawPerformed && loopFinished) { // Drawing to pong texture has been done, switch state
			lastPongRT.pongState = !lastPongRT.pongState;
			lastPongRT = null;
		}
		drawPerformed = false;
		
    	var target = params[0];
    	if (target == "") {
    		currentRenderTarget = frameRenderTarget;
    		currentRenderTargetW = iron.App.w;
			currentRenderTargetH = iron.App.h;
    		begin(currentRenderTarget);
    	}
		else {			
			var rt = resource.pipeline.renderTargets.get(target);
			var additionalImages:Array<kha.Canvas> = null;
			if (params.length > 1) {
				additionalImages = [];
				for (i in 1...params.length) {
					var t = resource.pipeline.renderTargets.get(params[i]);
					additionalImages.push(t.image);
				}
			}
			
			// Ping-pong
			if (rt.pong != null) {
				lastPongRT = rt;
				if (rt.pongState) rt = rt.pong;
			}
			
			currentRenderTarget = rt.image.g4;
			currentRenderTargetW = rt.image.width;
			currentRenderTargetH = rt.image.height;
			begin(currentRenderTarget, additionalImages);
		}
		bindParams = null;
    }

    function clearTarget(params:Array<String>, root:Node) {
		var colorFlag:Null<Int> = null;
		var depthFlag:Null<Float> = null;
		
		// TODO: Cache parsed clear flags
		for (i in 0...Std.int(params.length / 2)) {
			var pos = i * 2;
			var val = pos + 1;
			if (params[pos] == "color") {
				colorFlag = Color.fromString(params[val]);
			}
			else if (params[pos] == "depth") {
				if (params[val] == "1.0") depthFlag = 1.0;
				else depthFlag = 0.0;
			}
			// else if (params[pos] == "stencil") {}
		}
		
		currentRenderTarget.clear(colorFlag, depthFlag, null);
    }

    function drawGeometry(params:Array<String>, root:Node) {
		var context = params[0];
		if (!sorted && params[1] == "front_to_back") { // Order max one per frame
			var camX = camera.transform.absx();
			var camY = camera.transform.absy();
			var camZ = camera.transform.absz();
			for (model in RootNode.models) {
				model.computeCameraDistance(camX, camY, camZ);
			}
			RootNode.models.sort(function(a, b):Int {
				return a.cameraDistance > b.cameraDistance ? 1 : -1;
			});
			sorted = true;
		}
		var g = currentRenderTarget;
		var light = lights[currentLightIndex];
		// if (params[1] == "back_to_front") {
		// 	var len = RootNode.models.length;
		// 	for (i in 0...len) {
		// 		RootNode.models[len - 1 - i].render(g, context, camera, light, bindParams);
		// 	}
		// }
		// else {
			for (model in RootNode.models) {
				model.render(g, context, camera, light, bindParams);
			}
		// }
		end(g);
    }
	
	function drawDecals(params:Array<String>, root:Node) {
		var context = params[0];
		var g = currentRenderTarget;
		var light = lights[currentLightIndex];
		for (decal in RootNode.decals) {
			decal.render(g, context, camera, light, bindParams);
			g.setVertexBuffer(decalVB);
			g.setIndexBuffer(decalIB);
			g.drawIndexedVertices();
		}
		end(g);
    }

    function drawSkydome(params:Array<String>, root:Node) {
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

		var g = currentRenderTarget;
		g.setPipeline(cc.context.pipeState);
		var light = lights[currentLightIndex];
		ModelNode.setConstants(g, cc.context, null, camera, light, bindParams);
		if (cc.materialContext != null) {
			ModelNode.setMaterialConstants(g, cc.context, cc.materialContext);
		}
		g.setVertexBuffer(skydomeVB);
		g.setIndexBuffer(skydomeIB);
		g.drawIndexedVertices();
		end(g);
    }

    function bindTarget(params:Array<String>, root:Node) {
    	if (bindParams != null) for (p in params) bindParams.push(p); // Multiple binds, append params
		else bindParams = params;
    }
	
	function drawShaderQuad(params:Array<String>, root:Node) {
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
		drawQuad(cc, root);
	}
	
	function drawMaterialQuad(params:Array<String>, root:Node) {
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
		drawQuad(cc, root);
	}

    function drawQuad(cc:CachedShaderContext, root:Node) {
		var g = currentRenderTarget;		
		g.setPipeline(cc.context.pipeState);
		var light = lights[currentLightIndex];

		ModelNode.setConstants(g, cc.context, null, camera, light, bindParams);
		if (cc.materialContext != null) {
			ModelNode.setMaterialConstants(g, cc.context, cc.materialContext);
		}

		g.setVertexBuffer(screenAlignedVB);
		g.setIndexBuffer(screenAlignedIB);
		g.drawIndexedVertices();
		
		end(g);
    }

	function callFunction(params:Array<String>, root:Node) {
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
				commandFun(stage.params, root);
			}
		}
	}
	
	function loopLights(params:Array<String>, root:Node) {
		var stageData = resource.pipeline.resource.stages[currentStageIndex];
		
		currentLightIndex = 0;
		loopFinished = false;
		for (l in lights) {
			for (stage in stageData.returns_true) {
				// TODO: cache commands
				var commandFun = commandToFunction(stage.command);			
				commandFun(stage.params, root);
			}
			currentLightIndex++;
		}
		currentLightIndex = 0;
		loopFinished = true;

#if WITH_PROFILE
		endPass();
#end
	}

	inline function begin(g:Graphics, additionalRenderTargets:Array<kha.Canvas> = null) {
		#if !python
		g.begin(additionalRenderTargets);
		#end
	}

	inline function end(g:Graphics) {
		#if !python
		g.end();
		bindParams = null; // Remove, cleared at begin
		#end
		drawPerformed = true;
	}

    function cacheStageCommands() {
    	stageCommands = [];
    	stageParams = [];
#if WITH_PROFILE
		passNames = [];
		passTimes = [];
		passEnabled = [];
#end

    	for (stage in resource.pipeline.resource.stages) {
			stageCommands.push(commandToFunction(stage.command));
			stageParams.push(stage.params);
#if WITH_PROFILE
			if (stage.command.substr(0, 4) == "draw") {
				var splitParams = stage.params[0].split("_");
				var passName = splitParams[0];
				for (i in 1...splitParams.length) {
					// Remove from '_pass' or appended defs, starting with upper case letter
					if (splitParams[i] == "pass" || splitParams[i].charAt(0) == splitParams[i].charAt(0).toUpperCase()) {
						for (j in 1...i) passName += "_" + splitParams[j];
						break;
					}
				}
				passNames.push(passName);
				passTimes.push(0.0);
				passEnabled.push(true);
			}
			// Combine into single entry for now
			else if (stage.command == "loop_lights") {
				passNames.push(stage.command);
				passTimes.push(0.0);
				passEnabled.push(true);
			}
#end
		}
    }
	
	function commandToFunction(command:String):TStageCommand {
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
		else if (command == "draw_skydome") {
			return drawSkydome;
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
		else if (command == "loop_lights") {
			return loopLights;
		}
		return null;
	}
}

class CachedShaderContext {
	public var materialContext:MaterialContext;
	public var context:ShaderContext;
	public function new() {}
}
