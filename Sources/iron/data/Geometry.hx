package iron.data;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;
import kha.arrays.Int16Array;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.data.SceneFormat;
import iron.data.MeshData;

class Geometry {
#if arm_deinterleaved
	public var vertexBuffers: Array<InterleavedVertexBuffer>;
#else
	public var vertexBuffer: VertexBuffer;
	public var vertexBufferMap: Map<String, VertexBuffer> = new Map();
#end
	public var indexBuffers: Array<IndexBuffer>;
	public var start = 0; // For drawIndexedVertices
	public var count = -1;
	public var name = "";

	public var ready = false;
	public var vertices: Int16Array;
	public var indices: Array<Uint32Array>;
	public var numTris = 0;
	public var materialIndices: Array<Int>;
	public var struct: VertexStructure;
	public var structLength: Int;
	public var structStr: String;
	public var usage: Usage;

	public var instancedVB: VertexBuffer = null;
	public var instanced = false;
	public var instanceCount = 0;

	public var positions: TVertexArray;
	public var vertexArrays: Array<TVertexArray>;
	var uvs = false;
	var cols = false;
	var data: MeshData;

	public var aabb: Vec4 = null;
	public var aabbMin: Vec4 = null;
	public var aabbMax: Vec4 = null;

	// Skinned
	public var skinBoneCounts: Int16Array = null;
	public var skinBoneIndices: Int16Array = null;
	public var skinBoneWeights: Int16Array = null;

	public var skeletonTransformsI: Array<Mat4> = null;
	public var skeletonBoneRefs: Array<String> = null;
	public var skeletonBoneLens: Float32Array = null;

	public var actions: Map<String, Array<TObj>> = null;
	public var mats: Map<String, Array<Mat4>> = null;

	public function new(data: MeshData,
						indices: Array<Uint32Array>,
						materialIndices: Array<Int>,
						usage: Usage = null) {

		if (usage == null) usage = Usage.StaticUsage;

		this.indices = indices;
		this.materialIndices = materialIndices;
		this.usage = usage;

		this.vertexArrays = data.raw.vertex_arrays;
		this.positions = getVArray('pos');
		this.uvs = getVArray('tex') != null;
		this.cols = getVArray('col') != null;
		this.data = data;

		struct = getVertexStructure(vertexArrays);
		structLength = Std.int(struct.byteSize() / 2);
		structStr = "";
		for (e in struct.elements) structStr += e.name;
	}

	public function delete() {
#if arm_deinterleaved
		for (buf in vertexBuffers) if (buf.buffer != null) buf.buffer.delete();
#else
		for (buf in vertexBufferMap) if (buf != null) buf.delete();
#end
		for (buf in indexBuffers) buf.delete();
	}

	static function getVertexStructure(vertexArrays: Array<TVertexArray>): VertexStructure {
		var structure = new VertexStructure();
		for (i in 0...vertexArrays.length){
			structure.add(vertexArrays[i].attrib, getVertexData(vertexArrays[i].data));
		}
			
		return structure;
	}

	static function getVertexData(data: String): VertexData {
		var d = null;
		switch data {
			case "short4norm": d = VertexData.Short4Norm;
			case "short2norm": d = VertexData.Short2Norm;
		}
		return d;
	}

	public function applyScale(sx: Float, sy: Float, sz: Float) {
		data.scalePos *= sx;
	}

	public function getVArray(name: String): TVertexArray {
		for (i in 0...vertexArrays.length)
			if (vertexArrays[i].attrib == name)
				return vertexArrays[i];
		return null;
	}

	public function setupInstanced(data: Float32Array, instancedType: Int, usage: Usage) {
		var structure = new VertexStructure();
		structure.instanced = true;
		instanced = true;
		// pos, pos+rot, pos+scale, pos+rot+scale
		structure.add("ipos", kha.graphics4.VertexData.Float3);
		if (instancedType == 2 || instancedType == 4) {
			structure.add("irot", kha.graphics4.VertexData.Float3);
		}
		if (instancedType == 3 || instancedType == 4) {
			structure.add("iscl", kha.graphics4.VertexData.Float3);
		}

		instanceCount = Std.int(data.length / Std.int(structure.byteSize() / 4));
		instancedVB = new VertexBuffer(instanceCount, structure, usage, 1);
		var vertices = instancedVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		instancedVB.unlock();
	}

	public function copyVertices(vertices: Int16Array, offset = 0, fakeUVs = false) {
		buildVertices(vertices, vertexArrays, offset, fakeUVs);
	}

	static function buildVertices(vertices: Int16Array,
								  vertexArrays: Array<TVertexArray>,
								  offset = 0,
								  fakeUVs = false,
								  uvsIndex = -1) {	
		var numVertices = verticesCount(vertexArrays[0]);
		var di = -1 + offset;
		for (i in 0...numVertices) {
			for (va in 0...vertexArrays.length) {
				if (fakeUVs && va == uvsIndex) { // add fake uvs if uvs where "asked" for but not found
					vertices.set(++di, 0);
					vertices.set(++di, 0);
					continue;
				}
				var l = vertexArrays[va].size;
				for (o in 0...l) vertices.set(++di, vertexArrays[va].values[i * l + o]);
				if (vertexArrays[va].padding != null)     vertices.set(++di, 0);
			}
		}
	}

	public function getVerticesLength(): Int {
		var res = 0;
		for (i in 0...vertexArrays.length)
			res += vertexArrays[i].values.length;
		return res;
	}

#if arm_deinterleaved
	public function get(vs: Array<TVertexElement>): Array<VertexBuffer> {
		var vbs = [];
		for (e in vs) {
			for (v in 0...vertexBuffers.length)
				if (vertexBuffers[v].name == e.name){
					vbs.push(vertexBuffers[v].buffer);
					continue;
				}
			if (e.name == "ipos") 
				if (instancedVB != null) 
					vbs.push(instancedVB);
		}
		return vbs;
	}
#else
	
	public function get(vs: Array<TVertexElement>): VertexBuffer {
		var key = "";
		for (e in vs) key += e.name;
		var vb = vertexBufferMap.get(key);
		if (vb == null) {
			var nVertexArrays = [];
			var atex = false;
			var texOffset = -1;
			var acol = false;
			for (e in 0...vs.length){
				if (vs[e].name == "tex") {
					atex = true;
					texOffset = e; 
				}
				if (vs[e].name == "col") acol = true;
				for (va in 0...vertexArrays.length)
					if (vs[e].name == vertexArrays[va].attrib)
						nVertexArrays.push(vertexArrays[va]);
			}
			// Multi-mat mesh with different vertex structures		
			var struct = getVertexStructure(nVertexArrays);
			vb = new VertexBuffer(Std.int(positions.values.length / positions.size), struct, usage);
			vertices = vb.lockInt16();
			buildVertices(vertices, nVertexArrays, 0, atex && !uvs, texOffset);
			vb.unlock();
			vertexBufferMap.set(key, vb);
			if (atex && !uvs) trace("Armory Warning: Geometry " + name + " is missing UV map");
			if (acol && !cols) trace("Armory Warning: Geometry " + name + " is missing vertex colors");
		}
		return vb;
	}
#end

	public function build() {
		if (ready) return;

#if arm_deinterleaved
		var vaLength = vertexArrays.length;
		vertexBuffers = [];
		for (i in 0...vaLength) 
			vertexBuffers.push({
				name: vertexArrays[i].attrib,
				buffer: makeDeinterleavedVB(vertexArrays[i].values, vertexArrays[i].attrib, vertexArrays[i].size)
			});
#else

		vertexBuffer = new VertexBuffer(Std.int(positions.values.length / positions.size), struct, usage);
		vertices = vertexBuffer.lockInt16();
		buildVertices(vertices, vertexArrays);
		vertexBuffer.unlock();
		vertexBufferMap.set(structStr, vertexBuffer);
#end

		indexBuffers = [];
		for (id in indices) {
			if (id.length == 0) continue;
			var indexBuffer = new IndexBuffer(id.length, usage);
			numTris += Std.int(id.length / 3);

			var indicesA = indexBuffer.lock();
			for (i in 0...indicesA.length) indicesA[i] = id[i];

			indexBuffer.unlock();
			indexBuffers.push(indexBuffer);
		}

		// Instanced
		if (data.raw.instanced_data != null) setupInstanced(data.raw.instanced_data, data.raw.instanced_type, usage);

		ready = true;
	}

#if arm_deinterleaved
	function makeDeinterleavedVB(data: Int16Array, name: String, structLength: Int) {
		var struct = new VertexStructure();
		struct.add(name, structLength == 2 ? VertexData.Short2Norm : VertexData.Short4Norm);

		var vertexBuffer = new VertexBuffer(Std.int(data.length / structLength), struct, usage);

		var vertices = vertexBuffer.lockInt16();
		for (i in 0...vertices.length) vertices.set(i, data[i]);

		vertexBuffer.unlock();
		return vertexBuffer;
	}
#end

	public function getVerticesCount(): Int {
		return Std.int(positions.values.length / positions.size);
	}

	inline static function verticesCount(arr: TVertexArray): Int {
		return Std.int(arr.values.length / arr.size);
	}

	// Skinned
	public function addArmature(armature: Armature) {
		for (a in armature.actions) {
			addAction(a.bones, a.name);
		}
	}

	public function addAction(bones: Array<TObj>, name: String) {
		if (bones == null) return;
		if (actions == null) {
			actions = new Map();
			mats = new Map();
		}
		if (actions.get(name) != null) return;
		var actionBones: Array<TObj> = [];

		// Set bone references
		for (s in skeletonBoneRefs) {
			for (b in bones) {
				if (b.name == s) {
					actionBones.push(b);
				}
			}
		}
		actions.set(name, actionBones);

		var actionMats: Array<Mat4> = [];
		for (b in actionBones) {
			actionMats.push(Mat4.fromFloat32Array(b.transform.values));
		}
		mats.set(name, actionMats);
	}

	public function initSkeletonTransforms(transformsI: Array<Float32Array>) {
		skeletonTransformsI = [];
		for (t in transformsI) {
			var mi = Mat4.fromFloat32Array(t);
			skeletonTransformsI.push(mi);
		}
	}

	public function calculateAABB() {
		aabbMin = new Vec4(-0.01, -0.01, -0.01);
		aabbMax = new Vec4(0.01, 0.01, 0.01);
		aabb = new Vec4();
		var i = 0;
		while (i < positions.values.length) {
			if (positions.values[i    ] > aabbMax.x) aabbMax.x = positions.values[i];
			if (positions.values[i + 1] > aabbMax.y) aabbMax.y = positions.values[i + 1];
			if (positions.values[i + 2] > aabbMax.z) aabbMax.z = positions.values[i + 2];
			if (positions.values[i    ] < aabbMin.x) aabbMin.x = positions.values[i];
			if (positions.values[i + 1] < aabbMin.y) aabbMin.y = positions.values[i + 1];
			if (positions.values[i + 2] < aabbMin.z) aabbMin.z = positions.values[i + 2];
			i += 4;
		}
		aabb.x = (Math.abs(aabbMin.x) + Math.abs(aabbMax.x)) / 32767 * data.scalePos;
		aabb.y = (Math.abs(aabbMin.y) + Math.abs(aabbMax.y)) / 32767 * data.scalePos;
		aabb.z = (Math.abs(aabbMin.z) + Math.abs(aabbMax.z)) / 32767 * data.scalePos;
	}

	public function calculateTangents() {
		// var num_verts = Std.int(positions.length / 4);
		// var tangents = new Float32Array(num_verts * 3);
		// var bitangents = new Float32Array(num_verts * 3);
		// for (ia in indices) {
		// 	var num_tris = Std.int(ia.length / 3);
		// 	for (i in 0...num_tris) {
		// 		var i0 = ia[i * 3    ];
		// 		var i1 = ia[i * 3 + 1];
		// 		var i2 = ia[i * 3 + 2];
		// 		var v0 = Vector((positions[i0 * 4], positions[i0 * 4 + 1], positions[i0 * 4 + 2]));
		// 		var v1 = Vector((positions[i1 * 4], positions[i1 * 4 + 1], positions[i1 * 4 + 2]));
		// 		var v2 = Vector((positions[i2 * 4], positions[i2 * 4 + 1], positions[i2 * 4 + 2]));
		// 		var uv0 = Vector((uvs[i0 * 2], uvs[i0 * 2 + 1]));
		// 		var uv1 = Vector((uvs[i1 * 2], uvs[i1 * 2 + 1]));
		// 		var uv2 = Vector((uvs[i2 * 2], uvs[i2 * 2 + 1]));

		// 		var deltaPos1 = v1 - v0;
		// 		var deltaPos2 = v2 - v0;
		// 		var deltaUV1 = uv1 - uv0;
		// 		var deltaUV2 = uv2 - uv0;
		// 		var d = (deltaUV1.x * deltaUV2.y - deltaUV1.y * deltaUV2.x);
		// 		var r = d != 0 ? 1.0 / d : 1.0;
		// 		var tangent = (deltaPos1 * deltaUV2.y - deltaPos2 * deltaUV1.y) * r;
		// 		var bitangent = (deltaPos2 * deltaUV1.x - deltaPos1 * deltaUV2.x) * r;

		// 		var tangents[i0 * 3    ] += tangent.x;
		// 		var tangents[i0 * 3 + 1] += tangent.y;
		// 		var tangents[i0 * 3 + 2] += tangent.z;
		// 		var tangents[i1 * 3    ] += tangent.x;
		// 		var tangents[i1 * 3 + 1] += tangent.y;
		// 		var tangents[i1 * 3 + 2] += tangent.z;
		// 		var tangents[i2 * 3    ] += tangent.x;
		// 		var tangents[i2 * 3 + 1] += tangent.y;
		// 		var tangents[i2 * 3 + 2] += tangent.z;
		// 		var bitangents[i0 * 3    ] += bitangent.x;
		// 		var bitangents[i0 * 3 + 1] += bitangent.y;
		// 		var bitangents[i0 * 3 + 2] += bitangent.z;
		// 		var bitangents[i1 * 3    ] += bitangent.x;
		// 		var bitangents[i1 * 3 + 1] += bitangent.y;
		// 		var bitangents[i1 * 3 + 2] += bitangent.z;
		// 		var bitangents[i2 * 3    ] += bitangent.x;
		// 		var bitangents[i2 * 3 + 1] += bitangent.y;
		// 		var bitangents[i2 * 3 + 2] += bitangent.z;
		// 	}
		// }

		// // Orthogonalize
		// for (i in 0...num_verts) {
		// 	var t = Vector((tangents[i * 3], tangents[i * 3 + 1], tangents[i * 3 + 2]));
		// 	var b = Vector((bitangents[i * 3], bitangents[i * 3 + 1], bitangents[i * 3 + 2]));
		// 	var n = Vector((normals[i * 2], normals[i * 2 + 1], positions[i * 4 + 3] / scale_pos));
		// 	var v = t - n * n.dot(t);
		// 	v.normalize();
		// 	// Calculate handedness
		// 	var cnv = n.cross(v);
		// 	if (cnv.dot(b) < 0.0)
		// 		v = v * -1.0;
		// 	tangents[i * 3    ] = v.x;
		// 	tangents[i * 3 + 1] = v.y;
		// 	tangents[i * 3 + 2] = v.z;
		// }
	}
}

#if js
typedef InterleavedVertexBuffer = {
#else
@:structInit class InterleavedVertexBuffer {
#end
	public var name: String;
	public var buffer: VertexBuffer;
}
