package iron.object;

import haxe.ds.Vector;
import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import iron.Scene;
import iron.RenderPath;
import iron.math.*;
import iron.data.*;
import iron.data.MaterialData;
import iron.data.ShaderData;
import iron.data.SceneFormat;

class MeshObject extends Object {

	public var data:MeshData = null;
	public var materials:Vector<MaterialData>;
	public var particleSystems:Array<ParticleSystem> = null; // Particle owner
	public var particleChildren:Array<MeshObject> = null;
	public var particleOwner:MeshObject = null; // Particle object
	public var particleIndex = -1;
	public var cameraDistance:Float;
	public var screenSize = 0.0;
	public var frustumCulling = true;
	public var tilesheet:Tilesheet = null;

	#if arm_veloc
	public var prevMatrix = Mat4.identity();
	#end

	public function new(data:MeshData, materials:Vector<MaterialData>) {
		super();

		this.materials = materials;	
		setData(data);
		Scene.active.meshes.push(this);
	}

	public function setData(data:MeshData) {
		this.data = data;
		data.refcount++;

		var makeBuffers = true;
		#if arm_batch
		if (MeshBatch.isBatchable(this)) makeBuffers = false; // Batch data instead
		Scene.active.meshBatch.addMesh(this);
		#end
		if (makeBuffers) data.geom.build();
	}

	public override function remove() {
		#if arm_batch
		Scene.active.meshBatch.removeMesh(this);
		#end
		if (particleSystems != null) {
			for (psys in particleSystems) psys.remove();
			particleSystems = null;
		}
		if (tilesheet != null) tilesheet.remove();
		if (Scene.active != null) Scene.active.meshes.remove(this);
		data.refcount--;
		super.remove();
	}

	public override function setupAnimation(oactions:Array<TSceneFormat> = null) {
		var hasAction = parent != null && parent.raw != null && parent.raw.bone_actions != null;
		if (hasAction) {
			var armatureName = parent.name;
			for (a in Scene.active.animations) if (a.armature != null && a.armature.name == armatureName) { animation = a; break; }
			if (animation == null) animation = new BoneAnimation(armatureName);

			var banimation = cast(animation, BoneAnimation);
			if (data.isSkinned) banimation.setSkin(this);
			// This object is parented to bone
			// TODO: allow non-mesh object to be parented to bone
			else if (raw.parent_bone != null) banimation.addBoneChild(raw.parent_bone, this);
		}
		super.setupAnimation(oactions);
	}

	public function setupParticleSystem(sceneName:String, pref:TParticleReference) {
		if (particleSystems == null) particleSystems = [];
		var psys = new ParticleSystem(sceneName, pref);
		particleSystems.push(psys);
	}

	public function setupTilesheet(sceneName:String, tilesheet_ref:String, tilesheet_action_ref:String) {
		tilesheet = new Tilesheet(sceneName, tilesheet_ref, tilesheet_action_ref);
	}

	inline function isLodMaterial() {
		return (raw != null && raw.lod_material != null && raw.lod_material == true);
	}

	function setCulled(shadowsContext:Bool, b:Bool):Bool {
		shadowsContext ? culledShadow = b : culledMesh = b;
		culled = culledMesh && culledShadow;
		#if arm_debug
		if (b) RenderPath.culled++;
		#end
		return b;
	}

	public function cullMaterial(context:String, camera:CameraObject):Bool {
		// Skip render if material does not contain current context
		var mats = materials;
		if (!isLodMaterial() && !validContext(mats[0], context)) return true;

		var shadowsContext = context == RenderPath.shadowsContext;
		if (!visibleMesh && !shadowsContext) return setCulled(shadowsContext, true);
		if (!visibleShadow && shadowsContext) return setCulled(shadowsContext, true);

		// Check context skip
		if (skipContext(context)) return setCulled(shadowsContext, true);

		return setCulled(shadowsContext, false);
	}

	function cullMesh(context:String, camera:CameraObject, lamp:LampObject):Bool {

		if (camera.data.raw.frustum_culling && frustumCulling) {
			// Scale radius for skinned mesh and particle system
			// TODO: define skin & particle bounds
			var radiusScale = data.isSkinned ? 2.0 : 1.0;
			// particleSystems for update, particleOwner for render
			if (particleSystems != null || particleOwner != null) radiusScale *= 1000;
			if (context == "voxel") radiusScale *= 100;
			var shadowsContext = context == RenderPath.shadowsContext;
			var frustumPlanes = shadowsContext ? lamp.frustumPlanes : camera.frustumPlanes;

			if (shadowsContext && lamp.data.raw.type != "sun") { // Non-sun lamp bounds intersect camera frustum
				lamp.transform.radius = lamp.data.raw.far_plane;
				if (!CameraObject.sphereInFrustum(camera.frustumPlanes, lamp.transform)) {
					return setCulled(shadowsContext, true);
				}
			}

			// Instanced
			if (data.geom.instanced) {
				// Cull
				// TODO: per-instance culling
				var instanceInFrustum = false;
				for (v in data.geom.offsetVecs) {
					if (CameraObject.sphereInFrustum(frustumPlanes, transform, radiusScale, v.x, v.y, v.z)) {
						instanceInFrustum = true;
						break;
					}
				}
				if (!instanceInFrustum) return setCulled(shadowsContext, true);

				// Sort - always front to back for now
				// var camX = camera.transform.worldx();
				// var camY = camera.transform.worldy();
				// var camZ = camera.transform.worldz();
				// data.geom.sortInstanced(camX, camY, camZ); // TODO: do not sort particles here
			}
			// Non-instanced
			else {
				if (!CameraObject.sphereInFrustum(frustumPlanes, transform, radiusScale)) {
					return setCulled(shadowsContext, true);
				}
			}
		}

		culled = false;
		return culled;
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

	function getContexts(context:String, materials:Vector<MaterialData>, materialContexts:Array<MaterialContext>, shaderContexts:Array<ShaderContext>) {
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

		if (data == null || !data.geom.ready) return; // Data not yet streamed
		if (!visible) return; // Skip render if object is hidden
		if (cullMesh(context, camera, lamp)) return;
		if (raw != null && raw.is_particle && particleOwner == null) return; // Instancing not yet set-up by particle system owner
		var meshContext = raw != null ? RenderPath.meshContext == context : false;
		if (particleSystems != null && meshContext) {
			// TODO: all particles have to be added prior to render being called
			if (particleChildren == null) {
				particleChildren = [];
				for (psys in particleSystems) {
					var c = cast iron.Scene.active.getChild(psys.data.raw.dupli_object);
					particleChildren.push(c);
					if (c != null) {
						c.particleOwner = this;
						c.particleIndex = particleChildren.length - 1;
						c.transform = this.transform;
					}
				}
			}
			for (i in 0...particleSystems.length) particleSystems[i].update(particleChildren[i], this);
		}
		if (tilesheet != null) tilesheet.update();
		if (cullMaterial(context, camera)) return;

		// Get lod
		var mats = materials;
		var lod = this;
		if (raw != null && raw.lods != null && raw.lods.length > 0) {
			computeScreenSize(camera);
			initLods();
			if (context == "voxel") {
				// Voxelize using the lowest lod
				lod = cast lods[lods.length - 1];
			}
			else {
				// Select lod
				for (i in 0...raw.lods.length) {
					// Lod found
					if (screenSize > raw.lods[i].screen_size) break;
					lod = cast lods[i];
					if (isLodMaterial()) mats = lod.materials;
				}
			}
			if (lod == null) return; // Empty object
		}
		#if arm_debug
		else computeScreenSize(camera);
		#end
		if (isLodMaterial() && !validContext(mats[0], context)) return;
		
		// Get context
		var materialContexts:Array<MaterialContext> = [];
		var shaderContexts:Array<ShaderContext> = [];
		getContexts(context, mats, materialContexts, shaderContexts);
		
		transform.update();
		
		// Render mesh
		var ldata = lod.data;
		#if !arm_deinterleaved
		if (ldata.geom.instanced) {
			g.setVertexBuffers([ldata.geom.vertexBuffer, ldata.geom.instancedVB]);
		}
		else {
			g.setVertexBuffer(ldata.geom.vertexBuffer);
		}
		#end

		for (i in 0...ldata.geom.indexBuffers.length) {

			var mi = ldata.geom.materialIndices[i];
			if (shaderContexts.length <= mi) continue; 

			#if arm_deinterleaved
			g.setVertexBuffers(ldata.geom.getVertexBuffers(shaderContexts[mi].raw.vertex_structure));
			#end

			g.setIndexBuffer(ldata.geom.indexBuffers[i]);
			g.setPipeline(shaderContexts[mi].pipeState);

			Uniforms.setConstants(g, shaderContexts[mi], this, camera, lamp, bindParams);

			if (materialContexts.length > mi) {
				Uniforms.setMaterialConstants(g, shaderContexts[mi], materialContexts[mi]);
			}

			if (ldata.geom.instanced) {
				g.drawIndexedVerticesInstanced(ldata.geom.instanceCount);
			}
			else {
				g.drawIndexedVertices();
			}
		}

		#if arm_debug
		var shadowsContext = RenderPath.shadowsContext == context;
		if (meshContext) RenderPath.numTrisMesh += ldata.geom.numTris;
		else if (shadowsContext) RenderPath.numTrisShadow += ldata.geom.numTris;
		RenderPath.drawCalls++;
		#end

		#if arm_veloc
		prevMatrix.setFrom(transform.world);
		#end
	}

	public function renderBatch(g:Graphics, context:String, camera:CameraObject, lamp:LampObject, bindParams:Array<String>, start = 0, count = -1) {
		
		if (!visible) return; // Skip render if object is hidden
		if (cullMesh(context, camera, lamp)) return;

		// Get lod
		var lod = this;
		
		// Get context
		var materialContexts:Array<MaterialContext> = [];
		var shaderContexts:Array<ShaderContext> = [];
		getContexts(context, materials, materialContexts, shaderContexts);
		
		transform.update();
		
		// Render mesh
		Uniforms.setConstants(g, shaderContexts[0], this, camera, lamp, bindParams);
		Uniforms.setMaterialConstants(g, shaderContexts[0], materialContexts[0]);

		g.drawIndexedVertices(start, count);

		#if arm_debug
		RenderPath.drawCalls++;
		#end

		#if arm_veloc
		prevMatrix.setFrom(transform.world);
		#end
	}

	inline function validContext(mat:MaterialData, context:String):Bool {
		 return mat.getContext(context) != null;
	}

	public inline function computeCameraDistance(camX:Float, camY:Float, camZ:Float) {
		// Render path mesh sorting
		cameraDistance = iron.math.Vec4.distancef(camX, camY, camZ, transform.worldx(), transform.worldy(), transform.worldz());
	}

	public inline function computeScreenSize(camera:CameraObject) {
		// Approx..
		// var rp = camera.renderPath;
		// var screenVolume = rp.currentW * rp.currentH;
		var tr = transform;
		var volume = tr.dim.x * tr.scale.x * tr.dim.y * tr.scale.y * tr.dim.z * tr.scale.z;
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

	public override function toString():String { return "Mesh Object " + name; }
}
