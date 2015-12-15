package lue.resource;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import lue.math.Vec3;
import lue.math.Mat4;
import lue.resource.importer.SceneFormat;

class ModelResource extends Resource {

	public var resource:TGeometryResource;
	public var geometry:Geometry;
	public var isSkinned:Bool;
	public var bones:Array<TNode> = [];

	public function new(resource:TGeometryResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;

		// Mesh data
		var data:Array<Float> = [];
		var indices:Array<Array<Int>> = [];
		var materialIndices:Array<Int> = [];
		for (ind in resource.mesh.index_arrays) {
			indices.push(ind.values);
			materialIndices.push(ind.material);
		}

		var paVA = getVertexArray("position");
		var pa = paVA != null ? paVA.values : null;
		
		var naVA = getVertexArray("normal");
		var na = naVA != null ? naVA.values : null; 

		var uvaVA = getVertexArray("texcoord");
		var uva = uvaVA != null ? uvaVA.values : null;

		var caVA = getVertexArray("color");
		var ca = caVA != null ? caVA.values : null;

		var tanaVA = getVertexArray("tangent");
		var tana = tanaVA != null ? tanaVA.values : null;

		var bitanaVA = getVertexArray("bitangent");
		var bitana = bitanaVA != null ? bitanaVA.values : null;

		// Create data
		buildData(data, pa, na, uva, ca, tana, bitana, null, null);

		isSkinned = resource.mesh.skin != null ? true : false;
		var usage = isSkinned ? Usage.DynamicUsage : Usage.StaticUsage;
		
		// TODO: Mandatory vertex data names and sizes
		// pos=3, tex=2, nor=3, col=4, tan=3, bitan=3
		var struct = ShaderResource.getVertexStructure(pa != null, na != null, uva != null, ca != null, tana != null, bitana != null);
		var structLength = ShaderResource.getVertexStructureLength(pa != null, na != null, uva != null, ca != null, tana != null, bitana != null);

		geometry = new Geometry(data, indices, materialIndices, pa, na, uva, ca, tana, bitana, usage);		
		geometry.build(struct, structLength);

		// Instanced
		if (resource.mesh.instance_offsets != null) {
			setupInstancedGeometry(resource.mesh.instance_offsets);
		}
	}

	public function setupInstancedGeometry(offsets:Array<Float>) {
		geometry.instanced = true;
		geometry.instanceCount = Std.int(offsets.length / 3);

		var structure = new VertexStructure();
    	structure.add("off", kha.graphics4.VertexData.Float3);

		var vb = new VertexBuffer(geometry.instanceCount,
								  structure, kha.graphics4.Usage.StaticUsage,
								  1);
		var vertices = vb.lock();
		for (i in 0...vertices.length) {
			vertices.set(i, offsets[i]);
		}
		vb.unlock();

		geometry.instancedVertexBuffers = [geometry.vertexBuffer, vb];
	}

	public static function parse(name:String, id:String, remoteBoneNodes:Array<TNode> = null):ModelResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TGeometryResource = Resource.getGeometryResourceById(format.geometry_resources, id);

		var res = new ModelResource(resource);

		// Skinned
		if (resource.mesh.skin != null) {
			var nodes = remoteBoneNodes != null ? remoteBoneNodes : format.nodes;
			for (n in nodes) {
				setParents(n);
			}
			traverseNodes(nodes, function(node:TNode) {
				if (node.type == "bone_node") {
					res.bones.push(node);
				}
			});

			res.geometry.initSkinTransform(resource.mesh.skin.transform.values);
			res.geometry.skinBoneCounts = resource.mesh.skin.bone_count_array;
			res.geometry.skinBoneIndices = resource.mesh.skin.bone_index_array;
			res.geometry.skinBoneWeights = resource.mesh.skin.bone_weight_array;
			res.geometry.skeletonBoneRefs = resource.mesh.skin.skeleton.bone_ref_array;
			res.geometry.initSkeletonBones(res.bones);
			res.geometry.initSkeletonTransforms(resource.mesh.skin.skeleton.transforms);
		}

		return res;
	}

	static function setParents(node:TNode) {
		if (node.nodes == null) return;
		for (n in node.nodes) {
			n.parent = node;
			setParents(n);
		}
	}
	static function traverseNodes(nodes:Array<TNode>, callback:TNode->Void) {
		for (i in 0...nodes.length) {
			traverseNodesStep(nodes[i], callback);
		}
	}
	static function traverseNodesStep(node:TNode, callback:TNode->Void) {
		callback(node);
		if (node.nodes == null) return;
		for (i in 0...node.nodes.length) {
			traverseNodesStep(node.nodes[i], callback);
		}
	}

	function getVertexArray(attrib:String):TVertexArray {
		for (va in resource.mesh.vertex_arrays) {
			if (va.attrib == attrib) {
				return va;
			}
		}
		return null;
	}

	function buildData(data:Array<Float>,
					   pa:Array<Float> = null,
					   na:Array<Float> = null,
					   uva:Array<Float> = null,
					   ca:Array<Float> = null,
					   tana:Array<Float> = null,
					   bitana:Array<Float> = null,
					   ba:Array<Float> = null,
					   wa:Array<Float> = null) {

		for (i in 0...Std.int(pa.length / 3)) {
			
			data.push(pa[i * 3]); // Pos
			data.push(pa[i * 3 + 1]);
			data.push(pa[i * 3 + 2]);

			if (na != null) { // Normals
				data.push(na[i * 3]);
				data.push(na[i * 3 + 1]);
				data.push(na[i * 3 + 2]);
			}

			if (uva != null) { // TC
				data.push(uva[i * 2]);
				data.push(1 - uva[i * 2 + 1]);
			}

			if (ca != null) { // Colors
				data.push(ca[i * 3]);
				data.push(ca[i * 3 + 1]);
				data.push(ca[i * 3 + 2]);
				data.push(1.0);
			}

			if (tana != null) { // Tangents
				data.push(tana[i * 3]);
				data.push(tana[i * 3 + 1]);
				data.push(tana[i * 3 + 2]);
			}

			if (bitana != null) { // Bitangents
				data.push(bitana[i * 3]);
				data.push(bitana[i * 3 + 1]);
				data.push(bitana[i * 3 + 2]);
			}

			if (ba != null) { // Bones
				data.push(ba[i * 4]);
				data.push(ba[i * 4 + 1]);
				data.push(ba[i * 4 + 2]);
				data.push(ba[i * 4 + 3]);
			}

			if (wa != null) { // Weights
				data.push(wa[i * 4]);
				data.push(wa[i * 4 + 1]);
				data.push(wa[i * 4 + 2]);
				data.push(wa[i * 4 + 3]);
			}
		}
	}
}

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

    public var aabbMin:Vec3;
	public var aabbMax:Vec3;
	public var size:Vec3;
	public var radius:Float;

	var data:Array<Float>;
	var ids:Array<Array<Int>>;
	public var usage:Usage;

	public var positions:Array<Float>;
	public var normals:Array<Float>;
	public var uvs:Array<Float>;
	public var cols:Array<Float>;

	public var tangents:Array<Float>;
	public var bitangents:Array<Float>;

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
						tangents:Array<Float> = null, bitangents:Array<Float> = null,
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
		this.bitangents = bitangents;
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

		aabbMin = new Vec3(-0.01, -0.01, -0.01);
		aabbMax = new Vec3(0.01, 0.01, 0.01);
		size = new Vec3();

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
			var m = new Mat4(t);
			skeletonTransforms.push(m);
			
			var mi = new Mat4();
			mi.getInverse(m);
			skeletonTransformsI.push(mi);
		}
	}

	public function initSkinTransform(t:Array<Float>) {
		skinTransform = new Mat4(t);
		skinTransformI = new Mat4();
		skinTransformI.getInverse(skinTransform);
	}
}
