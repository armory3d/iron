package wings.w3d.mesh;

import wings.w3d.importer.md5.Md5Parser;

class Md5Geometry extends Geometry {

	public var md5:Md5Parser;
	public var childGeometries:Array<Geometry>;

	public function new(data:String, animData:String) {

        md5 = new Md5Parser();
        md5.loadModel(data);
        md5.loadAnimation(animData);

		super(md5.buildData(0), md5.meshes[0].indexBuffer);

		childGeometries = [];
		for (i in 1...md5.meshes.length) {
			childGeometries.push(new Geometry(md5.buildData(i), md5.meshes[i].indexBuffer));
		}
	}

	public function update() {
		var data = md5.buildData(0);
		vertexBuffer = kha.Sys.graphics.createVertexBuffer(Std.int(data.length / structure.structureLength), structure.structure, usage);
		vertices = vertexBuffer.lock();
		for (i in 0...vertices.length) vertices[i] = data[i];
		vertexBuffer.unlock();

		/*for (i in 1...md5.meshes.length) {
			var data = md5.buildData(i);
			childGeometries[i - 1].vertexBuffer = kha.Sys.graphics.createVertexBuffer(Std.int(data.length / structure.structureLength), structure.structure, usage);
			childGeometries[i - 1].vertices = vertexBuffer.lock();
			for (j in 0...childGeometries[i - 1].vertices.length) childGeometries[i - 1].vertices[j] = data[j];
			vertexBuffer.unlock();
		}*/
	}
}
