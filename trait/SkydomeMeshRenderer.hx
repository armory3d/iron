package fox.trait;

import fox.math.Mat4;
import fox.sys.mesh.Mesh;

class SkydomeMeshRenderer extends MeshRenderer {

	public function new(mesh:Mesh) {
		super(mesh);	
	}

	override function render(g:kha.graphics4.Graphics) {

		var f12:Float = scene.camera.V._41;
		var f13:Float = scene.camera.V._42;
		var f14:Float = scene.camera.V._43;

		scene.camera.V._41 = 0;
		scene.camera.V._42 = -20;
		scene.camera.V._43 = 0;

		super.render(g);

		scene.camera.V._41 = f12;
		scene.camera.V._42 = f13;
		scene.camera.V._43 = f14;
	}
}
