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
import iron.object.MeshObject;
import iron.object.LampObject;
import iron.object.Uniforms;
import iron.math.Vec4;
import iron.math.Mat4;

typedef TStageCommand = Array<String>->Object->Void;

class RenderPath {

	var camera:CameraObject;
	public var data:CameraData;

	var frameRenderTarget:Graphics;
	public var frameScissor = false;
	public var frameScissorX = 0;
	public var frameScissorY = 0;
	public var frameScissorW = 0;
	public var frameScissorH = 0;
	var scissorSet = false;
	var viewportScaled = false;
	var currentRenderTarget:Graphics;
	public var currentRenderTargetW:Int;
	public var currentRenderTargetH:Int;
	public var currentRenderTargetD:Int;
	public var currentRenderTargetCube:Bool;
	public var currentRenderTargetFace:Int;
	var bindParams:Array<String>;
	var helpMat = Mat4.identity();

	static var screenAlignedVB:VertexBuffer = null;
	static var screenAlignedIB:IndexBuffer = null;
	static var rectVB:VertexBuffer = null;
	static var rectIB:IndexBuffer = null;
	static var boxVB:VertexBuffer = null;
	static var boxIB:IndexBuffer = null;
	#if arm_deinterleaved
	static var skydomeVB:Array<VertexBuffer> = null;
	#else
	static var skydomeVB:VertexBuffer = null;
	#end
	static var skydomeIB:IndexBuffer = null;
	static var sphereVB:VertexBuffer = null;
	static var sphereIB:IndexBuffer = null;
	static var coneVB:VertexBuffer = null;
	static var coneIB:IndexBuffer = null;

	var currentStages:Array<TRenderPathStage> = null;
	var currentStageIndex = 0;
	var currentStageIndexOffset = 0;
	
	var meshesSorted:Bool;
	public var ready:Bool;
	
	var lamps:Array<LampObject>;
	public var currentLampIndex = 0;

	// Quad and decals contexts
	var cachedShaderContexts:Map<String, CachedShaderContext> = new Map();
	
#if arm_profile
	public static var drawCalls = 0;
	public static var batchBuckets = 0;
	public static var batchCalls = 0;
	public static var culled = 0;
	public static var numTrisMesh = 0;
	public static var numTrisShadow = 0;
#end

	// Used by render path nodes for branch functions
	@:keep
	public static function lampCastShadow(rp:RenderPath) {
		return rp.getLamp(rp.currentLampIndex).data.raw.cast_shadow;
	}
	@:keep
	public static function lampIsSun(rp:RenderPath) {
		return rp.getLamp(rp.currentLampIndex).data.raw.type == "sun";
	}

	static var voxelized = 0;
	static inline var voxelizeFrame = 2;
	@:keep
	public static function voxelize(rp:RenderPath) {
		#if arm_voxelgi_revox
		// return true;
		voxelized++;
		if (voxelized >= voxelizeFrame) { voxelized = 0; return true; }
		return false;
		#else
		return ++voxelized > 2 ? false : true;
		#end
	}

	public function new(camera:CameraObject) {
		this.camera = camera;
		data = camera.data;
		ready = false;
		loadStageCommands(data.pathdata.raw.stages, function() { ready = true; });
	}

	public function unload() {
		data.pathdata.unload();
	}

	static function createScreenAlignedData() {
		// Quad
		// var data = [-1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0];
		// var indices = [0, 1, 2, 0, 2, 3];
		// Over-sized triangle
		var data = [-1.0, -1.0, 3.0, -1.0, -1.0, 3.0];
		var indices = [0, 1, 2];

		// Mandatory vertex data names and sizes
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

	static function createRectData() {
		// Quad
		var data = [-1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0];
		var indices = [0, 1, 2, 0, 2, 3];

		// Mandatory vertex data names and sizes
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float2);
		rectVB = new VertexBuffer(Std.int(data.length / Std.int(structure.byteSize() / 4)), structure, Usage.StaticUsage);
		var vertices = rectVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		rectVB.unlock();

		rectIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = rectIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		rectIB.unlock();
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
		#if arm_deinterleaved
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		var structLength = Std.int(structure.byteSize() / 4);
		var pos = iron.data.ConstData.skydomePos;
		skydomeVB = [];
		skydomeVB[0] = new VertexBuffer(Std.int(pos.length / 3), structure, Usage.StaticUsage);
		var vertices = skydomeVB[0].lock();
		for (i in 0...Std.int(vertices.length / structLength)) {
			vertices.set(i * structLength, pos[i * 3]);
			vertices.set(i * structLength + 1, pos[i * 3 + 1]);
			vertices.set(i * structLength + 2, pos[i * 3 + 2]);
		}
		skydomeVB[0].unlock();
		structure = new VertexStructure();
		structure.add("nor", VertexData.Float3);
		structLength = Std.int(structure.byteSize() / 4);
		var nor = iron.data.ConstData.skydomeNor;
		skydomeVB[1] = new VertexBuffer(Std.int(pos.length / 3), structure, Usage.StaticUsage);
		var vertices = skydomeVB[1].lock();
		for (i in 0...Std.int(vertices.length / structLength)) {
			vertices.set(i * structLength, -nor[i * 3]); // Flip to match quad
			vertices.set(i * structLength + 1, -nor[i * 3 + 1]);
			vertices.set(i * structLength + 2, -nor[i * 3 + 2]);
		}
		skydomeVB[1].unlock();
		#else
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
		#end
		
		var indices = iron.data.ConstData.skydomeIndices;
		skydomeIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = skydomeIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		skydomeIB.unlock();
	}

	static function createSphereData() {
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		var data = iron.data.ConstData.spherePos;
		sphereVB = new VertexBuffer(Std.int(data.length / Std.int(structure.byteSize() / 4)), structure, Usage.StaticUsage);
		var vertices = sphereVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		sphereVB.unlock();

		var indices = iron.data.ConstData.sphereIndices;
		sphereIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = sphereIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		sphereIB.unlock();
	}

	static function createConeData() {
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		var data = iron.data.ConstData.conePos;
		coneVB = new VertexBuffer(Std.int(data.length / Std.int(structure.byteSize() / 4)), structure, Usage.StaticUsage);
		var vertices = coneVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		coneVB.unlock();

		var indices = iron.data.ConstData.coneIndices;
		coneIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = coneIB.lock();
		for (i in 0...id.length) id[i] = indices[i];
		coneIB.unlock();
	}

	inline function getLamp(index:Int) {
		return lamps.length > 0 ? lamps[index] : null;
	}

	var lastW = 0;
	var lastH = 0;
	public function renderFrame(g:Graphics, root:Object, lamps:Array<LampObject>) {
		if (!ready) return;

// #if arm_resizable
		if (lastW > 0 && (lastW != iron.App.w() || lastH != iron.App.h())) data.pathdata.resize();
		lastW = iron.App.w();
		lastH = iron.App.h();
// #end

#if arm_profile
		drawCalls = 0;
		batchBuckets = 0;
		batchCalls = 0;
		culled = 0;
		numTrisMesh = 0;
		numTrisShadow = 0;
#end
		
		frameRenderTarget = camera.data.mirror == null ? g : camera.data.mirror.g4; // Render to screen or camera texture
		currentRenderTarget = frameRenderTarget;
		currentRenderTargetW = iron.App.w();
		currentRenderTargetH = iron.App.h();
		currentRenderTargetD = 1;
		currentRenderTargetCube = false;
		currentRenderTargetFace = -1;
		meshesSorted = false;

		this.lamps = lamps;
		currentLampIndex = 0;
		for (l in lamps) if (l.visible) l.buildMatrices(camera);

		currentStages = data.pathdata.raw.stages;
		callCurrentStages(root);
	}

	function callCurrentStages(root:Object) {
		var i = 0;
		while (i < currentStages.length) {
			currentStageIndex = i;
			var f = commandToFunction(currentStages[i].command);
			f(currentStages[i].params, root);
			i += 1 + currentStageIndexOffset; // To repeat cubemap faces
			currentStageIndexOffset = 0;
		}
	}

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
			currentRenderTargetCube = false;
			currentRenderTargetFace = -1;
			if (frameScissor) setFrameScissor();
			begin(currentRenderTarget);
			#if arm_appwh
			setCurrentViewport(iron.App.w(), iron.App.h());
			setCurrentScissor(iron.App.w(), iron.App.h());
			#end
		}
		else { // Render target
			var rt = data.pathdata.renderTargets.get(target);
			// TODO: Handle shadowMap target properly
			// Create shadowmap on the fly
			if (target == "shadowMap" && getLamp(currentLampIndex).data.raw.shadowmap_cube) {
				// Switch to cubemap
				rt = data.pathdata.renderTargets.get(target + "Cube");
				if (rt == null) {
					// Cubemap size - assume sm / 2
					var size = Std.int(getLamp(currentLampIndex).data.raw.shadowmap_size / 2);
					var t:TRenderPathTarget = {
						name: target + "Cube",
						width: size,
						height: size,
						format: "DEPTH16",
						is_cubemap: true
					};
					rt = data.pathdata.createRenderTarget(t);
				}
			}
			if (target == "shadowMap" && rt == null) { // Non-cube sm
				var size = getLamp(currentLampIndex).data.raw.shadowmap_size;
				var t:TRenderPathTarget = {
					name: target,
					width: size,
					height: size,
					format: "DEPTH16"
				};
				rt = data.pathdata.createRenderTarget(t);
			}
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
			
			currentRenderTarget = rt.isCubeMap ? rt.cubeMap.g4 : rt.image.g4;
			currentRenderTargetW = rt.isCubeMap ? rt.cubeMap.width : rt.image.width;
			currentRenderTargetH = rt.isCubeMap ? rt.cubeMap.height : rt.image.height;
			if (rt.is3D) currentRenderTargetD = rt.image.depth;
			currentRenderTargetCube = rt.isCubeMap;
			if (currentRenderTargetFace >= 0) currentRenderTargetFace++; // Already drawing to faces
			else currentRenderTargetFace = rt.isCubeMap ? 0 : -1;
			begin(currentRenderTarget, additionalImages, currentRenderTargetFace);
		}
		var viewportScale = Std.parseFloat(params[0]);
		if (viewportScale != 1.0) {
			viewportScaled = true;
			var viewW = Std.int(currentRenderTargetW * viewportScale);
			var viewH = Std.int(currentRenderTargetH * viewportScale);
			currentRenderTarget.viewport(0, viewH, viewW, viewH);
			currentRenderTarget.scissor(0, viewH, viewW, viewH);
		}
		else if (viewportScaled) { // Reset viewport
			viewportScaled = false;
			setCurrentViewport(currentRenderTargetW, currentRenderTargetH);
			setCurrentScissor(currentRenderTargetW, currentRenderTargetH);
		}
		bindParams = null;
	}

	inline function begin(g:Graphics, additionalRenderTargets:Array<kha.Canvas> = null, face = -1) {
		face >= 0 ? g.beginFace(5 - face) : g.begin(additionalRenderTargets); // TODO: draw first cube-face last, otherwise some opengl drivers expose glitch
	}

	inline function end(g:Graphics) {
		g.end();
		if (scissorSet) {
			g.disableScissor();
			scissorSet = false;
		}
		bindParams = null; // Remove, cleared at begin
		drawPerformed = true;
	}

	public function setCurrentViewport(viewW:Int, viewH:Int) {
		currentRenderTarget.viewport(0, currentRenderTargetH - viewH, viewW, viewH);
	}

	public function setCurrentScissor(viewW:Int, viewH:Int) {
		currentRenderTarget.scissor(0, currentRenderTargetH - viewH, viewW, viewH);
		scissorSet = true;
	}

	public function setFrameScissor() {
		frameRenderTarget.scissor(frameScissorX, currentRenderTargetH - (frameScissorH - frameScissorY), frameScissorW, frameScissorH);
	}

	function setViewport(params:Array<String>, root:Object) {
		var viewW = Std.int(Std.parseFloat(params[0]));
		var viewH = Std.int(Std.parseFloat(params[1]));
		setCurrentViewport(viewW, viewH);
		setCurrentScissor(viewW, viewH);
	}

	function clearTarget(params:Array<String>, root:Object) {
		var colorFlag:Null<Int> = null;
		var depthFlag:Null<Float> = null;
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

	function clearImage(params:Array<String>, root:Object) {
		var target = params[0];
		var color = Color.fromString(params[1]);
		var rt = data.pathdata.renderTargets.get(target);
		rt.image.clear(0, 0, 0, rt.image.width, rt.image.height, rt.image.depth, color);
	}

	function generateMipmaps(params:Array<String>, root:Object) {
		var target = params[0];
		var rt = data.pathdata.renderTargets.get(target);
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

	function drawMeshes(params:Array<String>, root:Object) {
		var context = params[0];
		var lamp = getLamp(currentLampIndex);
		if (lamp != null && !lamp.visible) {
			// Pass draw atleast once to fill geometry buffers
			if (currentLampIndex > 0) return;
		}

		// Disabled shadow casting for this lamp
		if (context == data.pathdata.raw.shadows_context) {
			if (lamp == null || !lamp.data.raw.cast_shadow) return;
		}
		// Single face attached
		if (currentRenderTargetFace >= 0 && lamp != null) lamp.setCubeFace(5 - currentRenderTargetFace, camera); // TODO: draw first cube-face last, otherwise some opengl drivers expose glitch

		var g = currentRenderTarget;
#if arm_batch
		Scene.active.meshBatch.render(g, context, camera, lamp, bindParams);
#else

		if (!meshesSorted) { // Order max one per frame for now
			sortMeshes(Scene.active.meshes, camera);
			meshesSorted = true;
		}

		for (m in Scene.active.meshes) {
			m.render(g, context, camera, lamp, bindParams);
		}
#end
		end(g);

		// TODO: render all cubemap faces
		if (currentRenderTargetFace >= 0 && currentRenderTargetFace < 5) {
			currentStageIndexOffset = -3; // Move back draw meshes and clear, back to set target
		}
		else {
			currentRenderTargetFace = -1;
			// lamp.buildMatrices(camera); // Restore light matrix
		}
	}

	function getRectContexts(mat:MaterialData, context:String, materialContexts:Array<MaterialContext>, shaderContexts:Array<ShaderContext>) {
		for (i in 0...mat.raw.contexts.length) {
			if (mat.raw.contexts[i].name.substr(0, context.length) == context) {
				materialContexts.push(mat.contexts[i]);
				shaderContexts.push(mat.shader.getContext(context));
				break;
			}
		}
	}

	inline function clampRect(f:Float):Float {
		return f < -1.0 ? -1.0 : (f > 1.0 ? 1.0 : f);
	}

	public var currentMaterial:MaterialData = null; // Temp
	function drawRects(params:Array<String>, root:Object) {
		if (rectVB == null) createRectData();
		var g = currentRenderTarget;
		var context = params[0];
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
					var dim = m.transform.size;
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
			var dim = m.transform.size;
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
			helpMat.setFrom(camera.V);
			helpMat.multmat2(camera.P);
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

		g.setIndexBuffer(rectIB);
		
		// Screen-space rect per material
		for (i in 0...mats.length) {
			var mat = mats[i];
			var b = rectBounds[i];
			var dx = b.z - b.x;
			var dy = b.w - b.y;
			var v = rectVB.lock();
			v.set(0, clampRect(b.x));
			v.set(1, clampRect(b.y));
			v.set(2, clampRect(b.x + dx));
			v.set(3, clampRect(b.y));
			v.set(4, clampRect(b.x + dx));
			v.set(5, clampRect(b.y + dy));
			v.set(6, clampRect(b.x));
			v.set(7, clampRect(b.y + dy));
			rectVB.unlock();
			g.setVertexBuffer(rectVB);

			currentMaterial = mat;
			var materialContexts:Array<MaterialContext> = [];
			var shaderContexts:Array<ShaderContext> = [];
			getRectContexts(mat, context, materialContexts, shaderContexts);
			
			g.setPipeline(mat.shader.getContext(context).pipeState);
			Uniforms.setConstants(g, shaderContexts[0], null, camera, lamp, bindParams);
			Uniforms.setMaterialConstants(g, shaderContexts[0], materialContexts[0]);
			g.drawIndexedVertices();
		}
		currentMaterial = null;

		end(g);
	}
	
	function drawDecals(params:Array<String>, root:Object) {
		if (boxVB == null) createBoxData();
		var context = params[0];
		var g = currentRenderTarget;
		var lamp = getLamp(currentLampIndex);
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
		var lamp = getLamp(currentLampIndex);
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
				// Stroke
#if (js && kha_webgl && !kha_node && !kha_html5worker)
				// TODO: temporary, construct triangulated lines from points instead
				g.setVertexBuffer(frame.vertexStrokeBuffer);
				kha.SystemImpl.gl.lineWidth(3);
				var start = 0;
				for (i in frame.raw.num_stroke_points) {
					kha.SystemImpl.gl.drawArrays(js.html.webgl.GL.LINE_STRIP, start, i);
					start += i;
				}
#end
				// Fill
				g.setVertexBuffer(frame.vertexBuffer);
				g.setIndexBuffer(frame.indexBuffer);
				g.drawIndexedVertices();
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
		if (handle == '_worldMaterial' && Scene.active.world != null) return Scene.active.world.raw.material_ref.split('/');
		return null;
	}

	function drawSkydome(params:Array<String>, root:Object) {
		if (skydomeVB == null) createSkydomeData();
		var handle = params[0];
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		if (cc.context == null) return; // World data not specified
		var g = currentRenderTarget;
		g.setPipeline(cc.context.pipeState);
		var lamp = getLamp(currentLampIndex);
		Uniforms.setConstants(g, cc.context, null, camera, lamp, bindParams);
		if (cc.materialContext != null) {
			Uniforms.setMaterialConstants(g, cc.context, cc.materialContext);
		}
		#if arm_deinterleaved
		g.setVertexBuffers(skydomeVB);
		#else
		g.setVertexBuffer(skydomeVB);
		#end
		g.setIndexBuffer(skydomeIB);
		g.drawIndexedVertices();
		end(g);
	}

	function drawLampVolume(params:Array<String>, root:Object) {
		var vb:VertexBuffer = null;
		var ib:IndexBuffer = null;
		var lamp = getLamp(currentLampIndex);
		var type = lamp.data.raw.type;
		// if (type == "sun") { // Draw fs quad
			// if (boxVB == null) createBoxData();
			// vb = boxVB;
			// ib = boxIB;
		// }
		/*else*/ if (type == "point" || type == "area") { // Sphere
			if (sphereVB == null) createSphereData();
			vb = sphereVB;
			ib = sphereIB;
		}
		else if (type == "spot") { // Oriented cone
			// if (coneVB == null) createConeData();
			// vb = coneVB;
			// ib = coneIB;
			if (sphereVB == null) createSphereData();
			vb = sphereVB;
			ib = sphereIB;
		}
		
		var handle = params[0];
		var cc:CachedShaderContext = cachedShaderContexts.get(handle);
		var g = currentRenderTarget;		
		g.setPipeline(cc.context.pipeState);
		Uniforms.setConstants(g, cc.context, null, camera, lamp, bindParams);
		if (cc.materialContext != null) {
			Uniforms.setMaterialConstants(g, cc.context, cc.materialContext);
		}
		g.setVertexBuffer(vb);
		g.setIndexBuffer(ib);
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
		if (screenAlignedVB == null) createScreenAlignedData();
		var g = currentRenderTarget;		
		g.setPipeline(cc.context.pipeState);
		var lamp = getLamp(currentLampIndex);

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
		var path = params[0];
		var dotIndex = path.lastIndexOf(".");
		var classPath = path.substr(0, dotIndex);
		var classType = Type.resolveClass(classPath);
		var funName = path.substr(dotIndex + 1);
		var stage = currentStages[currentStageIndex];
		// Call function
		if (stage.returns_true == null && stage.returns_false == null) {
			Reflect.callMethod(classType, Reflect.field(classType, funName), [this]);
		}
		// Branch function
		else {
			var result:Bool = Reflect.callMethod(classType, Reflect.field(classType, funName), [this]);
			// Nested commands
			var nestedStages = result ? stage.returns_true : stage.returns_false;
			if (nestedStages != null) { // Null when only single branch is populated with commands
				var parentStages = currentStages;
				currentStages = nestedStages;
				callCurrentStages(root);
				currentStages = parentStages;
			}
		}
	}
	
	function loopLamps(params:Array<String>, root:Object) {
		var nestedStages = currentStages[currentStageIndex].returns_true;
		var parentStages = currentStages;
		currentStages = nestedStages;
		currentLampIndex = 0;
		loopFinished++;

		for (i in 0...lamps.length) {
			var l = lamps[i];
			if (!l.visible) continue;
			currentLampIndex = i;
			callCurrentStages(root);
		}

		currentLampIndex = 0;
		loopFinished--;
		currentStages = parentStages;
	}

#if arm_vr
	function drawStereo(params:Array<String>, root:Object) {
		var nestedStages = currentStages[currentStageIndex].returns_true;
		var parentStages = currentStages;
		currentStages = nestedStages;

		loopFinished++;
		var g = currentRenderTarget;

		var vr = kha.vr.VrInterface.instance;
		if (vr != null && vr.IsPresenting()) {
			var appw = iron.App.w();
			var apph = iron.App.h();
			var halfw = Std.int(appw / 2);

			// Left eye
			camera.V.setFrom(camera.leftV);
			camera.P.self = vr.GetProjectionMatrix(0);
			g.viewport(0, 0, halfw, apph);
			callCurrentStages(root);

			// Right eye
			camera.V.setFrom(camera.rightV);
			camera.P.self = vr.GetProjectionMatrix(1);
			g.viewport(halfw, 0, halfw, apph);
			callCurrentStages(root);
		}
		else {
			callCurrentStages(root);
			// Emulate
			// var appw = iron.App.w();
			// var apph = iron.App.h();
			// var halfw = Std.int(appw / 2);
			// 	// Left eye
			// 	g.viewport(0, 0, halfw, apph);
			// 	callCurrentStages(root);

			// 	// Right eye
			// 	camera.move(camera.right(), 0.032);
			// 	camera.buildMatrix();
			// 	g.viewport(halfw, 0, halfw, apph);
			// 	callCurrentStages(root);

			// 	camera.move(camera.right(), -0.032);
			// 	camera.buildMatrix();
		}

		loopFinished--;
		currentStages = parentStages;
	}
#end

	function loadStageCommands(stages:Array<TRenderPathStage>, done:Void->Void) {
		var stagesLoaded = 0;
		for (i in 0...stages.length) {
			loadCommand(stages[i], function() {				
				stagesLoaded++;
				if (stagesLoaded == stages.length) done();
			});
		}
	}
	
	function commandToFunction(command:String):TStageCommand {
		return switch (command) {
			case "set_target": setTarget;
			case "set_viewport": setViewport;
			case "clear_target": clearTarget;
			case "clear_image": clearImage;
			case "generate_mipmaps": generateMipmaps;
			case "draw_meshes": drawMeshes;
			case "draw_rects": drawRects; // Screen-space rectangle enclosing mesh bounds
			case "draw_decals": drawDecals;
			case "draw_skydome": drawSkydome;
			case "draw_lamp_volume": drawLampVolume;
			case "bind_target": bindTarget;
			case "draw_shader_quad": drawShaderQuad;
			case "draw_material_quad": drawMaterialQuad;
			case "draw_grease_pencil": drawGreasePencil;
			case "call_function": callFunction;
			case "loop_lamps": loopLamps;
#if arm_vr
			case "draw_stereo": drawStereo;
#end
			default: null;
		}
	}

	function loadCommand(stage:TRenderPathStage, done:Void->Void) {
		var handle = stage.params.length > 0 ? stage.params[0] : '';
		switch (stage.command) {
			case "draw_skydome": cacheMaterialQuad(handle, done);
			case "draw_lamp_volume": cacheShaderQuad(handle, done);
			case "draw_shader_quad": cacheShaderQuad(handle, done);
			case "draw_material_quad": cacheMaterialQuad(handle, done);
			case "call_function": cacheReturnsBoth(stage, done);
			case "loop_lamps": cacheReturnsTrue(stage, done);
#if arm_vr
			case "draw_stereo": cacheReturnsTrue(stage, done);
#end
			default: done();
		}
	}

	function cacheReturnsBoth(stage:TRenderPathStage, done:Void->Void) {
		var cached = 0;
		var cacheTo = 0;
		if (stage.returns_true != null && stage.returns_true.length > 0) cacheTo++;
		if (stage.returns_false != null && stage.returns_false.length > 0) cacheTo++;
		if (cacheTo == 0) done();

		if (stage.returns_true != null && stage.returns_true.length > 0) {
			loadStageCommands(stage.returns_true, function() { cached++; if (cached == cacheTo) done(); });
		}

		if (stage.returns_false != null && stage.returns_false.length > 0) {
			loadStageCommands(stage.returns_false, function() { cached++; if (cached == cacheTo) done(); });
		}

	}

	function cacheReturnsTrue(stage:TRenderPathStage, done:Void->Void) {
		if (stage.returns_true != null) {
			loadStageCommands(stage.returns_true, done);
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
		if (matPath == null) { done(); return; } // World material not specified

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
