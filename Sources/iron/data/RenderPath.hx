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

typedef TStageCommand = Array<String>->Object->Void;
typedef TStageParams = Array<String>;

class RenderPath {

	var camera:CameraObject;
	public var data:CameraData;

	var frameRenderTarget:Graphics;
	var currentRenderTarget:Graphics;
	public var currentRenderTargetW:Int;
	public var currentRenderTargetH:Int;
	public var currentRenderTargetD:Int;
	var bindParams:Array<String>;

	static var screenAlignedVB:VertexBuffer = null;
	static var screenAlignedIB:IndexBuffer = null;
	static var boxVB:VertexBuffer = null;
	static var boxIB:IndexBuffer = null;
	static var skydomeVB:VertexBuffer = null;
	static var skydomeIB:IndexBuffer = null;

	var stageCommands:Array<TStageCommand>;
	var stageParams:Array<TStageParams>;
	var currentStageIndex = 0;
	var nestedCommands:Map<String, Array<TStageCommand>> = new Map(); // Just one level deep nesting for now
	var nestedParams:Map<String, Array<TStageParams>> = new Map();
	var sorted:Bool;
	public var waiting:Bool;
	
	var lamps:Array<LampObject>;
	public var currentLampIndex = 0;

	// Quad and decals contexts
	var cachedShaderContexts:Map<String, CachedShaderContext> = new Map();
	
#if WITH_PROFILE
	public static var drawCalls = 0;
	public var passNames:Array<String>;
	public var passEnabled:Array<Bool>;
	var currentPass:Int;
#end

	public function new(camera:CameraObject) {
		this.camera = camera;
		data = camera.data;

		waiting = true;
		stageCommands = [];
		stageParams = [];
		cacheStageCommands(stageCommands, stageParams, data.pathdata.raw.stages, function() { waiting = false; });

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
		if (waiting) return;

#if WITH_PROFILE
		drawCalls = 0;
		currentPass = 0;
#end

		frameRenderTarget = camera.data.mirror == null ? g : camera.data.mirror.g4; // Render to screen or camera texture
		currentRenderTarget = g;
		currentRenderTargetW = iron.App.w();
		currentRenderTargetH = iron.App.h();
		currentRenderTargetD = 1;
		sorted = false;

		this.lamps = lamps;
		currentLampIndex = 0;
		
		for (l in lamps) l.buildMatrices(camera);

		for (i in 0...stageCommands.length) {
#if WITH_PROFILE
			var cmd = stageCommands[i];
			if (!passEnabled[currentPass]) {
				if (cmd == drawMeshes || cmd == drawSkydome || cmd == drawLampVolume || cmd == drawDecals || cmd == drawMaterialQuad || cmd == drawShaderQuad || cmd == drawGreasePencil) {
					endPass();
				}
				continue;
			}
#end

			currentStageIndex = i;
			stageCommands[i](stageParams[i], root);

#if WITH_PROFILE
			if (cmd == drawMeshes || cmd == drawSkydome || cmd == drawLampVolume || cmd == drawDecals || cmd == drawMaterialQuad || cmd == drawShaderQuad || cmd == drawGreasePencil) {
				endPass();
			}
#end
		}
	}
	
#if WITH_PROFILE
	function endPass() {
		if (loopFinished == 0) currentPass++;
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
		if (target == "") { // Framebuffer
			currentRenderTarget = frameRenderTarget;
			currentRenderTargetW = iron.App.w();
			currentRenderTargetH = iron.App.h();
			currentRenderTargetD = 1;
			begin(currentRenderTarget);
		}
		else { // Render target
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
			if (rt.is3D) currentRenderTargetD = rt.image.depth;
			begin(currentRenderTarget, additionalImages);
		}
		var viewportScale = Std.parseFloat(params[0]);
		if (viewportScale != 1.0) {
			var viewW = Std.int(currentRenderTargetW * viewportScale);
			var viewH = Std.int(currentRenderTargetH * viewportScale);
			currentRenderTarget.viewport(0, viewH, viewW, viewH);
		}
		bindParams = null;
	}

	function setViewport(params:Array<String>, root:Object) {
		var viewW = Std.int(Std.parseFloat(params[0]));
		var viewH = Std.int(Std.parseFloat(params[1]));
		// glViewport(x, _renderTargetHeight - y - height, width, height);
		currentRenderTarget.viewport(0, currentRenderTargetH - viewH, viewW, viewH);
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
				if (params[val] == "1.0") depthFlag = 1.0;
				else depthFlag = 0.0;
			}
			// else if (params[pos] == "stencil") {}
		}
		
		currentRenderTarget.clear(colorFlag, depthFlag, null);
	}

	function generateMipmaps(params:Array<String>, root:Object) {
		var target = params[0];
		var rt = data.pathdata.renderTargets.get(target);
		rt.image.generateMipmaps(1000);
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

	static var gpFrame = 0;
	function drawGreasePencil(params:Array<String>, root:Object) {
		var gp = Scene.active.greasePencil;
		if (gp == null) return;
		var g = currentRenderTarget;
		var lamp = lamps[currentLampIndex];
		var context = GreasePencilData.getContext(params[0]);
		g.setPipeline(context.pipeState);
		Uniforms.setConstants(g, context, null, camera, lamp, null);
		// Draw layers
		for (layer in gp.layers) {
			// Next frame
			if (layer.frames.length - 1 > layer.currentFrame && gpFrame >= layer.frames[layer.currentFrame + 1].raw.frame_number) {
				layer.currentFrame++;
			}
			var frame = layer.frames[layer.currentFrame];
			if (frame.numVertices > 0) {
				g.setVertexBuffer(frame.vertexBuffer);
				g.setIndexBuffer(frame.indexBuffer);
				g.drawIndexedVertices();
#if js
				// TODO: temporary, construct triangulated lines from points instead
				g.setVertexBuffer(frame.vertexStrokeBuffer);
				kha.SystemImpl.gl.lineWidth(3);
				var start = 0;
				for (i in frame.raw.num_stroke_points) {
					kha.SystemImpl.gl.drawArrays(js.html.webgl.GL.LINE_STRIP, start, i);
					start += i;
				}
#end
			}
		}
		gpFrame++;
		// Reset timeline
		if (gpFrame > GreasePencilData.frameEnd) {
			gpFrame = 0;
			for (layer in gp.layers) layer.currentFrame = 0;
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
		drawQuad(cc, root);
	}
	
	function drawMaterialQuad(params:Array<String>, root:Object) {
		var handle = params[0];
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
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
			var key = currentStageIndex + '';
			key = result ? key + '_true' : key + '_false';
			var stageCommands:Array<TStageCommand> = nestedCommands.get(key);
			var stageParams:Array<TStageParams> = nestedParams.get(key);
			for (i in 0...stageCommands.length) {
				stageCommands[i](stageParams[i], root);
			}
		}
	}
	
	function loopLamps(params:Array<String>, root:Object) {
		var key = currentStageIndex + '_true';
		var stageCommands:Array<TStageCommand> = nestedCommands.get(key);
		var stageParams:Array<TStageParams> = nestedParams.get(key);
		
		currentLampIndex = 0;
		loopFinished++;
		for (i in 0...lamps.length) {
			var l = lamps[i];
			if (!l.visible) continue;
			currentLampIndex = i;
			for (i in 0...stageCommands.length) {
				stageCommands[i](stageParams[i], root);
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
		var key = currentStageIndex + '_true';
		var stageCommands:Array<TStageCommand> = nestedCommands.get(key);
		var stageParams:Array<TStageParams> = nestedParams.get(key);

		loopFinished++;
		var g = currentRenderTarget;
		var halfW = Std.int(currentRenderTargetW / 2);

		// Left eye
		g.viewport(0, 0, halfW, currentRenderTargetH);
		for (i in 0...stageCommands.length) {
			stageCommands[i](stageParams[i], root);
		}

		// Right eye
		// TODO: For testing purposes only
		camera.move(camera.right(), 0.032);
		camera.buildMatrix();
		g.viewport(halfW, 0, halfW, currentRenderTargetH);
		for (i in 0...stageCommands.length) {
			stageCommands[i](stageParams[i], root);
		}

		camera.move(camera.right(), -0.032);
		camera.buildMatrix();

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

	function cacheStageCommands(stageCommands:Array<TStageCommand>, stageParams:Array<TStageParams>, stages:Array<TRenderPathStage>, done:Void->Void) {
#if WITH_PROFILE
		var setPasses = this.stageCommands == stageCommands;
		if (setPasses) {
			passNames = [];
			passEnabled = [];
		}
#end

		while (stageCommands.length < stages.length) stageCommands.push(null);
		var stagesLoaded = 0;

		for (i in 0...stages.length) {
			var stage = stages[i];

			stageParams.push(stage.params);
			commandToFunction(stage, i, function(cmd:TStageCommand) {
				stageCommands[i] = cmd;
				
				stagesLoaded++;
				if (stagesLoaded == stages.length) done();
			});

#if WITH_PROFILE
			if (setPasses) {
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
					passEnabled.push(true);
				}
				// Combine into single entry for now
				else if (stage.command == "loop_lamps" || stage.command == "loop_stages" || stage.command == "draw_stereo") {
					passNames.push(stage.command);
					passEnabled.push(true);
				}
			}
#end
		}
	}
	
	function commandToFunction(stage:TRenderPathStage, parsedStageIndex:Int, done:TStageCommand->Void) {
		var handle = stage.params.length > 0 ? stage.params[0] : '';
		switch (stage.command) {
			case "set_target": done(setTarget);
			case "set_viewport": done(setViewport);
			case "clear_target": done(clearTarget);
			case "generate_mipmaps": done(generateMipmaps);
			case "draw_meshes": done(drawMeshes);
			case "draw_decals": done(drawDecals);
			case "draw_skydome": cacheMaterialQuad(handle, function() { done(drawSkydome); });
			case "draw_lamp_volume": cacheShaderQuad(handle, function() { done(drawLampVolume); });
			case "bind_target": done(bindTarget);
			case "draw_shader_quad": cacheShaderQuad(handle, function() { done(drawShaderQuad); });
			case "draw_material_quad": cacheMaterialQuad(handle, function() { done(drawMaterialQuad); });
			case "draw_grease_pencil": done(drawGreasePencil);
			case "call_function": cacheReturnsBoth(stage, parsedStageIndex, function() { done(callFunction); });
			case "loop_lamps": cacheReturnsTrue(stage, parsedStageIndex, function() { done(loopLamps); });
#if WITH_VR
			case "draw_stereo": cacheReturnsTrue(stage, parsedStageIndex, function() { done(drawStereo); });
#end
			default: done(null);
		}
	}

	function cacheReturnsBoth(stageData:TRenderPathStage, parsedStageIndex:Int, done:Void->Void) {
		var key = parsedStageIndex + '';
		var cached = 0;
		var cacheTo = 0;
		if (stageData.returns_true != null) cacheTo++;
		if (stageData.returns_false != null) cacheTo++;
		if (cacheTo == 0) done();

		if (stageData.returns_true != null) {
			var stageCommands:Array<TStageCommand> = [];
			var stageParams:Array<TStageParams> = [];
			nestedCommands.set(key + '_true', stageCommands);
			nestedParams.set(key + '_true', stageParams);

			cacheStageCommands(stageCommands, stageParams, stageData.returns_true, function() { cached++; if (cached == cacheTo) done(); });
		}

		if (stageData.returns_false != null) {
			var stageCommands:Array<TStageCommand> = [];
			var stageParams:Array<TStageParams> = [];
			nestedCommands.set(key + '_false', stageCommands);
			nestedParams.set(key + '_false', stageParams);

			cacheStageCommands(stageCommands, stageParams, stageData.returns_false, function() { cached++; if (cached == cacheTo) done(); });
		}

	}

	function cacheReturnsTrue(stageData:TRenderPathStage, parsedStageIndex:Int, done:Void->Void) {
		var key = parsedStageIndex + '_true';

		if (stageData.returns_true != null) {
			var stageCommands:Array<TStageCommand> = [];
			var stageParams:Array<TStageParams> = [];
			nestedCommands.set(key, stageCommands);
			nestedParams.set(key, stageParams);

			cacheStageCommands(stageCommands, stageParams, stageData.returns_true, done);
		}
		else done();
	}

	function cacheMaterialQuad(handle:String, done:Void->Void) {
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc != null) { done(); return; }

		cc = new CachedShaderContext();
		cachedShaderContexts.set(handle, cc);

		var matPath:Array<String> = null;
		if (handle.charAt(0) == '_') matPath = parseMaterialLink(handle);
		else matPath = handle.split('/');
		
		Data.getMaterial(matPath[0], matPath[1], function(res:MaterialData) {
			cc.materialContext = res.getContext(matPath[2]);
			cc.context = res.shader.getContext(matPath[2]);
			done();
		});
	}

	function cacheShaderQuad(handle:String, done:Void->Void) {
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc != null) { done(); return; }

		cc = new CachedShaderContext();
		cachedShaderContexts.set(handle, cc);

		var shaderPath = handle.split("/");

		Data.getShader(shaderPath[0], shaderPath[1], null, function(res:ShaderData) {
			cc.materialContext = null;
			cc.context = res.getContext(shaderPath[2]);
			done();
		});
	}
}

class CachedShaderContext {
	public var materialContext:MaterialContext;
	public var context:ShaderContext;
	public function new() {}
}
