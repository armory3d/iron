package iron.data;

import kha.graphics4.VertexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;
import iron.data.SceneFormat;

class MeshData extends Data {

	public var name:String;
	public var raw:TMeshData;
	public var format:TSceneFormat;
	public var geom:Geometry;
	public var start = 0; // Batched
	public var count = -1;
	public var refcount = 0; // Number of users
	public var handle:String; // Handle used to retrieve this object in Data

	public var isSkinned:Bool;

	#if arm_sdf
	public static var sdfTex:kha.Image = null; // Use as global volume for now
	#end

	public function new(raw:TMeshData, done:MeshData->Void) {
		super();

		this.raw = raw;
		this.name = raw.name;

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
		#if arm_skin_cpu
		var usage = isSkinned ? Usage.DynamicUsage : Usage.StaticUsage;
		#else
		var usage = parsedUsage;
		#end

		var bonea:Float32Array = null; // Store bone indices and weights per vertex
		var weighta:Float32Array = null;
		#if (!arm_skin_cpu)
		if (isSkinned) {
			var l = Std.int(pa.length / 3) * 4;
			bonea = new Float32Array(l);
			weighta = new Float32Array(l);

			var index = 0;
			var ai = 0;
			for (i in 0...Std.int(pa.length / 3)) {
				var boneCount = raw.skin.bone_count_array[i];
				for (j in index...(index + boneCount)) {
					bonea[ai] = raw.skin.bone_index_array[j];
					weighta[ai] = raw.skin.bone_weight_array[j];
					ai++;
				}
				// Fill unused weights
				for (j in boneCount...4) {
					bonea[ai] = 0.0;
					weighta[ai] = 0.0;
					ai++;
				}
				index += boneCount;
			}
		}
		#end
		
		// Make vertex buffers
		geom = new Geometry(indices, materialIndices, pa, na, uva, uva1, ca, tanga, bonea, weighta, usage, raw.instanced_data, raw.instanced_type);
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
					#if arm_skin_cpu
					dat.geom.initSkinTransform(raw.skin.transform.values);
					#end
					dat.geom.skinBoneCounts = raw.skin.bone_count_array;
					dat.geom.skinBoneIndices = raw.skin.bone_index_array;
					dat.geom.skinBoneWeights = raw.skin.bone_weight_array;
					dat.geom.skeletonBoneRefs = raw.skin.bone_ref_array;
					dat.geom.skeletonBoneLens = raw.skin.bone_len_array;
					dat.geom.initSkeletonTransforms(raw.skin.transformsI);
				}
				// Sdf-enabled
				#if arm_sdf
				if (raw.sdf_ref != null && raw.sdf_ref != '') {
					Data.getBlob(raw.sdf_ref + '.arm', function(blob:kha.Blob) {
						var res = 50;
						sdfTex = kha.Image.fromBytes3D(blob.toBytes(), res, res, res, kha.graphics4.TextureFormat.A16, kha.graphics4.Usage.StaticUsage); // RS/AO
						// sdfTex.generateMipmaps(16);
						done(dat);
					});
				}
				else
				#end
					done(dat);
			});
		});
	}

	function getVertexArrayValues(attrib:String):Float32Array {
		for (va in raw.vertex_arrays) if (va.attrib == attrib) return va.values;
		return null;
	}
}
