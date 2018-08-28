package iron.data;

#if arm_batch

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.graphics4.Graphics;
import iron.object.CameraObject;
import iron.object.LightObject;
import iron.object.MeshObject;
import iron.object.Uniforms;
import iron.data.MaterialData;
import iron.data.ShaderData;
import iron.data.MeshData;

@:access(iron.object.MeshObject)
@:access(iron.object.Uniforms)
class MeshBatch {

	var buckets:Map<ShaderData, Bucket> = new Map();
	public var nonBatched:Array<MeshObject> = [];

	public function new() {

	}

	public function remove() {
		for (b in buckets) remove();
	}

	public static function isBatchable(m:MeshObject):Bool {
		return !(m.materials == null || m.materials.length > 1 || m.data.geom.instanced);
	}

	public function addMesh(m:MeshObject, isLod:Bool):Bool {
		if (!isBatchable(m) || isLod) { // No instancing, multimat or lod batching
			nonBatched.push(m);
			return false;
		}

		var shader = m.materials[0].shader;
		var b = buckets.get(shader);
		if (b == null) {
			b = new Bucket(shader);
			buckets.set(shader, b);
		}
		b.addMesh(m);
		return true;
	}

	public function removeMesh(m:MeshObject) {
		var shader = m.materials[0].shader;
		var b = buckets.get(shader);
		if (b != null) b.removeMesh(m);
		else nonBatched.remove(m);
	}

	public function render(g:Graphics, context:String, camera:CameraObject, light:LightObject, bindParams:Array<String>) {

		for (b in buckets) {

			if (!b.batched) b.batch();
			if (b.meshes.length > 0 && b.meshes[0].cullMaterial(context)) continue;

			var scontext = b.shader.getContext(context);
			g.setPipeline(scontext.pipeState);
			// #if arm_deinterleaved // TODO
			// g.setVertexBuffers(b.vertexBuffers);
			// #else
			g.setVertexBuffer(b.vertexBuffer);
			// #end
			g.setIndexBuffer(b.indexBuffer);
			
			Uniforms.setContextConstants(g, scontext, camera, light, bindParams);

			RenderPath.sortMeshesDistance(b.meshes, camera);

			for (m in b.meshes) {

				if (!m.visible) continue; // Skip render if object is hidden
				if (m.cullMesh(context, camera, light)) continue;
				
				// Get context
				var materialContexts:Array<MaterialContext> = [];
				var shaderContexts:Array<ShaderContext> = [];
				m.getContexts(context, m.materials, materialContexts, shaderContexts);
				
				m.transform.update();
				
				// Render mesh
				Uniforms.setObjectConstants(g, scontext, m, camera, light);
				Uniforms.setMaterialConstants(g, scontext, materialContexts[0]);

				g.drawIndexedVertices(m.data.start, m.data.count);

				#if arm_veloc
				m.prevMatrix.setFrom(m.transform.world);
				#end
				
				#if arm_debug
				RenderPath.drawCalls++;
				RenderPath.batchCalls++;
				#end
			}

			#if arm_debug
			RenderPath.batchBuckets++;
			#end
		}

		for (m in nonBatched) {
			m.render(g, context, camera, light, bindParams);
			
			#if arm_debug
			if (m.culled) RenderPath.culled++;
			#end
		}
	}
}

class Bucket {

	public var batched = false;
	public var shader:ShaderData;
	public var vertexBuffer:VertexBuffer;
	public var indexBuffer:IndexBuffer;
	public var meshes:Array<MeshObject> = [];

	public function new(shader:ShaderData) {
		this.shader = shader;
	}

	public function remove() {
		vertexBuffer.delete();
		indexBuffer.delete();
		meshes = [];
	}

	public function addMesh(m:MeshObject) {
		meshes.push(m);
	}

	public function removeMesh(m:MeshObject) {
		meshes.remove(m);
	}

	function vertexCount(g:Geometry, hasUVs:Bool):Int {
		var vcount = g.getVerticesLength();
		if (hasUVs && g.uvs == null) {
			vcount += Std.int(g.positions.length / 3) * 2;
		}
		return vcount;
	}

	public function batch() {
		batched = true;

		// Ensure same vertex structure for batched meshes
		var hasUVs = false;
		for (m in meshes) if (m.data.geom.uvs != null) { hasUVs = true; break; }

		// Unique mesh datas
		var vcount = 0;
		var icount = 0;
		var mdatas:Array<MeshData> = [];
		for (m in meshes) {
			var mdFound = false;
			for (md in mdatas) {
				if (m.data == md) {
					mdFound = true;
					break;
				}
			}
			if (!mdFound) {
				mdatas.push(m.data);
				m.data.start = icount;
				m.data.count = m.data.geom.indices[0].length;
				icount += m.data.count;
				vcount += vertexCount(m.data.geom, hasUVs);
			}
		}

		if (mdatas.length == 0) return;

		// Pick UVs if present
		var vs = mdatas[0].geom.struct;
		for (md in mdatas) if (md.geom.struct.size() > vs.size()) vs = md.geom.struct;

		// Build shared buffers
		vertexBuffer = new VertexBuffer(vcount, vs, Usage.StaticUsage);
		var vertices = vertexBuffer.lock();
		var offset = 0;
		for (md in mdatas) {
			md.geom.copyVertices(vertices, offset, hasUVs);
			offset += vertexCount(md.geom, hasUVs);
		}
		vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(icount, Usage.StaticUsage);
		var indices = indexBuffer.lock();
		var di = -1;
		var offset = 0;
		for (md in mdatas) {
			for (i in 0...md.geom.indices[0].length) {
				indices[++di] = md.geom.indices[0][i] + offset;
			}
			offset += Std.int(md.geom.getVerticesLength() / md.geom.structLength);
		}
		indexBuffer.unlock();
	}
}

#end
