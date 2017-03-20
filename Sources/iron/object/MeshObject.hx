package iron.object;

import haxe.ds.Vector;
import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import iron.Scene;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Mat4;
import iron.data.MeshBatch;
import iron.data.MeshData;
import iron.data.LampData;
import iron.data.MaterialData;
import iron.data.ShaderData;
import iron.data.SceneFormat;
import iron.data.RenderPath;

class MeshObject extends Object {

	public var data:MeshData;
	public var materials:Vector<MaterialData>;
	public var particleSystem:ParticleSystem = null;
	public var cameraDistance:Float;
	public var screenSize:Float = 0.0;
	public var frustumCulling = true;

#if arm_veloc
	public var prevMatrix = Mat4.identity();
#end

	public function new(data:MeshData, materials:Vector<MaterialData>) {
		super();

		this.data = data;
		this.materials = materials;	
		Scene.active.meshes.push(this);

		var makeBuffers = true;
#if arm_batch
		if (MeshBatch.isBatchable(this)) makeBuffers = false; // Batch data instead
		Scene.active.meshBatch.addMesh(this);
#end
		if (makeBuffers) data.mesh.build();
	}

	public override function remove() {
#if arm_batch
		Scene.active.meshBatch.removeMesh(this);
#end
		Scene.active.meshes.remove(this);
		super.remove();
	}

	public override function setupAnimation(setup:TAnimationSetup) {
		if (data.isSkinned) {
			animation = Animation.setupBoneAnimation(data, setup);
		}
		else {
			super.setupAnimation(setup);
		}
	}

	public function setupParticleSystem(sceneName:String, pref:TParticleReference) {
		particleSystem = new ParticleSystem(this, sceneName, pref);
	}

	inline function isLodMaterial() {
		return (raw != null && raw.lod_material != null && raw.lod_material == true);
	}

	public function cullMaterial(context:String, camera:CameraObject):Bool {
		// Skip render if material does not contain current context
		var mats = materials;
		if (!isLodMaterial() && !validContext(mats[0], context)) { culled = true; return culled; }

		var shadowsContext = camera.data.pathdata.raw.shadows_context;
		if (!visibleMesh && context != shadowsContext) { culled = true; return culled; }
		if (!visibleShadow && context == shadowsContext) { culled = true; return culled; }

		// Check context skip
		if (skipContext(context)) { culled = true; return culled; }

		culled = false; return culled;
	}

	function cullMesh(context:String, camera:CameraObject, lamp:LampObject):Bool {

		if (camera.data.raw.frustum_culling && frustumCulling) {
			// Scale radius for skinned mesh and particle system
			// TODO: determine max radius
			var radiusScale = data.isSkinned ? 2.0 : 1.0;
			if (particleSystem != null) radiusScale *= 100;
			if (context == "voxel") radiusScale *= 100;
			var shadowsContext = camera.data.pathdata.raw.shadows_context;
			var frustumPlanes = context == shadowsContext ? lamp.frustumPlanes : camera.frustumPlanes;

			// Instanced
			if (data.mesh.instanced) {
				// Cull
				// TODO: per-instance culling
				var instanceInFrustum = false;
				for (v in data.mesh.offsetVecs) {
					if (CameraObject.sphereInFrustum(frustumPlanes, transform, radiusScale, v.x, v.y, v.z)) {
						instanceInFrustum = true;
						break;
					}
				}
				if (!instanceInFrustum) { culled = true; return culled; }

				// Sort - always front to back for now
				var camX = camera.transform.absx();
				var camY = camera.transform.absy();
				var camZ = camera.transform.absz();
				data.mesh.sortInstanced(camX, camY, camZ);
			}
			// Non-instanced
			else {
				if (!CameraObject.sphereInFrustum(frustumPlanes, transform, radiusScale)) {
					culled = true; return culled;
				}
			}
		}

		culled = false; return culled;
	}

	function skipContext(context:String):Bool {
		for (mat in materials) {
			if (mat.raw.skip_context != null &&
				mat.raw.skip_context == context) {
				return true;
			}
		}
		return false;
	}

	function getContexts(context:String, materialContexts:Array<MaterialContext>, shaderContexts:Array<ShaderContext>) {
		for (mat in materials) {
			for (i in 0...mat.raw.contexts.length) {
				if (mat.raw.contexts[i].name.substr(0, context.length) == context) {
					materialContexts.push(mat.contexts[i]);
					shaderContexts.push(mat.shader.getContext(context));
					break;
				}
			}
		}
	}

	public function render(g:Graphics, context:String, camera:CameraObject, lamp:LampObject, bindParams:Array<String>) {

		if (!visible) return; // Skip render if object is hidden
		if (cullMaterial(context, camera)) return;
		if (cullMesh(context, camera, lamp)) return;

		var mats = materials;

		// Get lod
		var lod = this;
		if (raw != null && raw.lods != null && raw.lods.length > 0) {
			computeScreenSize(camera);
			initLods();
			// Select lod
			for (i in 0...raw.lods.length) {
				// Lod found
				if (screenSize > raw.lods[i].screen_size) break;
				lod = cast lods[i];
				if (isLodMaterial()) mats = lod.materials;
			}
			if (lod == null) return; // Empty object
		}
		if (isLodMaterial() && !validContext(mats[0], context)) return;
		
		// Get context
		var materialContexts:Array<MaterialContext> = [];
		var shaderContexts:Array<ShaderContext> = [];
		getContexts(context, materialContexts, shaderContexts);
		
		// TODO: move to update
		if (lod.particleSystem != null) lod.particleSystem.update();

		transform.update();
		
		// Render mesh
		var ldata = lod.data;
		if (ldata.mesh.instanced) {
			g.setVertexBuffers(ldata.mesh.instancedVertexBuffers);
		}
		else {
	#if arm_deinterleaved
			g.setVertexBuffers(ldata.mesh.vertexBuffers);
	#else
			// var shadowsContext = camera.data.pathdata.raw.shadows_context;
			// if (context == shadowsContext) { // Hard-coded for now
				// g.setVertexBuffer(ldata.mesh.vertexBufferDepth);
			// }
			// else {
				g.setVertexBuffer(ldata.mesh.vertexBuffer);
			// }
	#end
		}

		for (i in 0...ldata.mesh.indexBuffers.length) {

			var mi = ldata.mesh.materialIndices[i];
			if (shaderContexts.length <= mi) continue; 

			g.setIndexBuffer(ldata.mesh.indexBuffers[i]);
			g.setPipeline(shaderContexts[mi].pipeState);

			Uniforms.setConstants(g, shaderContexts[mi], this, camera, lamp, bindParams);

			if (materialContexts.length > mi) {
				Uniforms.setMaterialConstants(g, shaderContexts[mi], materialContexts[mi]);
			}

			if (ldata.mesh.instanced) {
				g.drawIndexedVerticesInstanced(ldata.mesh.instanceCount);
			}
			else {
				g.drawIndexedVertices();
			}
		}

#if arm_profile
		RenderPath.drawCalls++;
#end

#if arm_veloc
		prevMatrix.setFrom(transform.matrix);
#end

		// Mesh-only groups for now
		if (group != null) {
			for (o in group) {
				if (Std.is(o, MeshObject)) {
					o.transform.appendMatrix(transform.matrix);
					o.transform.buildMatrix();
					cast(o, MeshObject).render(g, context, camera, lamp, bindParams);
					o.transform.popAppendMatrix();
					o.transform.buildMatrix();
				}
			}
		}
	}

	public function renderBatch(g:Graphics, context:String, camera:CameraObject, lamp:LampObject, bindParams:Array<String>, start = 0, count = -1) {
		
		if (!visible) return; // Skip render if object is hidden
		if (cullMesh(context, camera, lamp)) return;

		// Get lod
		var lod = this;
		
		// Get context
		var materialContexts:Array<MaterialContext> = [];
		var shaderContexts:Array<ShaderContext> = [];
		getContexts(context, materialContexts, shaderContexts);
		
		// TODO: move to update
		if (lod.particleSystem != null) lod.particleSystem.update();
		transform.update();
		
		// Render mesh
		Uniforms.setConstants(g, shaderContexts[0], this, camera, lamp, bindParams);
		Uniforms.setMaterialConstants(g, shaderContexts[0], materialContexts[0]);

		g.drawIndexedVertices(start, count);

#if arm_profile
		RenderPath.drawCalls++;
#end

#if arm_veloc
		prevMatrix.setFrom(transform.matrix);
#end
	}

	inline function validContext(mat:MaterialData, context:String):Bool {
		 return mat.getContext(context) != null;
	}

	public inline function computeCameraDistance(camX:Float, camY:Float, camZ:Float) {
		// Render path mesh sorting
		cameraDistance = iron.math.Vec4.distance3df(camX, camY, camZ, transform.absx(), transform.absy(), transform.absz());
	}

	public inline function computeScreenSize(camera:CameraObject) {
		// Approx..
		// var rp = camera.renderPath;
		// var screenVolume = rp.currentRenderTargetW * rp.currentRenderTargetH;
		var tr = transform;
		var volume = tr.size.x * tr.scale.x * tr.size.y * tr.scale.y * tr.size.z * tr.scale.z;
		screenSize = volume * (1.0 / cameraDistance);
		screenSize = screenSize > 1.0 ? 1.0 : screenSize;
	}

	inline function initLods() {
		if (lods == null) {
			lods = [];
			for (l in raw.lods) {
				if (l.object_ref == "") lods.push(null); // Empty
				else lods.push(Scene.active.getChild(l.object_ref));
			}
		}
	}
}
