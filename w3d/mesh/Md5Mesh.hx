package wings.w3d.mesh;

import kha.graphics.Usage;

import wings.w3d.material.Material;
import wings.w3d.importer.md5.Md5Parser;

class Md5Mesh extends wings.w3d.mesh.Mesh {

	public var md5:Md5Parser;

	public function new(meshData:String, animData:String, materials:Array<Material>) {

		md5 = new Md5Parser();
        md5.loadModel(meshData);
        md5.loadAnimation(animData);

        var geoms = new Array<Geometry>();
        for (i in 0...md5.meshes.length) {
        	geoms.push(new Geometry(md5.buildData(i), md5.meshes[i].indexBuffer, Usage.DynamicUsage));
        }

		super(geoms, materials);
	}

	public function update() {

		for (i in 0...md5.meshes.length) {
			var data = md5.buildData(i);
			geometries[i].vertices = geometries[i].vertexBuffer.lock();
			for (j in 0...geometries[i].vertices.length) geometries[i].vertices[j] = data[j];
			geometries[i].vertexBuffer.unlock();
		}
	}
}
