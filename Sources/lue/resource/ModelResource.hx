package lue.resource;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;
import lue.math.Vec3;
import lue.resource.importer.SceneFormat;

class ModelResource extends Resource {

	public var resource:TGeometryResource;
	public var geometry:Geometry;

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

		// Create data
		buildData(data, pa, true, na, true, uva, true, ca, true);

		var usage = kha.graphics4.Usage.StaticUsage;
		geometry = new Geometry(data, indices, materialIndices, pa, na, uva, usage);
		geometry.build(ShaderResource.defaultStructure, ShaderResource.defaultStructureLength);
	}

	public static function parse(name:String, id:String):ModelResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TGeometryResource = Resource.getGeometryResourceById(format.geometry_resources, id);
		return new ModelResource(resource);
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

class Geometry {

	public var vertexBuffer:VertexBuffer;
	public var indexBuffers:Array<IndexBuffer>;
    public var vertices:kha.arrays.Float32Array;
    public var indices:Array<Array<Int>>;
    public var materialIndices:Array<Int>;
    public var structureLength:Int;

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

	//public var tangents:Array<Float>;
	//public var bitangents:Array<Float>;

	public function new(data:Array<Float>, indices:Array<Array<Int>>, materialIndices:Array<Int>,
						positions:Array<Float>, normals:Array<Float>, uvs:Array<Float>,
						usage:Usage = null) {

		if (usage == null) usage = Usage.StaticUsage;

		this.data = data;
		this.ids = indices;
		this.materialIndices = materialIndices;
		this.usage = usage;

		this.positions = positions;
		this.normals = normals;
		this.uvs = uvs;
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

		// If normal map is present
		//computeTangentBasis();
	}

	function computeTangentBasis() {
		// TODO: export tangents and bitangents from blender

		// http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-13-normal-mapping/
		/*for (i in 0...positions.length) {
 
		    // Shortcuts for vertices
		    glm::vec3 & v0 = vertices[i*3+0];
		    glm::vec3 & v1 = vertices[i*3+1];
		    glm::vec3 & v2 = vertices[i*3+2];
		 
		    // Shortcuts for UVs
		    glm::vec2 & uv0 = uvs[i*3+0];
		    glm::vec2 & uv1 = uvs[i*3+1];
		    glm::vec2 & uv2 = uvs[i*3+2];
		 
		    // Edges of the triangle : postion delta
		    glm::vec3 deltaPos1 = v1-v0;
		    glm::vec3 deltaPos2 = v2-v0;
		 
		    // UV delta
		    glm::vec2 deltaUV1 = uv1-uv0;
		    glm::vec2 deltaUV2 = uv2-uv0;

		    float r = 1.0f / (deltaUV1.x * deltaUV2.y - deltaUV1.y * deltaUV2.x);
			glm::vec3 tangent = (deltaPos1 * deltaUV2.y   - deltaPos2 * deltaUV1.y)*r;
			glm::vec3 bitangent = (deltaPos2 * deltaUV1.x   - deltaPos1 * deltaUV2.x)*r;

			// Set the same tangent for all three vertices of the triangle.
		    // They will be merged later, in vboindexer.cpp
		    tangents.push_back(tangent);
		    tangents.push_back(tangent);
		    tangents.push_back(tangent);
		 
		    // Same thing for binormals
		    bitangents.push_back(bitangent);
		    bitangents.push_back(bitangent);
		    bitangents.push_back(bitangent); 
		}*/
	}

	function calculateAABB() {

		aabbMin = new Vec3(-0.1, -0.1, -0.1);
		aabbMax = new Vec3(0.1, 0.1, 0.1);
		size = new Vec3();

		var i:Int = 0;

		while (i < vertices.length) {

			if (vertices.get(i) > aabbMax.x)		aabbMax.x = vertices.get(i);
			if (vertices.get(i + 1) > aabbMax.y)	aabbMax.y = vertices.get(i + 1);
			if (vertices.get(i + 2) > aabbMax.z)	aabbMax.z = vertices.get(i + 2);

			if (vertices.get(i) < aabbMin.x)		aabbMin.x = vertices.get(i);
			if (vertices.get(i + 1) < aabbMin.y)	aabbMin.y = vertices.get(i + 1);
			if (vertices.get(i + 2) < aabbMin.z)	aabbMin.z = vertices.get(i + 2);

			i += structureLength;
		}

		size.x = Math.abs(aabbMin.x) + Math.abs(aabbMax.x);
		size.y = Math.abs(aabbMin.y) + Math.abs(aabbMax.y);
		size.z = Math.abs(aabbMin.z) + Math.abs(aabbMax.z);

		// Sphere radius
		if (size.x > size.y && size.x > size.z) radius = size.x / 2;
		else if (size.y > size.x && size.y > size.z) radius = size.y / 2;
		else radius = size.z / 2;
	}

	public function getVerticesCount():Int {
		return Std.int(vertices.length / structureLength);
	}
}
