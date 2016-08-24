package iron.data;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.data.SceneFormat;

class Mesh {
#if WITH_DEINTERLEAVED
	public var vertexBuffers:Array<VertexBuffer>;
#else
	public var vertexBuffer:VertexBuffer;
	// public var vertexBufferDepth:VertexBuffer; // Depth pass - pos, bone, weight
	// public var structLengthDepth:Int;
#end
	public var indexBuffers:Array<IndexBuffer>;
    public var vertices:kha.arrays.Float32Array;
    public var indices:Array<Array<Int>>;
    public var materialIndices:Array<Int>;
    public var structLength:Int;

    public var instancedVertexBuffers:Array<VertexBuffer>;
    public var instanced = false;
	public var instanceCount = 0;

	var ids:Array<Array<Int>>;
	public var usage:Usage;

	public var positions:Array<Float>; // TODO: no need to store these references
	public var normals:Array<Float>;
	public var uvs:Array<Float>;
	public var cols:Array<Float>;

	public var tangents:Array<Float>;

	public var bones:Array<Float>;
	public var weights:Array<Float>;
	
	public var offsetVecs:Array<Vec4>; // Used for sorting and culling

	// Skinned
	public var skinTransform:Mat4 = null;
	public var skinTransformI:Mat4 = null;
	public var skinBoneCounts:Array<Int> = null;
	public var skinBoneIndices:Array<Int> = null;
	public var skinBoneWeights:Array<Float> = null;

	public var skeletonBoneRefs:Array<String> = null;
	public var skeletonBones:Array<TObj> = null;
	public var skeletonTransforms:Array<Mat4> = null;
	public var skeletonTransformsI:Array<Mat4> = null;

	public function new(indices:Array<Array<Int>>, materialIndices:Array<Int>,
						positions:Array<Float>, normals:Array<Float>, uvs:Array<Float>, cols:Array<Float>,
						tangents:Array<Float> = null,
						bones:Array<Float> = null, weights:Array<Float> = null,
						usage:Usage = null) {

		if (usage == null) usage = Usage.StaticUsage;

		this.ids = indices;
		this.materialIndices = materialIndices;
		this.usage = usage;

		this.positions = positions;
		this.normals = normals;
		this.uvs = uvs;
		this.cols = cols;
		this.tangents = tangents;
		this.bones = bones;
		this.weights = weights;

		build();
	}

	public function delete() {
#if WITH_DEINTERLEAVED
		for (buf in vertexBuffers) buf.delete();
#else
		vertexBuffer.delete();
#end
		for (buf in indexBuffers) buf.delete();
	}

	static function getVertexStructure(pos = false, nor = false, tex = false, col = false, tan = false, bone = false, weight = false):VertexStructure {
		var structure = new VertexStructure();
		if (pos) structure.add("pos", VertexData.Float3);
		if (nor) structure.add("nor", VertexData.Float3);
		if (tex) structure.add("tex", VertexData.Float2);
		if (col) structure.add("col", VertexData.Float3);
		if (tan) structure.add("tan", VertexData.Float3);
		if (bone) structure.add("bone", VertexData.Float4);
		if (weight) structure.add("weight", VertexData.Float4);
		return structure;
	}

	public function setupInstanced(offsets:Array<Float>, usage:Usage) {
		// Store vecs for sorting and culling
		offsetVecs = [];
		for (i in 0...Std.int(offsets.length / 3)) {
			offsetVecs.push(new Vec4(offsets[i * 3], offsets[i * 3 + 1], offsets[i * 3 + 2]));
		}

		instanced = true;
		instanceCount = Std.int(offsets.length / 3);

		var structure = new VertexStructure();
    	structure.add("off", kha.graphics4.VertexData.Float3);

		var instVB = new VertexBuffer(instanceCount, structure, usage, 1);
		var vertices = instVB.lock();
		for (i in 0...vertices.length) vertices.set(i, offsets[i]);
		instVB.unlock();

#if WITH_DEINTERLEAVED
		instancedVertexBuffers = [];
		for (vb in vertexBuffers) instancedVertexBuffers.push(vb);
		instancedVertexBuffers.push(instVB);
#else
		instancedVertexBuffers = [vertexBuffer, instVB];
#end
	}

	public function sortInstanced(camX:Float, camY:Float, camZ:Float) {
		// Use W component to store distance to camera
		for (v in offsetVecs) {
			// TODO: include parent transform
			v.w  = iron.math.Vec4.distance3dRaw(camX, camY, camZ, v.x, v.y, v.z);
		}
		
		offsetVecs.sort(function(a, b):Int {
			return a.w > b.w ? 1 : -1;
		});

		var vb = instancedVertexBuffers[1];
		var vertices = vb.lock();
		for (i in 0...Std.int(vertices.length / 3)) {
			vertices.set(i * 3, offsetVecs[i].x);
			vertices.set(i * 3 + 1, offsetVecs[i].y);
			vertices.set(i * 3 + 2, offsetVecs[i].z);
		}
		vb.unlock();
	}

#if (!WITH_DEINTERLEAVED)
	static function buildVertices(vertices:kha.arrays.Float32Array,
							  	  pa:Array<Float> = null,
					   		  	  na:Array<Float> = null,
					   		  	  uva:Array<Float> = null,
					   		  	  ca:Array<Float> = null,
					   		  	  tana:Array<Float> = null,
					   		  	  bonea:Array<Float> = null,
					   		  	  weighta:Array<Float> = null) {

		var numVertices = Std.int(pa.length / 3);
		var di = -1;
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
			if (ca != null) { // Colors
				vertices.set(++di, ca[i * 3]);
				vertices.set(++di, ca[i * 3 + 1]);
				vertices.set(++di, ca[i * 3 + 2]);
			}
			// Normal mapping
			if (tana != null) { // Tangents
				vertices.set(++di, tana[i * 3]);
				vertices.set(++di, tana[i * 3 + 1]);
				vertices.set(++di, tana[i * 3 + 2]);
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
#end

	public function build() {
#if WITH_DEINTERLEAVED
		vertexBuffers = [];
		vertexBuffers.push(makeDeinterleavedVB(positions, "pos", 3));
		if (normals != null) vertexBuffers.push(makeDeinterleavedVB(normals, "nor", 3));
		if (uvs != null) vertexBuffers.push(makeDeinterleavedVB(uvs, "uv", 2));
		if (cols != null) vertexBuffers.push(makeDeinterleavedVB(cols, "col", 3));
		if (tangents != null) vertexBuffers.push(makeDeinterleavedVB(tangents, "tan", 3));
		if (bones != null) vertexBuffers.push(makeDeinterleavedVB(bones, "bone", 4));
		if (weights != null) vertexBuffers.push(makeDeinterleavedVB(weights, "weight", 4));
#else
		// TODO: Mandatory vertex data names and sizes
		// pos=3, tex=2, nor=3, col=4, tan=3, bone=4, weight=4
		var struct = getVertexStructure(positions != null, normals != null, uvs != null, cols != null, tangents != null, bones != null, weights != null);
		structLength = Std.int(struct.byteSize() / 4);
		vertexBuffer = new VertexBuffer(Std.int(positions.length / 3), struct, usage);
		vertices = vertexBuffer.lock();
		buildVertices(vertices, positions, normals, uvs, cols, tangents, bones, weights);
		vertexBuffer.unlock();

		// For depth passes, pos=3, bone=4, weight=4
	// #if (!WITHOUT_SHADOWS)
		// var structDepth = getVertexStructure(positions != null, null, null, null, null, bones != null, weights != null);
		// structLengthDepth = Std.int(struct.byteSize() / 4);
		// vertexBufferDepth = new VertexBuffer(Std.int(positions.length / 3), structDepth, usage);
		// var verticesDepth = vertexBufferDepth.lock();
		// buildVertices(verticesDepth, positions, null, null, null, null, bones, weights);
		// vertexBufferDepth.unlock();
	// #end
#end

		indexBuffers = [];
		indices = [];
		for (id in ids) {
			var indexBuffer = new IndexBuffer(id.length, usage);
			var indicesA = indexBuffer.lock();
			for (i in 0...indicesA.length) indicesA[i] = id[i];
			indexBuffer.unlock();

			indexBuffers.push(indexBuffer);
			indices.push(indicesA);
		}
	}

#if WITH_DEINTERLEAVED
	function makeDeinterleavedVB(data:Array<Float>, name:String, structLength:Int) {
		var struct = new VertexStructure();
		if (structLength == 2) struct.add(name, VertexData.Float2);
		else if (structLength == 3) struct.add(name, VertexData.Float3);
		else if (structLength == 4) struct.add(name, VertexData.Float4);

		var vertexBuffer = new VertexBuffer(Std.int(data.length / structLength), struct, usage);
		var vertices = vertexBuffer.lock();
		for (i in 0...vertices.length) vertices.set(i, data[i]);
		vertexBuffer.unlock();
		return vertexBuffer;
	}
#end

	// function calculateAABB() {
	// 	aabbMin = new Vec4(-0.01, -0.01, -0.01);
	// 	aabbMax = new Vec4(0.01, 0.01, 0.01);
	// 	size = new Vec4();
	// 	var i = 0;
	// 	while (i < positions.length) {
	// 		if (positions[i] > aabbMax.x)		aabbMax.x = positions[i];
	// 		if (positions[i + 1] > aabbMax.y)	aabbMax.y = positions[i + 1];
	// 		if (positions[i + 2] > aabbMax.z)	aabbMax.z = positions[i + 2];
	// 		if (positions[i] < aabbMin.x)		aabbMin.x = positions[i];
	// 		if (positions[i + 1] < aabbMin.y)	aabbMin.y = positions[i + 1];
	// 		if (positions[i + 2] < aabbMin.z)	aabbMin.z = positions[i + 2];
	// 		i += 3;
	// 	}
	// 	size.x = Math.abs(aabbMin.x) + Math.abs(aabbMax.x);
	// 	size.y = Math.abs(aabbMin.y) + Math.abs(aabbMax.y);
	// 	size.z = Math.abs(aabbMin.z) + Math.abs(aabbMax.z);
	// 	// Sphere radius
	// 	if (size.x >= size.y && size.x >= size.z) radius = size.x / 2;
	// 	else if (size.y >= size.x && size.y >= size.z) radius = size.y / 2;
	// 	else radius = size.z / 2;
	// }

	public function getVerticesCount():Int {
		return Std.int(positions.length / 3);
	}

	// Skinned
	// TODO: check !ForceCpuSkinning
	public function initSkeletonBones(bones:Array<TObj>) {
		skeletonBones = [];

		// Set bone references
		for (s in skeletonBoneRefs) {
			for (b in bones) {
				if (b.name == s) {
					skeletonBones.push(b);
				}
			}
		}
	}

	public function initSkeletonTransforms(transforms:Array<Array<Float>>) {
		skeletonTransforms = [];
		skeletonTransformsI = [];

		for (t in transforms) {
			var m = Mat4.fromArray(t);
			skeletonTransforms.push(m);
			
			var mi = Mat4.identity();
			mi.getInverse(m);
			skeletonTransformsI.push(mi);
		}
	}

	public function initSkinTransform(t:Array<Float>) {
		skinTransform = Mat4.fromArray(t);
		skinTransformI = Mat4.identity();
		skinTransformI.getInverse(skinTransform);
	}
}
