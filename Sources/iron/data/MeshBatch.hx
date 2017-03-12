package iron.data;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.graphics4.Graphics;
import iron.object.CameraObject;
import iron.object.LampObject;
import iron.object.MeshObject;
import iron.object.Uniforms;
import iron.data.MaterialData;
import iron.data.MeshData;

class MeshBatch {

	var buckets:Map<MaterialData, Bucket> = new Map();
	var nonBatched:Array<MeshObject> = [];

	public function new() {

	}

	public function remove() {
		for (b in buckets) remove();
	}

	function isLod(m:MeshObject):Bool {
		return (m.raw != null && m.raw.lods != null && m.raw.lods.length > 0);
	}

	public function addMesh(m:MeshObject) {

		// Batch only basic meshes for now
		if (m.data.isSkinned || m.materials.length > 1 || isLod(m) || m.data.mesh.instanced) {
			nonBatched.push(m);
			return;
		}

		var mat = m.materials[0];
		var b = buckets.get(mat);
		if (b == null) {
			b = new Bucket(mat);
			buckets.set(mat, b);
		}
		b.addMesh(m);
	}

	public function removeMesh(m:MeshObject) {
		var mat = m.materials[0];
		var b = buckets.get(mat);
		if (b != null) b.removeMesh(m);
	}

	public function render(g:Graphics, context:String, camera:CameraObject, lamp:LampObject, bindParams:Array<String>) {

		for (b in buckets) {

			if (!b.batched) b.batch();

			if (b.meshes.length > 0 && b.meshes[0].cullMaterial(context, camera)) continue;

			g.setPipeline(b.mat.shader.getContext(context).pipeState);
			g.setVertexBuffer(b.vertexBuffer);
			g.setIndexBuffer(b.indexBuffer);

			// TODO: Sort bucket front to back

			for (i in 0...b.meshes.length) {
				var m = b.meshes[i];
				var start = b.starts[i];
				var count = b.counts[i];
				m.renderBatch(g, context, camera, lamp, bindParams, start, count);
#if arm_profile
				RenderPath.batchCalls++;
#end
			}

#if arm_profile
				RenderPath.batchBuckets++;
#end
		}

		for (m in nonBatched) {
			m.render(g, context, camera, lamp, bindParams);
		}
	}
}

class Bucket {

	public var batched = false;

	public var mat:MaterialData;
	public var vertexBuffer:VertexBuffer;
	public var indexBuffer:IndexBuffer;
	public var meshes:Array<MeshObject> = [];
	public var starts:Array<Int> = [];
	public var counts:Array<Int> = [];

	var bdata:Map<MeshData, BucketData> = new Map();

	public function new(mat:MaterialData) {
		this.mat = mat;
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

	public function batch() {
		batched = true;

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
				var count = m.data.mesh.indices[0].length;
				var d = new BucketData(icount, count);
				bdata.set(m.data, d);
				vcount += m.data.mesh.vertices.length;
				icount += count;
			}

			var d = bdata.get(m.data);
			starts.push(d.start);
			counts.push(d.count);
		}

		// Build shared buffers
		vertexBuffer = new VertexBuffer(vcount, mat.shader.structure, Usage.StaticUsage);
		var vertices = vertexBuffer.lock();
		var di = -1;
		for (md in mdatas) {
			for (i in 0...md.mesh.vertices.length) {
				vertices.set(++di, md.mesh.vertices.get(i));
			}
		}
		vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(icount, Usage.StaticUsage);
		var indices = indexBuffer.lock();
		di = -1;
		var offset = 0;
		for (md in mdatas) {
			for (i in 0...md.mesh.indices[0].length) {
				indices[++di] = md.mesh.indices[0][i] + offset;
			}
			offset += Std.int(md.mesh.vertices.length / mat.shader.structureLength); // / md.mesh.structLength
		}
		indexBuffer.unlock();
	}
}

class BucketData {
	public var start:Int;
	public var count:Int;
	public function new(start:Int, count:Int) {
		this.start = start;
		this.count = count;
	}
}
