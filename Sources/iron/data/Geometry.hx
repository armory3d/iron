package iron.data;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;
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
	public var vertices:Float32Array;
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

	public var positions:Float32Array;
	public var normals:Float32Array;
	public var uvs:Float32Array;
	public var uvs1:Float32Array;
	public var cols:Float32Array;
	public var tangents:Float32Array;
	public var bones:Float32Array;
	public var weights:Float32Array;
	var instancedData:Float32Array;
	var instancedType:Null<Int>;
	
	// public var offsetVecs:Array<Vec4>; // Used for sorting and culling
	public var aabb:Vec4 = null;

	// Skinned
	#if arm_skin_cpu
	public var skinTransform:Mat4 = null;
	public var skinTransformI:Mat4 = null;
	public var skeletonTransforms:Array<Mat4> = null;
	#end
	public var skinBoneCounts:Uint32Array = null;
	public var skinBoneIndices:Uint32Array = null;
	public var skinBoneWeights:Float32Array = null;

	public var skeletonTransformsI:Array<Mat4> = null;
	public var skeletonBoneRefs:Array<String> = null;
	public var skeletonBoneLens:Float32Array = null;

	public var actions:Map<String, Array<TObj>> = null;
	public var mats:Map<String, Array<Mat4>> = null;

	public function new(indices:Array<Uint32Array>,
						materialIndices:Array<Int>,
						positions:Float32Array,
						normals:Float32Array,
						uvs:Float32Array,
						uvs1:Float32Array,
						cols:Float32Array,
						tangents:Float32Array = null,
						bones:Float32Array = null,
						weights:Float32Array = null,
						usage:Usage = null,
						instancedData:Float32Array = null,
						instancedType:Null<Int> = null) {

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
		this.instancedData = instancedData;
		this.instancedType = instancedType;

		// pos=3, tex=2, nor=3, col=4, tang=3, bone=4, weight=4
		struct = getVertexStructure(positions != null, normals != null, uvs != null, uvs1 != null, cols != null, tangents != null, bones != null, weights != null);
		structLength = Std.int(struct.byteSize() / 4);
		structStr = '';
		for (e in struct.elements) structStr += e.name;
	}

	public function delete() {
#if arm_deinterleaved
		for (buf in vertexBuffers) if (buf != null) buf.delete();
#else
		vertexBuffer.delete();
#end
		for (buf in indexBuffers) buf.delete();
	}

	static function getVertexStructure(pos = false, nor = false, tex = false, tex1 = false, col = false, tang = false, bone = false, weight = false):VertexStructure {
		var structure = new VertexStructure();
		if (pos) structure.add("pos", VertexData.Float3);
		if (nor) structure.add("nor", VertexData.Float3);
		if (tex) structure.add("tex", VertexData.Float2);
		if (tex1) structure.add("tex1", VertexData.Float2);
		if (col) structure.add("col", VertexData.Float3);
		if (tang) structure.add("tang", VertexData.Float3);
		if (bone) structure.add("bone", VertexData.Float4);
		if (weight) structure.add("weight", VertexData.Float4);
		return structure;
	}

	public function applyScale(sx:Float, sy:Float, sz:Float) {
		#if arm_deinterleaved
		var vertices = vertexBuffers[0].lock();
		for (i in 0...Std.int(vertices.length / 3)) {
			vertices[i * 3]     *= sx;
			vertices[i * 3 + 1] *= sy;
			vertices[i * 3 + 2] *= sz;
		}
		vertexBuffers[0].unlock();
		#else
		var vertices = vertexBuffer.lock();
		for (i in 0...Std.int(vertices.length / structLength)) {
			vertices[i * structLength]     *= sx;
			vertices[i * structLength + 1] *= sy;
			vertices[i * structLength + 2] *= sz;
		}
		vertexBuffer.unlock();
		#end
	}

	public function setupInstanced(data:Float32Array, instancedType:Int, usage:Usage) {
		// Store vecs for sorting and culling
		// offsetVecs = [];
		// for (i in 0...Std.int(data.length / 3)) {
			// offsetVecs.push(new Vec4(data[i * 3], data[i * 3 + 1], data[i * 3 + 2]));
		// }

		instanced = true;
		instanceCount = Std.int(data.length / 3);

		var structure = new VertexStructure();
		structure.instanced = true;
		// off, loc, loc+rot, loc+scale, loc+rot+scale
		structure.add("ipos", kha.graphics4.VertexData.Float3);
		if (instancedType == 2 || instancedType == 4) {
			structure.add("irot", kha.graphics4.VertexData.Float3);
		}
		if (instancedType == 3 || instancedType == 4) {
			structure.add("iscl", kha.graphics4.VertexData.Float3);
		}

		instancedVB = new VertexBuffer(instanceCount, structure, usage, 1);
		var vertices = instancedVB.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		instancedVB.unlock();
	}

	// public function sortInstanced(camX:Float, camY:Float, camZ:Float) {
	// 	// Use W component to store distance to camera
	// 	for (v in offsetVecs) {
	// 		// TODO: include parent transform
	// 		v.w  = iron.math.Vec4.distancef(camX, camY, camZ, v.x, v.y, v.z);
	// 	}
		
	// 	offsetVecs.sort(function(a, b):Int {
	// 		return a.w > b.w ? 1 : -1;
	// 	});

	// 	var vb = instancedVB;
	// 	var vertices = vb.lock();
	// 	for (i in 0...Std.int(vertices.length / 3)) {
	// 		vertices.set(i * 3, offsetVecs[i].x);
	// 		vertices.set(i * 3 + 1, offsetVecs[i].y);
	// 		vertices.set(i * 3 + 2, offsetVecs[i].z);
	// 	}
	// 	vb.unlock();
	// }

	public function copyVertices(vertices:Float32Array, offset = 0, fakeUVs = false) {
		buildVertices(vertices, positions, normals, uvs, uvs1, cols, tangents, bones, weights, offset, fakeUVs);
	}

	static function buildVertices(vertices:Float32Array,
								  pa:Float32Array = null,
								  na:Float32Array = null,
								  uva:Float32Array = null,
								  uva1:Float32Array = null,
								  ca:Float32Array = null,
								  tanga:Float32Array = null,
								  bonea:Float32Array = null,
								  weighta:Float32Array = null,
								  offset = 0,
								  fakeUVs = false) {

		var numVertices = Std.int(pa.length / 3);
		var di = -1 + offset;
		for (i in 0...numVertices) {
			vertices.set(++di, pa[i * 3]); // Positions
			vertices.set(++di, pa[i * 3 + 1]);
			vertices.set(++di, pa[i * 3 + 2]);

			if (na != null) { // Normals
				vertices.set(++di, na[i * 3]);
				vertices.set(++di, na[i * 3 + 1]);
				vertices.set(++di, na[i * 3 + 2]);
			}
			if (uva != null) { // Texture coords
				vertices.set(++di, uva[i * 2]);
				vertices.set(++di, uva[i * 2 + 1]);
			}
			else if (fakeUVs) {
				vertices.set(++di, 0.0);
				vertices.set(++di, 0.0);
			}
			if (uva1 != null) { // Texture coords 1
				vertices.set(++di, uva1[i * 2]);
				vertices.set(++di, uva1[i * 2 + 1]);
			}
			if (ca != null) { // Colors
				vertices.set(++di, ca[i * 3]);
				vertices.set(++di, ca[i * 3 + 1]);
				vertices.set(++di, ca[i * 3 + 2]);
			}
			// Normal mapping
			if (tanga != null) { // Tangents
				vertices.set(++di, tanga[i * 3]);
				vertices.set(++di, tanga[i * 3 + 1]);
				vertices.set(++di, tanga[i * 3 + 2]);
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
	public function get(vs:Array<TVertexData>):Array<VertexBuffer> {
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
	function hasAttrib(s:String, vs:Array<TVertexData>):Bool {
		for (e in vs) if (e.name == s) return true;
		return false;
	}

	public function get(vs:Array<TVertexData>):VertexBuffer {
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
			vb = new VertexBuffer(Std.int(positions.length / 3), struct, usage);
			vertices = vb.lock();
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
		vertexBuffers[0] = makeDeinterleavedVB(positions, "pos", 3);
		if (normals != null) vertexBuffers[1] = makeDeinterleavedVB(normals, "nor", 3);
		if (uvs != null) vertexBuffers[2] = makeDeinterleavedVB(uvs, "tex", 2);
		if (uvs1 != null) vertexBuffers[3] = makeDeinterleavedVB(uvs1, "tex1", 2);
		if (cols != null) vertexBuffers[4] = makeDeinterleavedVB(cols, "col", 3);
		if (tangents != null) vertexBuffers[5] = makeDeinterleavedVB(tangents, "tang", 3);
		if (bones != null) vertexBuffers[6] = makeDeinterleavedVB(bones, "bone", 4);
		if (weights != null) vertexBuffers[7] = makeDeinterleavedVB(weights, "weight", 4);
#else

		vertexBuffer = new VertexBuffer(Std.int(positions.length / 3), struct, usage);
		vertices = vertexBuffer.lock();
		buildVertices(vertices, positions, normals, uvs, uvs1, cols, tangents, bones, weights);
		vertexBuffer.unlock();
		vertexBufferMap.set(structStr, vertexBuffer);
#end

		indexBuffers = [];
		for (id in indices) {
			if (id.length == 0) continue;
			var indexBuffer = new IndexBuffer(id.length, usage);
			numTris += Std.int(id.length / 3);

			#if (kha_html5 && !arm_json && arm_fast)
			indexBuffer._data = id;
			#else
			var indicesA = indexBuffer.lock();
			for (i in 0...indicesA.length) indicesA[i] = id[i];
			#end
			
			indexBuffer.unlock();
			indexBuffers.push(indexBuffer);
		}

		// Instanced
		if (instancedData != null) setupInstanced(instancedData, instancedType, usage);

		ready = true;
	}

#if arm_deinterleaved
	function makeDeinterleavedVB(data:Float32Array, name:String, structLength:Int) {
		var struct = new VertexStructure();
		if (structLength == 2) struct.add(name, VertexData.Float2);
		else if (structLength == 3) struct.add(name, VertexData.Float3);
		else if (structLength == 4) struct.add(name, VertexData.Float4);

		var vertexBuffer = new VertexBuffer(Std.int(data.length / structLength), struct, usage);
		
		#if (kha_html5 && !arm_json && arm_fast)
		vertexBuffer._data = data;
		#else
		var vertices = vertexBuffer.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		#end
		
		vertexBuffer.unlock();
		return vertexBuffer;
	}
#end

	public function getVerticesCount():Int {
		return Std.int(positions.length / 3);
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
		#if arm_skin_cpu
		skeletonTransforms = [];
		#end

		for (t in transformsI) {
			var mi = Mat4.fromFloat32Array(t);
			skeletonTransformsI.push(mi);
		}
		#if arm_skin_cpu
			for (mi in skeletonTransformsI) {
				var m = Mat4.identity();
				m.getInverse(mi);
				skeletonTransforms.push(m);
			}
		#end
	}

	#if arm_skin_cpu
	public function initSkinTransform(t:Float32Array) {
		skinTransform = Mat4.fromFloat32Array(t);
		skinTransformI = Mat4.identity();
		skinTransformI.getInverse(skinTransform);
	}
	#end

	public function calculateAABB() {
		var aabbMin = new Vec4(-0.01, -0.01, -0.01);
		var aabbMax = new Vec4(0.01, 0.01, 0.01);
		aabb = new Vec4();
		var i = 0;
		while (i < positions.length) {
			if (positions[i] > aabbMax.x) aabbMax.x = positions[i];
			if (positions[i + 1] > aabbMax.y) aabbMax.y = positions[i + 1];
			if (positions[i + 2] > aabbMax.z) aabbMax.z = positions[i + 2];
			if (positions[i] < aabbMin.x) aabbMin.x = positions[i];
			if (positions[i + 1] < aabbMin.y) aabbMin.y = positions[i + 1];
			if (positions[i + 2] < aabbMin.z) aabbMin.z = positions[i + 2];
			i += 3;
		}
		aabb.x = Math.abs(aabbMin.x) + Math.abs(aabbMax.x);
		aabb.y = Math.abs(aabbMin.y) + Math.abs(aabbMax.y);
		aabb.z = Math.abs(aabbMin.z) + Math.abs(aabbMax.z);
		// Sphere radius
		// if (aabb.x >= aabb.y && aabb.x >= aabb.z) radius = aabb.x / 2;
		// else if (aabb.y >= aabb.x && aabb.y >= aabb.z) radius = aabb.y / 2;
		// else radius = aabb.z / 2;
	}

	// ftp://ftp.fox-toolkit.org/pub/fasthalffloatconversion.pdf
	// Half to Float
	// float f = ((h&0x8000)<<16) | (((h&0x7c00)+0x1C000)<<13) | ((h&0x03FF)<<13);
	// Float to Half
	// uint32_t x = *((uint32_t*)&f);
	// uint16_t h = ((x>>16)&0x8000)|((((x&0x7f800000)-0x38000000)>>13)&0x7c00)|((x>>13)&0x03ff);
}
