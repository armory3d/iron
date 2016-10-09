package iron.object;

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
	public var materials:Array<MaterialData>;

	public var particleSystem:ParticleSystem = null;

	var cachedContexts:Map<String, CachedMeshContext> = new Map();
	
	public var cameraDistance:Float;

#if WITH_VELOC
	public var prevMatrix = Mat4.identity();
#end

	public function new(data:MeshData, materials:Array<MaterialData>) {
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

	public function render(g:Graphics, context:String, camera:CameraObject, lamp:LampObject, bindParams:Array<String>) {
		// Skip render if material does not contain current context
		if (materials[0].getContext(context) == null) return;

		// Skip render if object or lamp is hidden
		if (!visible || !lamp.visible) return;

		// Frustum culling
		culled = false;
		if (camera.data.raw.frustum_culling) {
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

		// Get context
		var cc = cachedContexts.get(context);
		if (cc == null) {
			cc = new CachedMeshContext();
			// Check context skip
			for (mat in materials) {
				if (mat.raw.skip_context != null &&
					mat.raw.skip_context == context) {
					cc.enabled = false;
					break;
				}
			}
			if (cc.enabled) {
				cc.materialContexts = [];
				for (mat in materials) {
					for (i in 0...mat.raw.contexts.length) {
						if (mat.raw.contexts[i].name.substr(0, context.length) == context) {
							cc.materialContexts.push(mat.contexts[i]);
							break;
						}
					}
				}
				// TODO: only one shader per mesh
				cc.context = materials[0].shader.getContext(context);
				cachedContexts.set(context, cc);
			}
		}
		if (!cc.enabled) return;
		
		// TODO: move to update
		if (particleSystem != null) particleSystem.update();

		var materialContexts = cc.materialContexts;
		var shaderContext = cc.context;

		transform.update();
		
		// Render mesh
		g.setPipeline(shaderContext.pipeState);
		
		if (data.mesh.instanced) {
			g.setVertexBuffers(data.mesh.instancedVertexBuffers);
		}
		else {
#if WITH_DEINTERLEAVED
			g.setVertexBuffers(data.mesh.vertexBuffers);
#else
			// var shadowsContext = camera.data.pathdata.raw.shadows_context;
			// if (context == shadowsContext) { // Hard-coded for now
				// g.setVertexBuffer(data.mesh.vertexBufferDepth);
			// }
			// else {
				g.setVertexBuffer(data.mesh.vertexBuffer);
			// }
#end
		}

		Uniforms.setConstants(g, shaderContext, this, camera, lamp, bindParams);

		for (i in 0...data.mesh.indexBuffers.length) {
			
			var mi = data.mesh.materialIndices[i];
			if (materialContexts.length > mi) {
				Uniforms.setMaterialConstants(g, shaderContext, materialContexts[mi]);
			}

			g.setIndexBuffer(data.mesh.indexBuffers[i]);

			if (data.mesh.instanced) {
				g.drawIndexedVerticesInstanced(data.mesh.instanceCount);
			}
			else {
				g.drawIndexedVertices();
			}
		}

#if WITH_PROFILE
		RenderPath.drawCalls++;
#end

#if WITH_VELOC
		prevMatrix.loadFrom(transform.matrix);
#end
	}

	public inline function computeCameraDistance(camX:Float, camY:Float, camZ:Float) {
		cameraDistance = iron.math.Vec4.distance3df(camX, camY, camZ, transform.absx(), transform.absy(), transform.absz());
	}
}

class CachedMeshContext {
	public var materialContexts:Array<MaterialContext>;
	public var context:ShaderContext;
	public var enabled = true;
	public function new() {}
}
