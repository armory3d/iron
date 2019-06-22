package iron.data;

import kha.graphics4.Usage;
import kha.arrays.Int16Array;
import kha.arrays.Uint32Array;
import iron.data.SceneFormat;

class MeshData {

	public var name:String;
	public var raw:TMeshData;
	public var format:TSceneFormat;
	public var geom:Geometry;
	public var start = 0; // Batched
	public var count = -1;
	public var refcount = 0; // Number of users
	public var handle:String; // Handle used to retrieve this object in Data
	public var scalePos:kha.FastFloat = 1.0;
	public var scaleTex:kha.FastFloat = 1.0;

	public var isSkinned:Bool;

	public function new(raw:TMeshData, done:MeshData->Void) {
		this.raw = raw;
		this.name = raw.name;
		
		if (raw.scale_pos != null) scalePos = raw.scale_pos;
		if (raw.scale_tex != null) scaleTex = raw.scale_tex;

		// Mesh data
		var indices:Array<Uint32Array> = [];
		var materialIndices:Array<Int> = [];
		for (ind in raw.index_arrays) {
			indices.push(ind.values);
			materialIndices.push(ind.material);
		}

		// Mandatory vertex array names for now
		var pa = getVertexArrayValues("pos");
		var na = getVertexArrayValues("nor");
		var uva = getVertexArrayValues("tex");
		var uva1 = getVertexArrayValues("tex1");
		var ca = getVertexArrayValues("col");
		var tanga = getVertexArrayValues("tang");

		// Skinning
		isSkinned = raw.skin != null;

		// Usage, also used for instanced data
		var parsedUsage = Usage.StaticUsage;
		if (raw.dynamic_usage != null && raw.dynamic_usage == true) parsedUsage = Usage.DynamicUsage;
		var usage = parsedUsage;

		var bonea:Int16Array = null; // Store bone indices and weights per vertex
		var weighta:Int16Array = null;
		if (isSkinned) {
			var l = Std.int(pa.length / 4) * 4;
			bonea = new Int16Array(l);
			weighta = new Int16Array(l);

			var index = 0;
			var ai = 0;
			for (i in 0...Std.int(pa.length / 4)) {
				var boneCount = raw.skin.bone_count_array[i];
				for (j in index...(index + boneCount)) {
					bonea[ai] = raw.skin.bone_index_array[j];
					weighta[ai] = raw.skin.bone_weight_array[j];
					ai++;
				}
				// Fill unused weights
				for (j in boneCount...4) {
					bonea[ai] = 0;
					weighta[ai] = 0;
					ai++;
				}
				index += boneCount;
			}
		}
		
		// Make vertex buffers
		geom = new Geometry(this, indices, materialIndices,
							pa, na, uva, uva1, ca, tanga, bonea, weighta, usage);
		geom.name = name;

		done(this);
	}

	public function delete() {
		geom.delete();
	}

	public static function parse(name:String, id:String, done:MeshData->Void) {
		Data.getSceneRaw(name, function(format:TSceneFormat) {
			var raw:TMeshData = Data.getMeshRawByName(format.mesh_datas, id);
			if (raw == null) {
				trace('Mesh data "$id" not found!');
				done(null);
			}

			new MeshData(raw, function(dat:MeshData) {
				dat.format = format;
				// Skinned
				if (raw.skin != null) {
					dat.geom.skinBoneCounts = raw.skin.bone_count_array;
					dat.geom.skinBoneIndices = raw.skin.bone_index_array;
					dat.geom.skinBoneWeights = raw.skin.bone_weight_array;
					dat.geom.skeletonBoneRefs = raw.skin.bone_ref_array;
					dat.geom.skeletonBoneLens = raw.skin.bone_len_array;
					dat.geom.initSkeletonTransforms(raw.skin.transformsI);
				}
				done(dat);
			});
		});
	}

	function getVertexArrayValues(attrib:String):Int16Array {
		for (va in raw.vertex_arrays) if (va.attrib == attrib) return va.values;
		return null;
	}
}
