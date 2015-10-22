package lue.resource;

import lue.resource.importer.SceneFormat;

class ModelResource extends Resource {

	public var resource:TGeometryResource;
	public var geometry:Geometry;

	public function new(name:String, id:String) {
		super();

		var format:TSceneFormat = Resource.getSceneResource(name);
		resource = Resource.getGeometryResourceById(format.geometry_resources, id);
		if (resource == null) {
			trace("Resource not found!");
			return;
		}

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

		// Create data
		buildData(data, pa, true, na, true, uva, true, ca, true);

		var usage = kha.graphics4.Usage.StaticUsage;
		geometry = new Geometry(data, indices, materialIndices, pa, na, uva, usage);
		geometry.build(Shader.defaultStructure, Shader.defaultStructureLength);
	}

	function getVertexArray(attrib:String):TVertexArray {
		for (va in resource.mesh.vertex_arrays) {
			if (va.attrib == attrib) {
				return va;
			}
		}
		return null;
	}

	// TODO: pass vertex structure
	function buildData(data:Array<Float>,
					   pa:Array<Float> = null, paEnabled = false,
					   na:Array<Float> = null, naEnabled = false,
					   uva:Array<Float> = null, uvaEnabled = false,
					   ca:Array<Float> = null, caEnabled = false,
					   isSkinned = false) {

		//var ba:Array<Float> = [];
		//var wa:Array<Float> = [];

		for (i in 0...Std.int(pa.length / 3)) {
			
			if (paEnabled) {
				data.push(pa[i * 3]); // Pos
				data.push(pa[i * 3 + 1]);
				data.push(pa[i * 3 + 2]);
			}

			if (uvaEnabled) {
				if (uva != null) {
					data.push(uva[i * 2]); // TC
					data.push(1 - uva[i * 2 + 1]);
				}
				else {
					data.push(0);
					data.push(0);
				}
			}

			if (naEnabled) {
				if (na != null) {
					data.push(na[i * 3]); // Normal
					data.push(na[i * 3 + 1]);
					data.push(na[i * 3 + 2]);
				}
				else {
					data.push(1);
					data.push(1);
					data.push(1);
				}
			}

			if (caEnabled) {
				if (ca != null) { // Color
					data.push(ca[i * 3]); // Vertex colors
					data.push(ca[i * 3 + 1]);
					data.push(ca[i * 3 + 2]);
					data.push(1.0);
				}
				else {
					data.push(1.0);	// Default color
					data.push(1.0);
					data.push(1.0);
					data.push(1.0);
				}
			}

			/*if (isSkinned) { // Bones and weights
				data.push(ba[i * 4]);
				data.push(ba[i * 4 + 1]);
				data.push(ba[i * 4 + 2]);
				data.push(ba[i * 4 + 3]);

				data.push(wa[i * 4]);
				data.push(wa[i * 4 + 1]);
				data.push(wa[i * 4 + 2]);
				data.push(wa[i * 4 + 3]);
			}*/
		}
	}
}
