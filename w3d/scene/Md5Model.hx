package wings.w3d.scene;

import kha.Sys;
import kha.Painter;

import wings.math.Vec3;
import wings.w3d.mesh.Mesh;
import wings.w3d.mesh.Md5Geometry;
import wings.w3d.mesh.Md5Mesh;

class Md5Model extends Model {

	

	public function new(mesh:Mesh, parent:Object = null) {
		super(mesh, parent);

		var m = cast(mesh, Md5Mesh);
		for (i in 0...m.childMaterials.length) {
			if (m.childMaterials[i] != null) m.childMaterials[i].registerModel(this);
		}
	}

	public override function render(painter:Painter) {
		skip = true;
		super.render(painter);

		cast(mesh.geometry, Md5Geometry).md5.update();
		cast(mesh.geometry, Md5Geometry).update();

		
		Sys.graphics.setVertexBuffer(mesh.geometry.vertexBuffer);
		Sys.graphics.setIndexBuffer(mesh.geometry.indexBuffer);
		Sys.graphics.setProgram(mesh.material.shader.program);
		
		Sys.graphics.setTexture(mesh.material.shader.textures[0], textures[0]);
		
		setConstants();

		Sys.graphics.drawIndexedVertices();


		var m = cast(mesh, Md5Mesh);
		var geo = cast(mesh.geometry, Md5Geometry);
		for (i in 0...geo.childGeometries.length) {
			Sys.graphics.setVertexBuffer(geo.childGeometries[i].vertexBuffer);
			Sys.graphics.setIndexBuffer(geo.childGeometries[i].indexBuffer);
			Sys.graphics.setProgram(m.childMaterials[i].shader.program);
			
			Sys.graphics.setTexture(m.childMaterials[i].shader.textures[0], textures[i + 1]);
			
			setConstants();

			Sys.graphics.drawIndexedVertices();
		}
	}
}
