package wings.w3d.scene;

import kha.Sys;
import kha.Painter;

import wings.math.Vec3;
import wings.w3d.mesh.Mesh;
import wings.w3d.mesh.Md5Mesh;

class Md5Model extends Model {

	public function new(mesh:Md5Mesh, parent:Object = null) {
		super(mesh, parent);
	}

	public override function render(painter:Painter) {
		cast(mesh, Md5Mesh).md5.update();
		cast(mesh, Md5Mesh).update();

		super.render(painter);
	}
}
