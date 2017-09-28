package iron.data;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.data.SceneFormat;

class Geometry {
#if arm_deinterleaved
	public var vertexBuffers:Array<VertexBuffer>;
#else
	public var vertexBuffer:VertexBuffer;
#end
	public var indexBuffers:Array<IndexBuffer>;

	public var ready = false;
	public var vertices:kha.arrays.Float32Array;
	public var indices:Array<TUint32Array>;
	public var numTris = 0;
	public var materialIndices:Array<Int>;
	public var struct:VertexStructure;
	public var structLength:Int;
	public var usage:Usage;

	public var instancedVB:VertexBuffer = null;
	public var instanced = false;
	public var instanceCount = 0;

	public var positions:TFloat32Array; // TODO: no need to store these references
	public var normals:TFloat32Array;
	public var uvs:TFloat32Array;
	public var uvs1:TFloat32Array;
	public var cols:TFloat32Array;
	public var tangents:TFloat32Array;
	public var bones:TFloat32Array;
	public var weights:TFloat32Array;
	var instanceOffsets:TFloat32Array;
	
	public var offsetVecs:Array<Vec4>; // Used for sorting and culling
	public var aabb:Vec4 = null;

	// Skinned
	public var skinTransform:Mat4 = null;
	public var skinTransformI:Mat4 = null;
	public var skinBoneCounts:TUint32Array = null;
	public var skinBoneIndices:TUint32Array = null;
	public var skinBoneWeights:TFloat32Array = null;

	public var skeletonTransforms:Array<Mat4> = null;
	public var skeletonTransformsI:Array<Mat4> = null;
	public var skeletonBoneRefs:Array<String> = null;
	public var skeletonBones:Array<TObj> = null;
	public var skeletonMats:Map<TObj, Mat4> = null;
	public var actions:Map<String, Array<TObj>> = null;
	public var mats:Map<String, Map<TObj, Mat4>> = null;

	public function new(indices:Array<TUint32Array>, materialIndices:Array<Int>,
						positions:TFloat32Array,
						normals:TFloat32Array,
						uvs:TFloat32Array,
						uvs1:TFloat32Array,
						cols:TFloat32Array,
						tangents:TFloat32Array = null,
						bones:TFloat32Array = null,
						weights:TFloat32Array = null,
						usage:Usage = null, instanceOffsets:TFloat32Array = null) {

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
		this.instanceOffsets = instanceOffsets;

		// TODO: Mandatory vertex data names and sizes
		// pos=3, tex=2, nor=3, col=4, tang=3, bone=4, weight=4
		struct = getVertexStructure(positions != null, normals != null, uvs != null, uvs1 != null, cols != null, tangents != null, bones != null, weights != null);
		structLength = Std.int(struct.byteSize() / 4);
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

	public function setupInstanced(offsets:TFloat32Array, usage:Usage) {
		// Store vecs for sorting and culling
		offsetVecs = [];
		for (i in 0...Std.int(offsets.length / 3)) {
			offsetVecs.push(new Vec4(offsets[i * 3], offsets[i * 3 + 1], offsets[i * 3 + 2]));
		}

		instanced = true;
		instanceCount = Std.int(offsets.length / 3);

		var structure = new VertexStructure();
		structure.instanced = true;
		structure.add("off", kha.graphics4.VertexData.Float3);

		instancedVB = new VertexBuffer(instanceCount, structure, usage, 1);
		var vertices = instancedVB.lock();
		for (i in 0...vertices.length) vertices.set(i, offsets[i]);
		instancedVB.unlock();
	}

	public function sortInstanced(camX:Float, camY:Float, camZ:Float) {
		// Use W component to store distance to camera
		for (v in offsetVecs) {
			// TODO: include parent transform
			v.w  = iron.math.Vec4.distance3df(camX, camY, camZ, v.x, v.y, v.z);
		}
		
		offsetVecs.sort(function(a, b):Int {
			return a.w > b.w ? 1 : -1;
		});

		var vb = instancedVB;
		var vertices = vb.lock();
		for (i in 0...Std.int(vertices.length / 3)) {
			vertices.set(i * 3, offsetVecs[i].x);
			vertices.set(i * 3 + 1, offsetVecs[i].y);
			vertices.set(i * 3 + 2, offsetVecs[i].z);
		}
		vb.unlock();
	}

	public function copyVertices(vertices:kha.arrays.Float32Array, offset = 0) {
		buildVertices(vertices, positions, normals, uvs, uvs1, cols, tangents, bones, weights, offset);
	}

	static function buildVertices(vertices:kha.arrays.Float32Array,
								  pa:TFloat32Array = null,
								  na:TFloat32Array = null,
								  uva:TFloat32Array = null,
								  uva1:TFloat32Array = null,
								  ca:TFloat32Array = null,
								  tanga:TFloat32Array = null,
								  bonea:TFloat32Array = null,
								  weighta:TFloat32Array = null,
								  offset = 0) {

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
	public function getVertexBuffers(vertex_structure:Array<TVertexData>):Array<VertexBuffer> {
		var vbs = [];
		for (e in vertex_structure) {
			if (e.name == 'pos') { if (vertexBuffers[0] != null) vbs.push(vertexBuffers[0]); }
			else if (e.name == 'nor') { if (vertexBuffers[1] != null) vbs.push(vertexBuffers[1]); }
			else if (e.name == 'tex') { if (vertexBuffers[2] != null) vbs.push(vertexBuffers[2]); }
			else if (e.name == 'tex1') { if (vertexBuffers[3] != null) vbs.push(vertexBuffers[3]); }
			else if (e.name == 'col') { if (vertexBuffers[4] != null) vbs.push(vertexBuffers[4]); }
			else if (e.name == 'tang') { if (vertexBuffers[5] != null) vbs.push(vertexBuffers[5]); }
			else if (e.name == 'bone') { if (vertexBuffers[6] != null) vbs.push(vertexBuffers[6]); }
			else if (e.name == 'weight') { if (vertexBuffers[7] != null) vbs.push(vertexBuffers[7]); }
			else if (e.name == 'off') { if (instancedVB != null) vbs.push(instancedVB); }
		}
		return vbs;
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
#end

		indexBuffers = [];
		for (id in indices) {
			if (id.length == 0) continue; // Material has no faces assigned, discard
			// TODO: duplicate storage allocated in IB
			var indexBuffer = new IndexBuffer(id.length, usage);
			numTris += Std.int(id.length / 3);
			
			#if (cpp || arm_json || kha_node)
			var indicesA = indexBuffer.lock();
			for (i in 0...indicesA.length) indicesA[i] = id[i];
			#else
			indexBuffer._data = id;
			#end
			
			indexBuffer.unlock();

			indexBuffers.push(indexBuffer);
		}

		// Instanced
		if (instanceOffsets != null) setupInstanced(instanceOffsets, usage);

		ready = true;
	}

#if arm_deinterleaved
	function makeDeinterleavedVB(data:TFloat32Array, name:String, structLength:Int) {
		var struct = new VertexStructure();
		if (structLength == 2) struct.add(name, VertexData.Float2);
		else if (structLength == 3) struct.add(name, VertexData.Float3);
		else if (structLength == 4) struct.add(name, VertexData.Float4);

		// TODO: duplicate storage allocated in VB
		var vertexBuffer = new VertexBuffer(Std.int(data.length / structLength), struct, usage);
		
		#if (cpp || arm_json || kha_node)
		var vertices = vertexBuffer.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		#else
		vertexBuffer._data = data;
		#end
		
		vertexBuffer.unlock();
		return vertexBuffer;
	}
#end

	public function getVerticesCount():Int {
		return Std.int(positions.length / 3);
	}

	// Skinned
	public function addAction(bones:Array<TObj>, name:String) {
		if (actions == null) {
			actions = new Map();
			mats = new Map();
		}
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

		var actionMats = new Map<TObj, Mat4>();
		for (b in actionBones) {
			actionMats.set(b, Mat4.fromFloat32Array(b.transform.values));
			// boneTimeIndices.set(b, 0);
		}
		mats.set(name, actionMats);

		if (skeletonBones == null) {
			skeletonBones = actionBones;
			skeletonMats = actionMats;
		}
	}

	public function setAction(action:String) {
		skeletonBones = actions.get(action);
		skeletonMats = mats.get(action);
	}

	public function initSkeletonTransforms(transforms:Array<TFloat32Array>) {
		skeletonTransforms = [];
		skeletonTransformsI = [];

		for (t in transforms) {
			var m = Mat4.fromFloat32Array(t);
			skeletonTransforms.push(m);
			
			var mi = Mat4.identity();
			mi.getInverse(m);
			skeletonTransformsI.push(mi);
		}
	}

	public function initSkinTransform(t:TFloat32Array) {
		skinTransform = Mat4.fromFloat32Array(t);
		skinTransformI = Mat4.identity();
		skinTransformI.getInverse(skinTransform);
	}

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
}
