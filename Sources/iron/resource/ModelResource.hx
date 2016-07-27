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
		
		// Make vertex buffers
		geometry = new Geometry(indices, materialIndices, pa, na, uva, ca, tana, bonea, weighta, usage);

		// Instanced
		if (resource.mesh.instance_offsets != null) {
			geometry.setupInstanced(resource.mesh.instance_offsets, usage);
		}
	}

	public function delete() {
		geometry.delete();
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
}
