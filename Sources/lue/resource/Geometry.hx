package lue.resource;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import lue.math.Vec4;
import lue.math.Mat4;
import lue.resource.importer.SceneFormat;

class Geometry {

	public var vertexBuffer:VertexBuffer;
	public var indexBuffers:Array<IndexBuffer>;
    public var vertices:kha.arrays.Float32Array;
    public var indices:Array<Array<Int>>;
    public var materialIndices:Array<Int>;
    public var structureLength:Int;

    public var instancedVertexBuffers:Array<VertexBuffer>;
    public var instanced:Bool = false;
	public var instanceCount:Int = 0;

    public var aabbMin:Vec4;
	public var aabbMax:Vec4;
	public var size:Vec4;
	public var radius:Float;

	var data:Array<Float>;
	var ids:Array<Array<Int>>;
	public var usage:Usage;

	public var positions:Array<Float>; // TODO: no need to store these references
	public var normals:Array<Float>;
	public var uvs:Array<Float>;
	public var cols:Array<Float>;

	public var tangents:Array<Float>;

	public var bones:Array<Float>;
	public var weights:Array<Float>;

	// Skinned
	public var skinTransform:Mat4 = null;
	public var skinTransformI:Mat4 = null;
	public var skinBoneCounts:Array<Int> = null;
	public var skinBoneIndices:Array<Int> = null;
	public var skinBoneWeights:Array<Float> = null;

	public var skeletonBoneRefs:Array<String> = null;
	public var skeletonBones:Array<TNode> = null;
	public var skeletonTransforms:Array<Mat4> = null;
	public var skeletonTransformsI:Array<Mat4> = null;

	public function new(data:Array<Float>, indices:Array<Array<Int>>, materialIndices:Array<Int>,
						positions:Array<Float>, normals:Array<Float>, uvs:Array<Float>, cols:Array<Float>,
						tangents:Array<Float> = null,
						bones:Array<Float> = null, weights:Array<Float> = null,
						usage:Usage = null) {

		if (usage == null) usage = Usage.StaticUsage;

		this.data = data;
		this.ids = indices;
		this.materialIndices = materialIndices;
		this.usage = usage;

		this.positions = positions;
		this.uvs = uvs;
		this.normals = normals;
		this.cols = cols;

		this.tangents = tangents;

		this.bones = bones;
		this.weights = weights;
	}

	public function build(structure:VertexStructure, structureLength:Int) {
		this.structureLength = structureLength;

		vertexBuffer = new VertexBuffer(Std.int(data.length / structureLength),
										structure, usage);
		vertices = vertexBuffer.lock();
		
		for (i in 0...vertices.length) {
			vertices.set(i, data[i]);
		}
		vertexBuffer.unlock();

		indexBuffers = [];
		indices = [];
		for (id in ids) {
			var indexBuffer = new IndexBuffer(id.length, usage);
			var indicesA = indexBuffer.lock();

			for (i in 0...indicesA.length) {
				indicesA[i] = id[i];
			}
			indexBuffer.unlock();

			indexBuffers.push(indexBuffer);
			indices.push(indicesA);
		}

		calculateAABB();
	}

	function calculateAABB() {

		aabbMin = new Vec4(-0.01, -0.01, -0.01);
		aabbMax = new Vec4(0.01, 0.01, 0.01);
		size = new Vec4();

		var i = 0;
		while (i < positions.length) {

			if (positions[i] > aabbMax.x)		aabbMax.x = positions[i];
			if (positions[i + 1] > aabbMax.y)	aabbMax.y = positions[i + 1];
			if (positions[i + 2] > aabbMax.z)	aabbMax.z = positions[i + 2];

			if (positions[i] < aabbMin.x)		aabbMin.x = positions[i];
			if (positions[i + 1] < aabbMin.y)	aabbMin.y = positions[i + 1];
			if (positions[i + 2] < aabbMin.z)	aabbMin.z = positions[i + 2];

			i += 3;
		}

		size.x = Math.abs(aabbMin.x) + Math.abs(aabbMax.x);
		size.y = Math.abs(aabbMin.y) + Math.abs(aabbMax.y);
		size.z = Math.abs(aabbMin.z) + Math.abs(aabbMax.z);

		// Sphere radius
		if (size.x >= size.y && size.x >= size.z) radius = size.x / 2;
		else if (size.y >= size.x && size.y >= size.z) radius = size.y / 2;
		else radius = size.z / 2;
	}

	public function getVerticesCount():Int {
		return Std.int(vertices.length / structureLength);
	}

	// Skinned
	// TODO: check !ForceCpuSkinning
	public function initSkeletonBones(bones:Array<TNode>) {
		skeletonBones = [];

		// Set bone references
		for (s in skeletonBoneRefs) {
			for (b in bones) {
				if (b.id == s) {
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
