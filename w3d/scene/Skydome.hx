package wings.w3d.scene;

import kha.Painter;
import wings.w3d.meshes.Mesh;
import wings.w3d.materials.Material;

class Skydome extends Model {

	public function new(mesh:Mesh) {
		super(mesh);
	}

	public override function render(painter:Painter) {

		var f12:Float = scene.camera.viewMatrix._41;
		var f13:Float = scene.camera.viewMatrix._42;
		var f14:Float = scene.camera.viewMatrix._43;

		scene.camera.viewMatrix._41 = 0;
		scene.camera.viewMatrix._42 = -20;
		scene.camera.viewMatrix._43 = 0;

		super.render(painter);

		scene.camera.viewMatrix._41 = f12;
		scene.camera.viewMatrix._42 = f13;
		scene.camera.viewMatrix._43 = f14;
	}
}
