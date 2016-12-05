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
	public var cachedContexts:Map<String, CachedMeshContext> = new Map();	
	public var cameraDistance:Float;
	public var screenSize:Float = 0.0;

#if arm_veloc
	public var prevMatrix = Mat4.identity();
#end

	public function new(data:MeshData, materials:Vector<MaterialData>) {
		super();

		this.data = data;
		this.materials = materials;	
		Scene.active.meshes.push(this);
	}

	public override function remove() {
		Scene.active.meshes.remove(this);
		super.remove();
	}

	public override function setupAnimation(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>, maxBones = 50) {
		if (data.isSkinned) {
			animation = Animation.setupBoneAnimation(data, startTrack, names, starts, ends, speeds, loops, reflects, maxBones);
		}
		else {
			super.setupAnimation(startTrack, names, starts, ends, speeds, loops, reflects);
		}
	}

	public function setupParticleSystem(sceneName:String, pref:TParticleReference) {
		particleSystem = new ParticleSystem(this, sceneName, pref);
	}

	inline function isLodMaterial() {
		return (raw.lod_material != null && raw.lod_material == true);
	}

	public function render(g:Graphics, context:String, camera:CameraObject, lamp:LampObject, bindParams:Array<String>) {
		// Skip render if material does not contain current context
		var mats = materials;
		if (!isLodMaterial() && !validContext(mats[0], context)) return;

		// Skip render if object or lamp is hidden
		if (!visible) return;
		if (lamp != null && !lamp.visible) return;

		var meshContext = camera.data.pathdata.raw.mesh_context;
		if (!visibleMesh && context == meshContext) return;
		
		var shadowsContext = camera.data.pathdata.raw.shadows_context;
		if (!visibleShadow && context == shadowsContext) return;

		// Frustum culling
		culled = false;
		if (camera.data.raw.frustum_culling) {
			// Scale radius for skinned mesh and particle system
			// TODO: determine max radius
			var radiusScale = data.isSkinned ? 2.0 : 1.0;
			if (particleSystem != null) radiusScale *= 100;
			if (context == "voxel") radiusScale *= 100;
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
				if (!instanceInFrustum) { culled = true; return; }

				// Sort - always front to back for now
				var camX = camera.transform.absx();
				var camY = camera.transform.absy();
				var camZ = camera.transform.absz();
				data.mesh.sortInstanced(camX, camY, camZ);
			}
			// Non-instanced
			else {
				if (!CameraObject.sphereInFrustum(frustumPlanes, transform, radiusScale)) {
					culled = true;
					return;
				}
			}
		}

		// Get lod
		var lod = this;
		if (raw.lods != null && raw.lods.length > 0) {
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
		var cc = lod.cachedContexts.get(context);
		if (cc == null) {
			cc = new CachedMeshContext();
			// Check context skip
			for (mat in mats) {
				if (mat.raw.skip_context != null &&
					mat.raw.skip_context == context) {
					cc.enabled = false;
					break;
				}
			}
			if (cc.enabled) {
				cc.materialContexts = [];
				for (mat in mats) {
					for (i in 0...mat.raw.contexts.length) {
						if (mat.raw.contexts[i].name.substr(0, context.length) == context) {
							cc.materialContexts.push(mat.contexts[i]);
							break;
						}
					}
				}
				// TODO: only one shader per mesh
				cc.context = mats[0].shader.getContext(context);
				lod.cachedContexts.set(context, cc);
			}
		}
		if (!cc.enabled) return;
		
		// TODO: move to update
		if (lod.particleSystem != null) lod.particleSystem.update();

		var materialContexts = cc.materialContexts;
		var shaderContext = cc.context;

		transform.update();
		
		// Render mesh
		g.setPipeline(shaderContext.pipeState);
		
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

		Uniforms.setConstants(g, shaderContext, this, camera, lamp, bindParams);

		for (i in 0...ldata.mesh.indexBuffers.length) {
			
			var mi = ldata.mesh.materialIndices[i];
			if (materialContexts.length > mi) {
				Uniforms.setMaterialConstants(g, shaderContext, materialContexts[mi]);
			}

			g.setIndexBuffer(ldata.mesh.indexBuffers[i]);

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

class CachedMeshContext {
	public var materialContexts:Array<MaterialContext>;
	public var context:ShaderContext;
	public var enabled = true;
	public function new() {}
}
