package iron;

import kha.Image;
import kha.Color;
import kha.Scheduler;
import kha.graphics4.*;
import iron.math.*;
import iron.object.*;
import iron.data.*;
import iron.data.SceneFormat;
import iron.data.MaterialData;
import iron.data.ShaderData;

class RenderPath {

	public static var active:RenderPath;

	public var frameScissor = false;
	public var frameScissorX = 0;
	public var frameScissorY = 0;
	public var frameScissorW = 0;
	public var frameScissorH = 0;
	public var frameTime = 0.0;
	public var currentTarget:RenderTarget = null;
	public var currentCube:Bool;
	public var currentFace:Int;
	public var currentLampIndex = 0;
	public var currentW:Int;
	public var currentH:Int;
	public var currentD:Int;
	var lastW = 0;
	var lastH = 0;
	var bindParams:Array<String>;
	var meshesSorted:Bool;
	var scissorSet = false;
	var viewportScaled = false;
	var currentG:Graphics;
	var frameG:Graphics;
	var lastFrameTime = 0.0;
	
	public var paused = false;
	public var ready(get, null):Bool;
	function get_ready():Bool { return loading == 0; }
	var loading = 0;
	var cachedShaderContexts:Map<String, CachedShaderContext> = new Map();

	public var commands:Void->Void = null;
	public var renderTargets:Map<String, RenderTarget> = new Map();
	public var depthToRenderTarget:Map<String, RenderTarget> = new Map();

	// Used by render path nodes for branch functions
	public function lampCastShadow() {
		return getLamp(currentLampIndex).data.raw.cast_shadow;
	}

	public function lampIsSun() {
		return getLamp(currentLampIndex).data.raw.type == "sun";
	}

	#if (rp_gi != "Off")
	var voxelized = 0;
	public var onVoxelize:Void->Bool = null;
	public function voxelize() {
		if (onVoxelize != null) return onVoxelize();
		#if arm_voxelgi_revox
		return true;
		#else
		return ++voxelized > 2 ? false : true;
		#end
	}
	#end

	public static function setActive(renderPath:RenderPath) { 
		active = renderPath;
	}

	public function new() {}

	inline public function getLamp(index:Int) { return Scene.active.lamps.length > 0 ? Scene.active.lamps[index] : null; }

	public function renderFrame(g:Graphics) {
		if (!ready || paused || iron.App.w() == 0 || iron.App.h() == 0) return;

		// #if arm_resizable
		if (lastW > 0 && (lastW != iron.App.w() || lastH != iron.App.h())) resize();
		lastW = iron.App.w();
		lastH = iron.App.h();
		// #end

		frameTime = iron.system.Time.time() - lastFrameTime;
		lastFrameTime = iron.system.Time.time();

		#if arm_debug
		drawCalls = 0;
		batchBuckets = 0;
		batchCalls = 0;
		culled = 0;
		numTrisMesh = 0;
		numTrisShadow = 0;
		#end
		
		frameG = Scene.active.camera == null || Scene.active.camera.data.renderTarget == null ? g : Scene.active.camera.data.renderTarget.g4; // Render to screen or camera texture
		currentG = frameG;
		currentW = iron.App.w();
		currentH = iron.App.h();
		currentD = 1;
		currentCube = false;
		currentFace = -1;
		meshesSorted = false;

		currentLampIndex = 0;
		for (l in Scene.active.lamps) if (l.visible) l.buildMatrices(Scene.active.camera);

		commands();
	}

	public function setTarget(target:String, additional:Array<String> = null, viewportScale = 1.0) {
		if (target == "") { // Framebuffer
			currentG = frameG;
			currentW = iron.App.w();
			currentH = iron.App.h();
			currentD = 1;
			currentTarget = null;
			currentCube = false;
			currentFace = -1;
			if (frameScissor) setFrameScissor();
			begin(currentG);
			#if arm_appwh
			setCurrentViewport(iron.App.w(), iron.App.h());
			setCurrentScissor(iron.App.w(), iron.App.h());
			#end
		}
		else { // Render target
			var rt = renderTargets.get(target);
			currentTarget = rt;
			var additionalImages:Array<kha.Canvas> = null;
			if (additional != null) {
				additionalImages = [];
				for (s in additional) {
					var t = renderTargets.get(s);
					additionalImages.push(t.image);
				}
			}
			currentG = rt.isCubeMap ? rt.cubeMap.g4 : rt.image.g4;
			currentW = rt.isCubeMap ? rt.cubeMap.width : rt.image.width;
			currentH = rt.isCubeMap ? rt.cubeMap.height : rt.image.height;
			if (rt.is3D) currentD = rt.image.depth;
			currentCube = rt.isCubeMap;
			begin(currentG, additionalImages, currentFace);
		}
		if (viewportScale != 1.0) {
			viewportScaled = true;
			var viewW = Std.int(currentW * viewportScale);
			var viewH = Std.int(currentH * viewportScale);
			currentG.viewport(0, viewH, viewW, viewH);
			currentG.scissor(0, viewH, viewW, viewH);
		}
		else if (viewportScaled) { // Reset viewport
			viewportScaled = false;
			setCurrentViewport(currentW, currentH);
			setCurrentScissor(currentW, currentH);
		}
		bindParams = null;
	}

	inline function begin(g:Graphics, additionalRenderTargets:Array<kha.Canvas> = null, face = -1) {
		// TODO: draw first cube-face last, otherwise some opengl drivers glitch
		face >= 0 ? g.beginFace(5 - face) : g.begin(additionalRenderTargets);
	}

	inline function end(g:Graphics) {
		g.end();
		if (scissorSet) { g.disableScissor(); scissorSet = false; }
		bindParams = null;
	}

	public function setCurrentViewport(viewW:Int, viewH:Int) {
		currentG.viewport(0, currentH - viewH, viewW, viewH);
	}

	public function setCurrentScissor(viewW:Int, viewH:Int) {
		currentG.scissor(0, currentH - viewH, viewW, viewH);
		scissorSet = true;
	}

	public function setFrameScissor() {
		frameG.scissor(frameScissorX, currentH - (frameScissorH - frameScissorY), frameScissorW, frameScissorH);
	}

	public function setViewport(viewW:Int, viewH:Int) {
		setCurrentViewport(viewW, viewH);
		setCurrentScissor(viewW, viewH);
	}

	public function clearTarget(colorFlag:Null<Int> = null, depthFlag:Null<Float> = null) {
		if (colorFlag == -1) {
			if (Scene.active.world != null) colorFlag = Scene.active.world.raw.background_color;
			else if (Scene.active.camera != null) {
				var cc = Scene.active.camera.data.raw.clear_color;
				if (cc != null) colorFlag = kha.Color.fromFloats(cc[0], cc[1], cc[2]);
			}
		}
		currentG.clear(colorFlag, depthFlag, null);
	}

	public function clearImage(target:String, color:Int) {
		var rt = renderTargets.get(target);
		rt.image.clear(0, 0, 0, rt.image.width, rt.image.height, rt.image.depth, color);
	}

	public function generateMipmaps(target:String) {
		var rt = renderTargets.get(target);
		rt.image.generateMipmaps(1000);
	}

	public static function sortMeshes(meshes:Array<MeshObject>, camera:CameraObject) {
		// if (params[1] == "front_to_back") {
			var camX = camera.transform.worldx();
			var camY = camera.transform.worldy();
			var camZ = camera.transform.worldz();
			for (mesh in meshes) {
				mesh.computeCameraDistance(camX, camY, camZ);
			}
			meshes.sort(function(a, b):Int {
				return a.cameraDistance >= b.cameraDistance ? 1 : -1;
			});
		// }
		// else if (params[1] == "material") {
			// Scene.active.meshes.sort(function(a, b):Int {
				// return a.materials[0].name >= b.materials[0].name ? 1 : -1;
			// });
		// }
	}

	public function drawMeshes(context:String) {
		var lamp = getLamp(currentLampIndex);
		if (lamp != null && !lamp.visible) {
			// Pass draw atleast once to fill geometry buffers
			if (currentLampIndex > 0) return;
		}

		var isShadows = context == shadowsContext;
		if (isShadows) {
			// Disabled shadow casting for this lamp
			if (lamp == null || !lamp.data.raw.cast_shadow) return;
		}
		// Single face attached
		// TODO: draw first cube-face last, otherwise some opengl drivers glitch
		if (currentFace >= 0 && lamp != null) lamp.setCubeFace(5 - currentFace, Scene.active.camera);
		
		var g = currentG;
		var drawn = false;

		#if arm_csm
		if (isShadows && lamp.data.raw.type == "sun") {
			var step = currentH; // Atlas with tiles on x axis
			for (i in 0...LampObject.cascadeCount) {
				lamp.setCascade(Scene.active.camera, i);
				// g.viewport(0, currentH - (i + 1) * step, step, step);
				g.viewport(i * step, 0, step, step);
				submitDraw(context);
			}
			drawn = true;
		}
		#end

		if (!drawn) submitDraw(context);

		#if arm_debug
		// Callbacks to specific context
		if (contextEvents != null) {
			var ar = contextEvents.get(context);
			if (ar != null) for (i in 0...ar.length) ar[i](g, i, ar.length);
		}
		#end

		end(g);
	}

	function submitDraw(context:String) {
		var lamp = getLamp(currentLampIndex);
		var g = currentG;

		#if arm_batch
		Scene.active.meshBatch.render(g, context, Scene.active.camera, lamp, bindParams);
		#else
		if (!meshesSorted && Scene.active.camera != null) { // Order max one per frame for now
			sortMeshes(Scene.active.meshes, Scene.active.camera);
			meshesSorted = true;
		}
		for (m in Scene.active.meshes) {
			m.render(g, context, Scene.active.camera, lamp, bindParams);
		}
		#end
	}

	#if arm_debug
	static var contextEvents:Map<String, Array<Graphics->Int->Int->Void>> = null;
	public static function notifyOnContext(name:String, onContext:Graphics->Int->Int->Void) {
		if (contextEvents == null) contextEvents = new Map();
		var ar = contextEvents.get(name);
		if (ar == null) { ar = []; contextEvents.set(name, ar); }
		ar.push(onContext);
	}
	#end

	function getRectContexts(mat:MaterialData, context:String, materialContexts:Array<MaterialContext>, shaderContexts:Array<ShaderContext>) {
		for (i in 0...mat.raw.contexts.length) {
			if (mat.raw.contexts[i].name.substr(0, context.length) == context) {
				materialContexts.push(mat.contexts[i]);
				shaderContexts.push(mat.shader.getContext(context));
				break;
			}
		}
	}

	inline function clampRect(f:Float):Float { return f < -1.0 ? -1.0 : (f > 1.0 ? 1.0 : f); }

	public var currentMaterial:MaterialData = null; // Temp
	static var helpMat = Mat4.identity();
	public function drawRects(context:String) {
		if (ConstData.rectVB == null) ConstData.createRectData();
		var g = currentG;
		var lamp = getLamp(currentLampIndex);

		// Unique materials
		var mats:Array<MaterialData> = [];
		var volumesMin:Array<Vec4> = [];
		var volumesMax:Array<Vec4> = [];
		for (m in Scene.active.meshes) {
			var found = false;
			for (i in 0...mats.length) {
				var mat = mats[i];
				if (mat == m.materials[0]) {
					var loc = new Vec4(m.transform.worldx(), m.transform.worldy(), m.transform.worldz());
					var dim = m.transform.dim;
					var min = volumesMin[i];
					var max = volumesMax[i];
					if (min.x > loc.x - dim.x / 2.0) min.x = loc.x - dim.x / 2.0;
					if (min.y > loc.y - dim.y / 2.0) min.y = loc.y - dim.y / 2.0;
					if (min.z > loc.z - dim.z / 2.0) min.z = loc.z - dim.z / 2.0;
					if (max.x < loc.x + dim.x / 2.0) max.x = loc.x + dim.x / 2.0;
					if (max.y < loc.y + dim.y / 2.0) max.y = loc.y + dim.y / 2.0;
					if (max.z < loc.z + dim.z / 2.0) max.z = loc.z + dim.z / 2.0;
					found = true;
					break;
				}
			}
			if (found) continue;
			var loc = new Vec4(m.transform.worldx(), m.transform.worldy(), m.transform.worldz());
			var dim = m.transform.dim;
			volumesMin.push(new Vec4(loc.x - dim.x / 2.0, loc.y - dim.y / 2.0, loc.z - dim.z / 2.0));
			volumesMax.push(new Vec4(loc.x + dim.x / 2.0, loc.y + dim.y / 2.0, loc.z + dim.z / 2.0));
			mats.push(m.materials[0]);
		}
		var rectBounds:Array<Vec4> = [];
		for (i in 0...volumesMin.length) {
			var min = volumesMin[i];
			var max = volumesMax[i];
			var dx = max.x - min.x;
			var dy = max.y - min.y;
			var dz = max.z - min.z;
			var ps:Array<Vec4> = [];
			ps.push(new Vec4(min.x, min.y, min.z));
			ps.push(new Vec4(min.x + dx, min.y, min.z));
			ps.push(new Vec4(min.x, min.y + dy, min.z));
			ps.push(new Vec4(min.x, min.y, min.z + dz));
			ps.push(new Vec4(min.x + dx, min.y + dy, min.z));
			ps.push(new Vec4(min.x, min.y + dy, min.z + dz));
			ps.push(new Vec4(min.x + dx, min.y, min.z + dz));
			ps.push(new Vec4(min.x + dx, min.y + dy, min.z + dz));
			helpMat.setFrom(Scene.active.camera.V);
			helpMat.multmat2(Scene.active.camera.P);
			var b:Vec4 = null;
			for (v in ps) {
				v.applymat4(helpMat);
				v.x /= v.w; v.y /= v.w; v.z /= v.w;
				if (b == null) {
					b = new Vec4(v.x, v.y, v.x, v.y);
				}
				else {
					if (v.x < b.x) b.x = v.x; // Min
					if (v.y < b.y) b.y = v.y;
					if (v.x > b.z) b.z = v.x; // Max
					if (v.y > b.w) b.w = v.y;
				}
			}
			rectBounds.push(b);
		}

		g.setIndexBuffer(ConstData.rectIB);
		
		// Screen-space rect per material
		for (i in 0...mats.length) {
			var mat = mats[i];
			var b = rectBounds[i];
			var dx = b.z - b.x;
			var dy = b.w - b.y;
			var v = ConstData.rectVB.lock();
			v.set(0, clampRect(b.x));
			v.set(1, clampRect(b.y));
			v.set(2, clampRect(b.x + dx));
			v.set(3, clampRect(b.y));
			v.set(4, clampRect(b.x + dx));
			v.set(5, clampRect(b.y + dy));
			v.set(6, clampRect(b.x));
			v.set(7, clampRect(b.y + dy));
			ConstData.rectVB.unlock();
			g.setVertexBuffer(ConstData.rectVB);

			currentMaterial = mat;
			var materialContexts:Array<MaterialContext> = [];
			var shaderContexts:Array<ShaderContext> = [];
			getRectContexts(mat, context, materialContexts, shaderContexts);
			
			g.setPipeline(mat.shader.getContext(context).pipeState);
			Uniforms.setConstants(g, shaderContexts[0], null, Scene.active.camera, lamp, bindParams);
			Uniforms.setMaterialConstants(g, shaderContexts[0], materialContexts[0]);
			g.drawIndexedVertices();
		}
		currentMaterial = null;

		end(g);
	}
	
	public function drawDecals(context:String) {
		if (ConstData.boxVB == null) ConstData.createBoxData();
		var g = currentG;
		var lamp = getLamp(currentLampIndex);
		for (decal in Scene.active.decals) {
			decal.render(g, context, Scene.active.camera, lamp, bindParams);
		}
		end(g);
	}

	// static var gpFrame = 0;
	// public function drawGreasePencil(con:String) {
	// 	var gp = Scene.active.greasePencil;
	// 	if (gp == null) return;
	// 	var g = currentG;
	// 	var lamp = getLamp(currentLampIndex);
	// 	var context = GreasePencilData.getContext(con);
	// 	g.setPipeline(context.pipeState);
	// 	Uniforms.setConstants(g, context, null, Scene.active.camera, lamp, null);
	// 	// Draw layers
	// 	for (layer in gp.layers) {
	// 		// Next frame
	// 		if (layer.frames.length - 1 > layer.currentFrame && gpFrame >= layer.frames[layer.currentFrame + 1].raw.frame_number) {
	// 			layer.currentFrame++;
	// 		}
	// 		var frame = layer.frames[layer.currentFrame];
	// 		if (frame.numVertices > 0) {
	// 			// Stroke
	// 			#if (js && kha_webgl && !kha_node && !kha_html5worker)
	// 			// TODO: temporary, construct triangulated lines from points instead
	// 			g.setVertexBuffer(frame.vertexStrokeBuffer);
	// 			kha.SystemImpl.gl.lineWidth(3);
	// 			var start = 0;
	// 			for (i in frame.raw.num_stroke_points) {
	// 				kha.SystemImpl.gl.drawArrays(js.html.webgl.GL.LINE_STRIP, start, i);
	// 				start += i;
	// 			}
	// 			#end
	// 			// Fill
	// 			g.setVertexBuffer(frame.vertexBuffer);
	// 			g.setIndexBuffer(frame.indexBuffer);
	// 			g.drawIndexedVertices();
	// 		}
	// 	}
	// 	gpFrame++;
	// 	// Reset timeline
	// 	if (gpFrame > GreasePencilData.frameEnd) {
	// 		gpFrame = 0;
	// 		for (layer in gp.layers) layer.currentFrame = 0;
	// 	}
	// 	end(g);
	// }

	public function drawSkydome(handle:String) {
		if (ConstData.skydomeVB == null) ConstData.createSkydomeData();
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc.context == null) return; // World data not specified
		var g = currentG;
		g.setPipeline(cc.context.pipeState);
		var lamp = getLamp(currentLampIndex);
		Uniforms.setConstants(g, cc.context, null, Scene.active.camera, lamp, bindParams);
		#if arm_deinterleaved
		g.setVertexBuffers(ConstData.skydomeVB);
		#else
		g.setVertexBuffer(ConstData.skydomeVB);
		#end
		g.setIndexBuffer(ConstData.skydomeIB);
		g.drawIndexedVertices();
		end(g);
	}

	public function drawLampVolume(handle:String) {
		var vb:VertexBuffer = null;
		var ib:IndexBuffer = null;
		var lamp = getLamp(currentLampIndex);
		var type = lamp.data.raw.type;
		if (type == "point" || type == "area") { // Sphere
			if (ConstData.sphereVB == null) ConstData.createSphereData();
			vb = ConstData.sphereVB;
			ib = ConstData.sphereIB;
		}
		else if (type == "spot") { // Oriented cone
			// if (ConstData.coneVB == null) ConstData.createConeData();
			// vb = ConstData.coneVB;
			// ib = ConstData.coneIB;
			if (ConstData.sphereVB == null) ConstData.createSphereData();
			vb = ConstData.sphereVB;
			ib = ConstData.sphereIB;
		}
		
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		var g = currentG;		
		g.setPipeline(cc.context.pipeState);
		Uniforms.setConstants(g, cc.context, null, Scene.active.camera, lamp, bindParams);
		g.setVertexBuffer(vb);
		g.setIndexBuffer(ib);
		g.drawIndexedVertices();
		end(g);
	}

	public function bindTarget(target:String, uniform:String) {
		if (bindParams != null) { bindParams.push(target); bindParams.push(uniform); }
		else bindParams = [target, uniform];
	}
	
	// Full-screen triangle
	public function drawShader(handle:String) {
		// file/data_name/context
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (ConstData.screenAlignedVB == null) ConstData.createScreenAlignedData();
		var g = currentG;		
		g.setPipeline(cc.context.pipeState);
		var lamp = getLamp(currentLampIndex);
		Uniforms.setConstants(g, cc.context, null, Scene.active.camera, lamp, bindParams);
		g.setVertexBuffer(ConstData.screenAlignedVB);
		g.setIndexBuffer(ConstData.screenAlignedIB);
		g.drawIndexedVertices();
		
		end(g);
	}

	public function getComputeShader(handle:String):kha.compute.Shader {
		return Reflect.field(kha.Shaders, handle + "_comp");
	}

	#if arm_vr
	public function drawStereo(drawMeshes:Void->Void) {
		var vr = kha.vr.VrInterface.instance;
		var g = currentG;
		var appw = iron.App.w();
		var apph = iron.App.h();
		var halfw = Std.int(appw / 2);

		if (vr != null && vr.IsPresenting()) {
			// Left eye
			Scene.active.camera.V.setFrom(Scene.active.camera.leftV);
			Scene.active.camera.P.self = vr.GetProjectionMatrix(0);
			g.viewport(0, 0, halfw, apph);
			drawMeshes();

			// Right eye
			Scene.active.camera.V.setFrom(Scene.active.camera.rightV);
			Scene.active.camera.P.self = vr.GetProjectionMatrix(1);
			g.viewport(halfw, 0, halfw, apph);
			drawMeshes();
		}
		else { // Simulate
			// Left eye
			g.viewport(0, 0, halfw, apph);
			drawMeshes();

			// Right eye
			Scene.active.camera.move(Scene.active.camera.right(), 0.032);
			Scene.active.camera.buildMatrix();
			g.viewport(halfw, 0, halfw, apph);
			drawMeshes();

			Scene.active.camera.move(Scene.active.camera.right(), -0.032);
			Scene.active.camera.buildMatrix();
		}
	}
	#end

	public function loadShader(handle:String) {
		loading++;
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc != null) { loading--; return; }

		cc = new CachedShaderContext();
		cachedShaderContexts.set(handle, cc);

		// file/data_name/context
		var shaderPath = handle.split("/");

		#if arm_json
		shaderPath[0] += '.json';
		#end

		Data.getShader(shaderPath[0], shaderPath[1], null, function(res:ShaderData) {
			cc.context = res.getContext(shaderPath[2]);
			loading--;
		});
	}

	public function unload() { for (rt in renderTargets) rt.unload(); }

	public function resize() {
		for (rt in renderTargets) {
			if (rt.raw.width == 0) {
				rt.image.unload();
				rt.image = createImage(rt.raw, rt.depthStencil);
				if (rt.depthStencilFrom != "") {
					rt.image.setDepthStencilFrom(depthToRenderTarget.get(rt.depthStencilFrom).image);
				}
			}
		}
	}
	
	public function createRenderTarget(t:RenderTargetRaw):RenderTarget {
		var rt = createTarget(t);
		renderTargets.set(t.name, rt);
		return rt;
	}

	var depthBuffers:Array<{name:String, format:String}> = [];
	public function createDepthBuffer(name:String, format:String = null) {
		depthBuffers.push({name: name, format: format});
	}

	function createTarget(t:RenderTargetRaw):RenderTarget {
		var rt = new RenderTarget(t);
		// With depth buffer
		if (t.depth_buffer != null) {
			rt.hasDepth = true;
			var depthTarget = depthToRenderTarget.get(t.depth_buffer);
			
			// Create new one
			if (depthTarget == null) {
				for (db in depthBuffers) {
					if (db.name == t.depth_buffer) {
						depthToRenderTarget.set(db.name, rt);
						rt.depthStencil = getDepthStencilFormat(db.format);
						rt.image = createImage(t, rt.depthStencil);
						break;
					}
				}
			}
			// Reuse
			else {
				rt.depthStencil = DepthStencilFormat.NoDepthAndStencil;
				rt.depthStencilFrom = t.depth_buffer;
				rt.image = createImage(t, rt.depthStencil);
				rt.image.setDepthStencilFrom(depthTarget.image);
			}
		}
		// No depth buffer
		else {
			rt.hasDepth = false;
			if (t.depth != null && t.depth > 1) rt.is3D = true;
			if (t.is_cubemap) {
				rt.isCubeMap = true;
				rt.depthStencil = DepthStencilFormat.NoDepthAndStencil;
				rt.cubeMap = createCubeMap(t, rt.depthStencil);
			}
			else {
				rt.depthStencil = DepthStencilFormat.NoDepthAndStencil;
				rt.image = createImage(t, rt.depthStencil);
			}
		}
		
		return rt;
	}

	function createImage(t:RenderTargetRaw, depthStencil:DepthStencilFormat):Image {
		var width = t.width == 0 ? iron.App.w() : t.width;
		var height = t.height == 0 ? iron.App.h() : t.height;
		var depth = t.depth != null ? t.depth : 0;
		if (t.displayp != null) { // 1080p/..
			if (width > height) {
				width = Std.int(width * (t.displayp / height));
				height = t.displayp;
			}
			else {
				height = Std.int(height * (t.displayp / width));
				width = t.displayp;
			}
		}
		if (t.scale != null) {
			width = Std.int(width * t.scale);
			height = Std.int(height * t.scale);
			depth = Std.int(depth * t.scale);
		}
		if (t.depth != null && t.depth > 1) { // 3D texture
			// Image only
			var img = Image.create3D(width, height, depth,
				t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32);
			if (t.mipmaps) img.generateMipmaps(1000); // Allocate mipmaps
			return img;
		}
		else { // 2D texture
			if (t.is_image != null && t.is_image) { // Image
				return Image.create(width, height,
					t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32);
			}
			else { // Render target
				return Image.createRenderTarget(width, height,
					t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32,
					depthStencil);
			}
		}
	}

	function createCubeMap(t:RenderTargetRaw, depthStencil:DepthStencilFormat):CubeMap {
		return CubeMap.createRenderTarget(t.width,
			t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32,
			depthStencil);
	}

	inline function getTextureFormat(s:String):TextureFormat {
		switch (s) {
		case "RGBA32": return TextureFormat.RGBA32;
		case "RGBA64": return TextureFormat.RGBA64;
		case "RGBA128": return TextureFormat.RGBA128;
		case "DEPTH16": return TextureFormat.DEPTH16;
		case "A32": return TextureFormat.A32;
		case "A16": return TextureFormat.A16;
		case "A8": return TextureFormat.L8;
		case "R32": return TextureFormat.A32;
		case "R16": return TextureFormat.A16;
		case "R8": return TextureFormat.L8;
		default: return TextureFormat.RGBA32;
		}
	}
	
	inline function getDepthStencilFormat(s:String):DepthStencilFormat {
		// if (depth && stencil) return DepthStencilFormat.Depth24Stencil8;
		// else if (depth) return DepthStencilFormat.DepthOnly;
		// else return DepthStencilFormat.NoDepthAndStencil; 
		if (s == null || s == "") return DepthStencilFormat.DepthOnly;
		switch (s) {
		case "DEPTH24": return DepthStencilFormat.DepthOnly; // Depth32Stencil8
		case "DEPTH16": return DepthStencilFormat.Depth16;
		default: return DepthStencilFormat.DepthOnly;
		}
	}

	public static inline var meshContext = "mesh";
	public static inline var shadowsContext = "shadowmap";

	#if arm_debug
	public static var drawCalls = 0;
	public static var batchBuckets = 0;
	public static var batchCalls = 0;
	public static var culled = 0;
	public static var numTrisMesh = 0;
	public static var numTrisShadow = 0;
	#end
}

class RenderTargetRaw {
	public var name:String;
	public var width:Int;
	public var height:Int;
	public var format:String = null;
	public var scale:Null<Float> = null;
	public var displayp:Null<Int> = null; // Set to 1080p/...
	public var depth_buffer:String = null; // 2D texture
	public var mipmaps:Null<Bool> = null;
	public var depth:Null<Int> = null; // 3D texture
	public var is_image:Null<Bool> = null; // Image
	public var is_cubemap:Null<Bool> = null; // Cubemap
	public function new() {}
}

class RenderTarget {
	public var raw:RenderTargetRaw;
	public var depthStencil:DepthStencilFormat;
	public var depthStencilFrom = "";
	public var image:Image = null; // RT or image
	public var cubeMap:CubeMap = null;
	public var hasDepth = false;
	public var is3D = false; // sampler2D / sampler3D
	public var isCubeMap = false;
	public function new(raw:RenderTargetRaw) { this.raw = raw; }
	public function unload() {
		if (image != null) image.unload();
		if (cubeMap != null) cubeMap.unload();
	}
}

class CachedShaderContext {
	public var context:ShaderContext;
	public function new() {}
}
