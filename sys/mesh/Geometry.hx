package fox.sys.mesh;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import fox.sys.material.Material;
import fox.sys.material.VertexStructure;
import fox.math.Vec3;

class Geometry {

	public var vertexBuffer:VertexBuffer;
	public var indexBuffer:IndexBuffer;
    public var vertices:Array<Float>;
    public var indices:Array<Int>;

    public var aabbMin:Vec3;
	public var aabbMax:Vec3;
	public var size:Vec3;
	public var radius:Float;

	var data:Array<Float>;
	var ids:Array<Int>;
	public var usage:Usage;

	public var structure:VertexStructure;

	public var positions:Array<Float>;
	public var normals:Array<Float>;

	public function new(data:Array<Float>, indices:Array<Int>,
						positions:Array<Float>, normals:Array<Float>,
						usage:Usage = null) {

		if (usage == null) usage = Usage.StaticUsage;

		this.data = data;
		this.ids = indices;
		this.usage = usage;

		this.positions = positions;
		this.normals = normals;
	}

	public function build(material:Material) {
		
		structure = material.shader.structure;

		vertexBuffer = new VertexBuffer(Std.int(data.length / structure.structureLength),
										structure.structure, usage);
		vertices = vertexBuffer.lock();
		
		for (i in 0...vertices.length) {
			vertices[i] = data[i];
		}
		vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(ids.length, Usage.StaticUsage);
		this.indices = indexBuffer.lock();

		for (i in 0...this.indices.length) {
			this.indices[i] = ids[i];
		}
		indexBuffer.unlock();


		calculateAABB();
	}

	function calculateAABB() {

		aabbMin = new Vec3(-0.1, -0.1, -0.1);
		aabbMax = new Vec3(0.1, 0.1, 0.1);
		size = new Vec3();

		var i:Int = 0;

		while (i < vertices.length) {

			if (vertices[i] > aabbMax.x)		aabbMax.x = vertices[i];
			if (vertices[i + 1] > aabbMax.y)	aabbMax.y = vertices[i + 1];
			if (vertices[i + 2] > aabbMax.z)	aabbMax.z = vertices[i + 2];

			if (vertices[i] < aabbMin.x)		aabbMin.x = vertices[i];
			if (vertices[i + 1] < aabbMin.y)	aabbMin.y = vertices[i + 1];
			if (vertices[i + 2] < aabbMin.z)	aabbMin.z = vertices[i + 2];

			i += structure.structureLength;
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
		return Std.int(vertices.length / structure.structureLength);
	}
}
