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

class Geometry {
#if arm_deinterleaved
	public var vertexBuffers:Array<VertexBuffer>;
#else
	public var vertexBuffer:VertexBuffer;
	public var vertexBufferMap:Map<String, VertexBuffer> = new Map();
#end
	public var indexBuffers:Array<IndexBuffer>;
	public var start = 0; // For drawIndexedVertices
	public var count = -1;
	public var name = "";

	public var ready = false;
	public var vertices:Int16Array;
	public var indices:Array<Uint32Array>;
	public var numTris = 0;
	public var materialIndices:Array<Int>;
	public var struct:VertexStructure;
	public var structLength:Int;
	public var structStr:String;
	public var usage:Usage;

	public var instancedVB:VertexBuffer = null;
	public var instanced = false;
	public var instanceCount = 0;

	public var positions:Int16Array;
	public var normals:Int16Array;
	public var uvs:Int16Array;
	public var uvs1:Int16Array;
	public var cols:Int16Array;
	public var tangents:Int16Array;
	public var bones:Int16Array;
	public var weights:Int16Array;
	var data:MeshData;
	
	public var aabb:Vec4 = null;
	public var aabbMin:Vec4 = null;
	public var aabbMax:Vec4 = null;

	// Skinned
	public var skinBoneCounts:Int16Array = null;
	public var skinBoneIndices:Int16Array = null;
	public var skinBoneWeights:Int16Array = null;

	public var skeletonTransformsI:Array<Mat4> = null;
	public var skeletonBoneRefs:Array<String> = null;
	public var skeletonBoneLens:Float32Array = null;

	public var actions:Map<String, Array<TObj>> = null;
	public var mats:Map<String, Array<Mat4>> = null;

	public function new(data:MeshData,
						indices:Array<Uint32Array>,
						materialIndices:Array<Int>,
						positions:Int16Array,
						normals:Int16Array,
						uvs:Int16Array,
						uvs1:Int16Array,
						cols:Int16Array,
						tangents:Int16Array = null,
						bones:Int16Array = null,
						weights:Int16Array = null,
						usage:Usage = null) {

		if (usage == null) usage = Usage.StaticUsage;

		this.indices = indices;
		this.materialIndices = materialIndices;
		this.usage = usage;

		this.positions = positions;
		this.normals = normals;
		this.uvs = uvs;
		this.uvs1 = uvs1;
		this.cols = cols;
		this.tangents = tangents;
		this.bones = bones;
		this.weights = weights;
		this.data = data;

		// pos=4, nor=2, tex=2, col=4, tang=4, bone=4, weight=4
		struct = getVertexStructure(positions != null, normals != null, uvs != null, uvs1 != null, cols != null, tangents != null, bones != null, weights != null);
		structLength = Std.int(struct.byteSize() / 2);
		structStr = '';
		for (e in struct.elements) structStr += e.name;
	}

	public function delete() {
#if arm_deinterleaved
		for (buf in vertexBuffers) if (buf != null) buf.delete();
#else
		for (buf in vertexBufferMap) if (buf != null) buf.delete();
#end
		for (buf in indexBuffers) buf.delete();
	}

	static function getVertexStructure(pos = false, nor = false, tex = false, tex1 = false, col = false, tang = false, bone = false, weight = false):VertexStructure {
		var structure = new VertexStructure();
		if (pos) structure.add("pos", VertexData.Short4Norm); // p.xyz + n.z
		if (nor) structure.add("nor", VertexData.Short2Norm); // n.xy
		if (tex) structure.add("tex", VertexData.Short2Norm);
		if (tex1) structure.add("tex1", VertexData.Short2Norm);
		if (col) structure.add("col", VertexData.Short4Norm); // 3+1 padding
		if (tang) structure.add("tang", VertexData.Short4Norm); //3+1 padding
		if (bone) structure.add("bone", VertexData.Short4Norm);
		if (weight) structure.add("weight", VertexData.Short4Norm);
		return structure;
	}

	public function applyScale(sx:Float, sy:Float, sz:Float) {
		data.scalePos *= sx;
	}

	public function setupInstanced(data:Float32Array, instancedType:Int, usage:Usage) {
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

	public function copyVertices(vertices:Int16Array, offset = 0, fakeUVs = false) {
		buildVertices(vertices, positions, normals, uvs, uvs1, cols, tangents, bones, weights, offset, fakeUVs);
	}

	static function buildVertices(vertices:Int16Array,
								  pa:Int16Array = null,
								  na:Int16Array = null,
								  uva:Int16Array = null,
								  uva1:Int16Array = null,
								  ca:Int16Array = null,
								  tanga:Int16Array = null,
								  bonea:Int16Array = null,
								  weighta:Int16Array = null,
								  offset = 0,
								  fakeUVs = false) {

		var numVertices = Std.int(pa.length / 4);
		var di = -1 + offset;
		for (i in 0...numVertices) {
			vertices.set(++di, pa[i * 4    ]); // Positions
			vertices.set(++di, pa[i * 4 + 1]);
			vertices.set(++di, pa[i * 4 + 2]);
			vertices.set(++di, pa[i * 4 + 3]); // n.z
			if (na != null) { // Normals
				vertices.set(++di, na[i * 2    ]); // n.x
				vertices.set(++di, na[i * 2 + 1]); // n.y
			}
			if (uva != null) { // Texture coords
				vertices.set(++di, uva[i * 2    ]);
				vertices.set(++di, uva[i * 2 + 1]);
			}
			else if (fakeUVs) {
				vertices.set(++di, 0);
				vertices.set(++di, 0);
			}
			if (uva1 != null) { // Texture coords 1
				vertices.set(++di, uva1[i * 2    ]);
				vertices.set(++di, uva1[i * 2 + 1]);
			}
			if (ca != null) { // Colors
				vertices.set(++di, ca[i * 3    ]);
				vertices.set(++di, ca[i * 3 + 1]);
				vertices.set(++di, ca[i * 3 + 2]);
				vertices.set(++di, 0); // Padding
			}
			// Normal mapping
			if (tanga != null) { // Tangents
				vertices.set(++di, tanga[i * 3    ]);
				vertices.set(++di, tanga[i * 3 + 1]);
				vertices.set(++di, tanga[i * 3 + 2]);
				vertices.set(++di, 0); // Padding
			}
			// GPU skinning
			if (bonea != null) { // Bone indices
				vertices.set(++di, bonea[i * 4]);
				vertices.set(++di, bonea[i * 4 + 1]);
				vertices.set(++di, bonea[i * 4 + 2]);
				vertices.set(++di, bonea[i * 4 + 3]);
			}
			if (weighta != null) { // Weights
				vertices.set(++di, weighta[i * 4]);
				vertices.set(++di, weighta[i * 4 + 1]);
				vertices.set(++di, weighta[i * 4 + 2]);
				vertices.set(++di, weighta[i * 4 + 3]);
			}
		}
	}

	public function getVerticesLength():Int {
		var res = positions.length;
		if (normals != null) res += normals.length;
		if (uvs != null) res += uvs.length;
		if (uvs1 != null) res += uvs1.length;
		if (cols != null) res += cols.length;
		if (tangents != null) res += tangents.length;
		if (bones != null) res += bones.length;
		if (weights != null) res += weights.length;
		return res;
	}

#if arm_deinterleaved
	public function get(vs:Array<TVertexElement>):Array<VertexBuffer> {
		var vbs = [];
		for (e in vs) {
			if (e.name == 'pos') { if (vertexBuffers[0] != null) vbs.push(vertexBuffers[0]); }
			else if (e.name == 'nor') { if (vertexBuffers[1] != null) vbs.push(vertexBuffers[1]); }
			else if (e.name == 'tex') { if (vertexBuffers[2] != null) vbs.push(vertexBuffers[2]); }
			else if (e.name == 'tex1') { if (vertexBuffers[3] != null) vbs.push(vertexBuffers[3]); }
			else if (e.name == 'col') { if (vertexBuffers[4] != null) vbs.push(vertexBuffers[4]); }
			else if (e.name == 'tang') { if (vertexBuffers[5] != null) vbs.push(vertexBuffers[5]); }
			else if (e.name == 'bone') { if (vertexBuffers[6] != null) vbs.push(vertexBuffers[6]); }
			else if (e.name == 'weight') { if (vertexBuffers[7] != null) vbs.push(vertexBuffers[7]); }
			else if (e.name == 'ipos') { if (instancedVB != null) vbs.push(instancedVB); }
		}
		return vbs;
	}
#else
	function hasAttrib(s:String, vs:Array<TVertexElement>):Bool {
		for (e in vs) if (e.name == s) return true;
		return false;
	}

	public function get(vs:Array<TVertexElement>):VertexBuffer {
		var s = '';
		for (e in vs) s += e.name;
		var vb = vertexBufferMap.get(s);
		if (vb == null) {
			// Multi-mat mesh with different vertex structures
			var apos = hasAttrib("pos", vs);
			var anor = hasAttrib("nor", vs);
			var atex = hasAttrib("tex", vs);
			var atex1 = hasAttrib("tex1", vs);
			var acol = hasAttrib("col", vs);
			var atang = hasAttrib("tang", vs);
			var abone = hasAttrib("bone", vs);
			var aweight = hasAttrib("weight", vs);
			var struct = getVertexStructure(apos, anor, atex, atex1, acol, atang, abone, aweight);
			vb = new VertexBuffer(Std.int(positions.length / 4), struct, usage);
			vertices = vb.lockInt16();
			buildVertices(vertices, apos ? positions : null, anor ? normals : null, atex ? uvs : null, atex1 ? uvs1 : null, acol ? cols : null, atang ? tangents : null, abone ? bones : null, aweight ? weights : null, 0, atex && uvs == null);
			vb.unlock();
			vertexBufferMap.set(s, vb);
			if (atex && uvs == null) trace("Armory Warning: Geometry " + name + " is missing UV map");
			if (acol && cols == null) trace("Armory Warning: Geometry " + name + " is missing vertex colors");
		}
		return vb;
	}
#end

	public function build() {
		if (ready) return;

#if arm_deinterleaved
		vertexBuffers = [null, null, null, null, null, null, null, null];
		vertexBuffers[0] = makeDeinterleavedVB(positions, "pos", 4);
		if (normals != null) vertexBuffers[1] = makeDeinterleavedVB(normals, "nor", 2);
		if (uvs != null) vertexBuffers[2] = makeDeinterleavedVB(uvs, "tex", 2);
		if (uvs1 != null) vertexBuffers[3] = makeDeinterleavedVB(uvs1, "tex1", 2);
		if (cols != null) vertexBuffers[4] = makeDeinterleavedVB(cols, "col", 4);
		if (tangents != null) vertexBuffers[5] = makeDeinterleavedVB(tangents, "tang", 4);
		if (bones != null) vertexBuffers[6] = makeDeinterleavedVB(bones, "bone", 4);
		if (weights != null) vertexBuffers[7] = makeDeinterleavedVB(weights, "weight", 4);
#else

		vertexBuffer = new VertexBuffer(Std.int(positions.length / 4), struct, usage);
		vertices = vertexBuffer.lockInt16();
		buildVertices(vertices, positions, normals, uvs, uvs1, cols, tangents, bones, weights);
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
	function makeDeinterleavedVB(data:Int16Array, name:String, structLength:Int) {
		var struct = new VertexStructure();
		struct.add(name, structLength == 2 ? VertexData.Short2Norm : VertexData.Short4Norm);

		var vertexBuffer = new VertexBuffer(Std.int(data.length / structLength), struct, usage);

		var vertices = vertexBuffer.lockInt16();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		
		vertexBuffer.unlock();
		return vertexBuffer;
	}
#end

	public function getVerticesCount():Int {
		return Std.int(positions.length / 4);
	}

	// Skinned
	public function addArmature(armature:Armature) {
		for (a in armature.actions) {
			addAction(a.bones, a.name);
		}
	}

	public function addAction(bones:Array<TObj>, name:String) {
		if (bones == null) return;
		if (actions == null) {
			actions = new Map();
			mats = new Map();
		}
		if (actions.get(name) != null) return;
		var actionBones:Array<TObj> = [];

		// Set bone references
		for (s in skeletonBoneRefs) {
			for (b in bones) {
				if (b.name == s) {
					actionBones.push(b);
				}
			}
		}
		actions.set(name, actionBones);

		var actionMats:Array<Mat4> = [];
		for (b in actionBones) {
			actionMats.push(Mat4.fromFloat32Array(b.transform.values));
		}
		mats.set(name, actionMats);
	}

	public function initSkeletonTransforms(transformsI:Array<Float32Array>) {
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
		while (i < positions.length) {
			if (positions[i    ] > aabbMax.x) aabbMax.x = positions[i];
			if (positions[i + 1] > aabbMax.y) aabbMax.y = positions[i + 1];
			if (positions[i + 2] > aabbMax.z) aabbMax.z = positions[i + 2];
			if (positions[i    ] < aabbMin.x) aabbMin.x = positions[i];
			if (positions[i + 1] < aabbMin.y) aabbMin.y = positions[i + 1];
			if (positions[i + 2] < aabbMin.z) aabbMin.z = positions[i + 2];
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
