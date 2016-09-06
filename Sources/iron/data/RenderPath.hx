package iron.data;

import kha.Color;
import kha.Scheduler;
import kha.graphics4.Graphics;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import iron.data.SceneFormat;
import iron.data.RenderPathData.RenderTarget; // Ping-pong
import iron.data.MaterialData.MaterialContext;
import iron.data.ShaderData.ShaderContext;
import iron.Scene;
import iron.object.Object;
import iron.object.CameraObject;
import iron.object.LampObject;
import iron.object.Uniforms;

#if cpp
@:headerCode('
#include <Kore/pch.h>
#include <Kore/Graphics/Graphics.h>
')
#end

typedef TStageCommand = Array<String>->Object->Void;

class RenderPath {

	var camera:CameraObject;
	public var data:CameraData;

	var frameRenderTarget:Graphics;
	var currentRenderTarget:Graphics;
	public var currentRenderTargetW:Int;
	public var currentRenderTargetH:Int;
	var bindParams:Array<String>;

	static var screenAlignedVB:VertexBuffer = null;
	static var screenAlignedIB:IndexBuffer = null;
	static var boxVB:VertexBuffer = null;
	static var boxIB:IndexBuffer = null;
	static var skydomeVB:VertexBuffer = null;
	static var skydomeIB:IndexBuffer = null;

	var stageCommands:Array<TStageCommand>;
	var stageParams:Array<Array<String>>;
	var currentStageIndex = 0;
	var sorted:Bool;
	
	var lamps:Array<LampObject>;
	public var currentLampIndex = 0;

	// Quad and decals contexts
	var cachedShaderContexts:Map<String, CachedShaderContext> = new Map();
	
#if WITH_PROFILE
	public static var drawCalls = 0;
	public var passNames:Array<String>;
	public var passTimes:Array<Float>;
	public var passEnabled:Array<Bool>;
	var currentPass:Int;
#end

	public function new(camera:CameraObject) {
		this.camera = camera;
		data = camera.data;

		cacheStageCommands();

		if (screenAlignedVB == null) createScreenAlignedData();
		if (boxVB == null) createBoxData();
		if (skydomeVB == null) createSkydomeData();
	}

	static function createScreenAlignedData() {
		var data = [-1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0];
		var indices = [0, 1, 2, 0, 2, 3];

		// TODO: Mandatory vertex data names and sizes
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float2);
		screenAlignedVB = new VertexBuffer(Std.int(data.length / Std.int(structure.byteSize() / 4)), structure, Usage.StaticUsage);
		var vertices = screenAlignedVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		screenAlignedVB.unlock();

		screenAlignedIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = screenAlignedIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		screenAlignedIB.unlock();
	}
	
	static function createBoxData() {
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

		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		boxVB = new VertexBuffer(Std.int(data.length / Std.int(structure.byteSize() / 4)), structure, Usage.StaticUsage);
		var vertices = boxVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		boxVB.unlock();

		boxIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = boxIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		boxIB.unlock();
	}

	static function createSkydomeData() {
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		structure.add("nor", VertexData.Float3);
		var structLength = Std.int(structure.byteSize() / 4);
		var pos = iron.data.ConstData.skydomePos;
		var nor = iron.data.ConstData.skydomeNor;
		skydomeVB = new VertexBuffer(Std.int(pos.length / 3), structure, Usage.StaticUsage);
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

		var indices = iron.data.ConstData.skydomeIndices;
		skydomeIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = skydomeIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		skydomeIB.unlock();
	}

	public function renderFrame(g:Graphics, root:Object, lamps:Array<LampObject>) {
#if WITH_PROFILE
		drawCalls = 0;
		currentPass = 0;
#end

		frameRenderTarget = camera.data.mirror == null ? g : camera.data.mirror.g4; // Render to screen or camera texture
		currentRenderTarget = g;
		currentRenderTargetW = iron.App.w;
		currentRenderTargetH = iron.App.h;
		sorted = false;

		this.lamps = lamps;
		currentLampIndex = 0;
		
		for (l in lamps) l.buildMatrices(camera);

		for (i in 0...stageCommands.length) {
#if WITH_PROFILE
			var cmd = stageCommands[i];
			if (!passEnabled[currentPass]) {
				if (cmd == drawMeshes || cmd == drawSkydome || cmd == drawLampVolume || cmd == drawDecals || cmd == drawMaterialQuad || cmd == drawShaderQuad) {
					endPass();
				}
				continue;
			}
			var startTime = kha.Scheduler.realTime();
#end

			currentStageIndex = i;
			stageCommands[i](stageParams[i], root);

#if WITH_PROFILE
			if (cmd == drawMeshes || cmd == drawSkydome || cmd == drawLampVolume || cmd == drawDecals || cmd == drawMaterialQuad || cmd == drawShaderQuad) {
				passTimes[currentPass] = kha.Scheduler.realTime() - startTime;
				endPass();
			}
#end
		}
	}

#if WITH_PROFILE
	function endPass() {
		if (loopFinished == 0) {
			currentPass++;
		}
	}
#end
	
	public static var lastPongRT:RenderTarget;
	var loopFinished = 0;
	var drawPerformed = false;
	function setTarget(params:Array<String>, root:Object) {
		// Ping-pong
		if (lastPongRT != null && drawPerformed && loopFinished == 0) { // Drawing to pong texture has been done, switch state
			lastPongRT.pongState = !lastPongRT.pongState;
			lastPongRT = null;
		}
		drawPerformed = false;
		
		var target = params[1];
		if (target == "") {
			currentRenderTarget = frameRenderTarget;
			currentRenderTargetW = iron.App.w;
			currentRenderTargetH = iron.App.h;
			begin(currentRenderTarget);
		}
		else {			
			var rt = data.pathdata.renderTargets.get(target);
			var additionalImages:Array<kha.Canvas> = null;
			if (params.length > 2) {
				additionalImages = [];
				for (i in 2...params.length) {
					var t = data.pathdata.renderTargets.get(params[i]);
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
		var viewportScale = Std.parseFloat(params[0]);
		if (viewportScale != 1.0) {
			var viewW = Std.int(currentRenderTargetW * viewportScale);
			var viewH = Std.int(currentRenderTargetH * viewportScale);
			currentRenderTarget.viewport(0, viewH, viewW, viewH);
			// currentRenderTarget.viewport(0, 0, viewW, viewH);
		}
		// else { // Set by Kha
			// currentRenderTarget.viewport(0, 0, currentRenderTargetW, currentRenderTargetH);
		// }
		bindParams = null;
	}

	function clearTarget(params:Array<String>, root:Object) {
		var colorFlag:Null<Int> = null;
		var depthFlag:Null<Float> = null;
		
		// TODO: Cache parsed clear flags
		for (i in 0...Std.int(params.length / 2)) {
			var pos = i * 2;
			var val = pos + 1;
			if (params[pos] == "color") {
				colorFlag = params[val] == '-1' ? Scene.active.world.raw.background_color : Color.fromString(params[val]);
			}
			else if (params[pos] == "depth") {
				// TODO: Fix non-independent depth clearing
				#if cpp
					untyped __cpp__("Kore::Graphics::setRenderState(Kore::DepthWrite, true);");
				#else
					kha.SystemImpl.gl.depthMask(true);
				#end

				if (params[val] == "1.0") depthFlag = 1.0;
				else depthFlag = 0.0;
			}
			// else if (params[pos] == "stencil") {}
		}
		
		currentRenderTarget.clear(colorFlag, depthFlag, null);
	}

	function drawMeshes(params:Array<String>, root:Object) {
		var context = params[0];
		var lamp = lamps[currentLampIndex];

		// Disabled shadow casting for this lamp
		if (context == data.pathdata.raw.shadows_context && !lamp.data.raw.cast_shadow) return;

		if (!sorted && params[1] == "front_to_back") { // Order max one per frame
			var camX = camera.transform.absx();
			var camY = camera.transform.absy();
			var camZ = camera.transform.absz();
			for (mesh in Scene.active.meshes) {
				mesh.computeCameraDistance(camX, camY, camZ);
			}
			Scene.active.meshes.sort(function(a, b):Int {
				return a.cameraDistance > b.cameraDistance ? 1 : -1;
			});
			sorted = true;
		}
		var g = currentRenderTarget;
		// if (params[1] == "back_to_front") {
		// 	var len = Scene.active.meshes.length;
		// 	for (i in 0...len) {
		// 		Scene.active.meshes[len - 1 - i].render(g, context, camera, lamp, bindParams);
		// 	}
		// }
		// else {
			for (mesh in Scene.active.meshes) {
				mesh.render(g, context, camera, lamp, bindParams);
			}
		// }
		end(g);
	}
	
	function drawDecals(params:Array<String>, root:Object) {
		var context = params[0];
		var g = currentRenderTarget;
		var lamp = lamps[currentLampIndex];
		for (decal in Scene.active.decals) {
			decal.render(g, context, camera, lamp, bindParams);
			g.setVertexBuffer(boxVB);
			g.setIndexBuffer(boxIB);
			g.drawIndexedVertices();
		}
		end(g);
	}

	function parseMaterialLink(handle:String):Array<String> {
		if (handle == '_worldMaterial') return Scene.active.world.raw.material_ref.split('/');
		return null;
	}

	function drawSkydome(params:Array<String>, root:Object) {
		var handle = params[0];
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc == null) {
			var matPath:Array<String> = null;
			if (handle.charAt(0) == '_') matPath = parseMaterialLink(handle);
			else matPath = handle.split('/');
			var res = Data.getMaterial(matPath[0], matPath[1]);
			cc = new CachedShaderContext();
			cc.materialContext = res.getContext(matPath[2]);
			cc.context = res.shader.getContext(matPath[2]);
			cachedShaderContexts.set(handle, cc);
		}

		var g = currentRenderTarget;
		g.setPipeline(cc.context.pipeState);
		var lamp = lamps[currentLampIndex];
		Uniforms.setConstants(g, cc.context, null, camera, lamp, bindParams);
		if (cc.materialContext != null) {
			Uniforms.setMaterialConstants(g, cc.context, cc.materialContext);
		}
		g.setVertexBuffer(skydomeVB);
		g.setIndexBuffer(skydomeIB);
		g.drawIndexedVertices();
		end(g);
	}

	function drawLampVolume(params:Array<String>, root:Object) {
		var handle = params[0];
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc == null) {
			var shaderPath = handle.split("/");
			var res = Data.getShader(shaderPath[0], shaderPath[1]);
			cc = new CachedShaderContext();
			cc.materialContext = null;
			cc.context = res.getContext(shaderPath[2]);
			cachedShaderContexts.set(handle, cc);
		}
		var g = currentRenderTarget;		
		g.setPipeline(cc.context.pipeState);
		var lamp = lamps[currentLampIndex];
		Uniforms.setConstants(g, cc.context, null, camera, lamp, bindParams);
		if (cc.materialContext != null) {
			Uniforms.setMaterialConstants(g, cc.context, cc.materialContext);
		}
		g.setVertexBuffer(boxVB);
		g.setIndexBuffer(boxIB);
		g.drawIndexedVertices();
		end(g);
	}

	function bindTarget(params:Array<String>, root:Object) {
		if (bindParams != null) for (p in params) bindParams.push(p); // Multiple binds, append params
		else bindParams = params;
	}
	
	function drawShaderQuad(params:Array<String>, root:Object) {
		var handle = params[0];
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc == null) {
			var shaderPath = handle.split("/");
			var res = Data.getShader(shaderPath[0], shaderPath[1]);
			cc = new CachedShaderContext();
			cc.materialContext = null;
			cc.context = res.getContext(shaderPath[2]);
			cachedShaderContexts.set(handle, cc);
		}
		drawQuad(cc, root);
	}
	
	function drawMaterialQuad(params:Array<String>, root:Object) {
		var handle = params[0];
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc == null) {
			var matPath:Array<String> = null;
			if (handle.charAt(0) == '_') matPath = parseMaterialLink(handle);
			else matPath = handle.split('/');
			var res = Data.getMaterial(matPath[0], matPath[1]);
			cc = new CachedShaderContext();
			cc.materialContext = res.getContext(matPath[2]);
			cc.context = res.shader.getContext(matPath[2]);
			cachedShaderContexts.set(handle, cc);
		}
		drawQuad(cc, root);
	}

	function drawQuad(cc:CachedShaderContext, root:Object) {
		var g = currentRenderTarget;		
		g.setPipeline(cc.context.pipeState);
		var lamp = lamps[currentLampIndex];

		Uniforms.setConstants(g, cc.context, null, camera, lamp, bindParams);
		if (cc.materialContext != null) {
			Uniforms.setMaterialConstants(g, cc.context, cc.materialContext);
		}

		g.setVertexBuffer(screenAlignedVB);
		g.setIndexBuffer(screenAlignedIB);
		g.drawIndexedVertices();
		
		end(g);
	}

	function callFunction(params:Array<String>, root:Object) {
		// TODO: cache
		var path = params[0];
		var dotIndex = path.lastIndexOf(".");
		var classPath = path.substr(0, dotIndex);
		var classType = Type.resolveClass(classPath);
		var funName = path.substr(dotIndex + 1);
		var stageData = data.pathdata.raw.stages[currentStageIndex];
		// Call function
		if (stageData.returns_true == null && stageData.returns_false == null) {
			Reflect.callMethod(classType, Reflect.field(classType, funName), []);
		}
		// Branch function
		else {
			var result:Bool = Reflect.callMethod(classType, Reflect.field(classType, funName), []);
			// Nested commands
			var stages:Array<TRenderPathStage> = null;
			if (result) stages = stageData.returns_true;
			else stages = stageData.returns_false;
			for (stage in stages) {
				// TODO: cache commands
				var commandFun = commandToFunction(stage.command);			
				commandFun(stage.params, root);
			}
		}
	}
	
	function loopLamps(params:Array<String>, root:Object) {
		var stageData = data.pathdata.raw.stages[currentStageIndex];
		
		currentLampIndex = 0;
		loopFinished++;
		for (i in 0...lamps.length) {
			var l = lamps[i];
			if (!l.visible) continue;
			currentLampIndex = i;
			for (stage in stageData.returns_true) {
				// TODO: cache commands
				var commandFun = commandToFunction(stage.command);			
				commandFun(stage.params, root);
			}
		}
		currentLampIndex = 0;
		loopFinished--;

#if WITH_PROFILE
		endPass();
#end
	}

#if WITH_VR
	function drawStereo(params:Array<String>, root:Object) {
		var stageData = data.pathdata.raw.stages[currentStageIndex];
		
		loopFinished++;
		var g = currentRenderTarget;
		var halfW = Std.int(currentRenderTargetW / 2);

		// Left eye
		g.viewport(0, 0, halfW, currentRenderTargetH);

		for (stage in stageData.returns_true) {
			var commandFun = commandToFunction(stage.command);			
			commandFun(stage.params, root);
		}

		// Right eye
		// TODO: For testing purposes only
		camera.move(camera.right(), 0.032);
		camera.updateMatrix();
		g.viewport(halfW, 0, halfW, currentRenderTargetH);

		for (stage in stageData.returns_true) {
			var commandFun = commandToFunction(stage.command);			
			commandFun(stage.params, root);
		}

		camera.move(camera.right(), -0.032);
		camera.updateMatrix();

		loopFinished--;

	#if WITH_PROFILE
		endPass();
	#end
	}
#end

	inline function begin(g:Graphics, additionalRenderTargets:Array<kha.Canvas> = null) {
		// #if !python
		g.begin(additionalRenderTargets);
		// #end
	}

	inline function end(g:Graphics) {
		// #if !python
		g.end();
		bindParams = null; // Remove, cleared at begin
		// #end
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

		for (stage in data.pathdata.raw.stages) {
			stageCommands.push(commandToFunction(stage.command));
			stageParams.push(stage.params);
#if WITH_PROFILE
			if (stage.command != "draw_stereo" && stage.command.substr(0, 4) == "draw") {
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
			else if (stage.command == "loop_lamps" || stage.command == "loop_stages" || stage.command == "draw_stereo") {
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
		else if (command == "draw_meshes") {
			return drawMeshes;
		}
		else if (command == "draw_decals") {
			return drawDecals;
		}
		else if (command == "draw_skydome") {
			return drawSkydome;
		}
		else if (command == "draw_lamp_volume") {
			return drawLampVolume;
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
		else if (command == "loop_lamps") {
			return loopLamps;
		}
#if WITH_VR
		else if (command == "draw_stereo") {
			return drawStereo;
		}
#end
		return null;
	}
}

class CachedShaderContext {
	public var materialContext:MaterialContext;
	public var context:ShaderContext;
	public function new() {}
}
