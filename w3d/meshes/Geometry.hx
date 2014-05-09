package wings.w3d.meshes;

import kha.graphics.VertexBuffer;
import kha.graphics.IndexBuffer;
import kha.graphics.Usage;
import kha.Sys;

import wings.w3d.materials.VertexStructure;
import wings.math.Vec3;

class Geometry {

	public static var structure;

	public var vertexBuffer:VertexBuffer;
	public var indexBuffer:IndexBuffer;
    public var vertices:Array<Float>;
    public var indices:Array<Int>;

    public var aabbMin:Vec3;
	public var aabbMax:Vec3;
	public var size:Vec3;

	public function new(data:Array<Float>, indices:Array<Int>, usage:Usage = null) {

		if (usage == null) usage = Usage.StaticUsage;

		vertexBuffer = Sys.graphics.createVertexBuffer(Std.int(data.length / Geometry.structure.structureLength),
													   Geometry.structure.structure, usage);
		vertices = vertexBuffer.lock();
		
		for (i in 0...vertices.length) {
			vertices[i] = data[i];
		}
		vertexBuffer.unlock();

		indexBuffer = Sys.graphics.createIndexBuffer(indices.length, Usage.StaticUsage);
		this.indices = indexBuffer.lock();

		for (i in 0...this.indices.length) {
			this.indices[i] = indices[i];
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

			i += 8;
		}

		size.x = Math.abs(aabbMin.x) + Math.abs(aabbMax.x);
		size.y = Math.abs(aabbMin.y) + Math.abs(aabbMax.y);
		size.z = Math.abs(aabbMin.z) + Math.abs(aabbMax.z);
	}

	public function getVerticesCount():Int {
		return Std.int(vertices.length / structure.structureLength);
	}
}
