package iron.resource;

import kha.graphics4.VertexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import iron.resource.SceneFormat;

class ModelResource extends Resource {

	public var resource:TGeometryResource;
	public var geometry:Geometry;

	public static inline var ForceCpuSkinning = false;
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

		// Normal mapping
		var tanaVA = getVertexArray("tangent");
		var tana = tanaVA != null ? tanaVA.values : null;

		// Skinning
		isSkinned = resource.mesh.skin != null ? true : false;
		// Usage, also used for instanced data
		var parsedUsage = Usage.StaticUsage;
		if (resource.mesh.static_usage != null && resource.mesh.static_usage == false) parsedUsage = Usage.DynamicUsage;
		var usage = (isSkinned && ForceCpuSkinning) ? Usage.DynamicUsage : parsedUsage;

		var bonea:Array<Float> = null; // Store bone indices and weights per vertex
		var weighta:Array<Float> = null;
		if (isSkinned && !ForceCpuSkinning) {
			bonea = [];
			weighta = [];

			var index = 0;
			for (i in 0...Std.int(pa.length / 3)) {
				var boneCount = resource.mesh.skin.bone_count_array[i];
				for (j in index...(index + boneCount)) {
					bonea.push(resource.mesh.skin.bone_index_array[j]);
					weighta.push(resource.mesh.skin.bone_weight_array[j]);
				}
				// Fill unused weights
				for (j in boneCount...4) {
					bonea.push(0);
					weighta.push(0);
				}
				index += boneCount;
			}
		}

		// Create data
		var data = buildData(pa, na, uva, ca, tana, bonea, weighta);
		
		// TODO: Mandatory vertex data names and sizes
		// pos=3, tex=2, nor=3, col=4, tan=3, bone=4, weight=4
		var struct = ShaderResource.getVertexStructure(pa != null, na != null, uva != null, ca != null, tana != null, bonea != null, weighta != null);
		var structLength = ShaderResource.getVertexStructureLength(pa != null, na != null, uva != null, ca != null, tana != null, bonea != null, weighta != null);

		geometry = new Geometry(data, indices, materialIndices, pa, na, uva, ca, tana, bonea, weighta, usage);		
		geometry.build(struct, structLength);

		// Instanced
		if (resource.mesh.instance_offsets != null) {
			setupInstancedGeometry(resource.mesh.instance_offsets, usage);
		}
	}

	public function setupInstancedGeometry(offsets:Array<Float>, usage:Usage) {
		geometry.instanced = true;
		geometry.instanceCount = Std.int(offsets.length / 3);

		var structure = new VertexStructure();
    	structure.add("off", kha.graphics4.VertexData.Float3);

		var vb = new VertexBuffer(geometry.instanceCount,
								  structure, usage,
								  1);
		var vertices = vb.lock();
		for (i in 0...vertices.length) {
			vertices.set(i, offsets[i]);
		}
		vb.unlock();

		geometry.instancedVertexBuffers = [geometry.vertexBuffer, vb];
	}

	public static function parse(name:String, id:String, boneNodes:Array<TNode> = null):ModelResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TGeometryResource = Resource.getGeometryResourceById(format.geometry_resources, id);

		var res = new ModelResource(resource);

		// Skinned
		if (resource.mesh.skin != null) {
			// TODO: check !ForceCpuSkinning
			var nodes = boneNodes != null ? boneNodes : format.nodes;
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

	function buildData(pa:Array<Float> = null,
					   na:Array<Float> = null,
					   uva:Array<Float> = null,
					   ca:Array<Float> = null,
					   tana:Array<Float> = null,
					   bonea:Array<Float> = null,
					   weighta:Array<Float> = null):Array<Float> {

		var data:Array<Float> = [];
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

			// Normal mapping
			if (tana != null) { // Tangents
				data.push(tana[i * 3]);
				data.push(tana[i * 3 + 1]);
				data.push(tana[i * 3 + 2]);
			}

			// GPU skinning
			if (bonea != null) { // Bone indices
				data.push(bonea[i * 4]);
				data.push(bonea[i * 4 + 1]);
				data.push(bonea[i * 4 + 2]);
				data.push(bonea[i * 4 + 3]);
			}

			if (weighta != null) { // Weights
				data.push(weighta[i * 4]);
				data.push(weighta[i * 4 + 1]);
				data.push(weighta[i * 4 + 2]);
				data.push(weighta[i * 4 + 3]);
			}
		}

		return data;
	}
}
