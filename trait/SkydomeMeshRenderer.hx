package wings.trait;

import wings.math.Mat4;

class SkydomeMeshRenderer extends MeshRenderer {

	public function new(mesh:Mesh) {
		super(mesh);	
	}

	override function render(g:kha.graphics4.Graphics) {

		var f12:Float = scene.camera.viewMatrix._41;
		var f13:Float = scene.camera.viewMatrix._42;
		var f14:Float = scene.camera.viewMatrix._43;

		scene.camera.viewMatrix._41 = 0;
		scene.camera.viewMatrix._42 = -20;
		scene.camera.viewMatrix._43 = 0;

		super.render();

		scene.camera.viewMatrix._41 = f12;
		scene.camera.viewMatrix._42 = f13;
		scene.camera.viewMatrix._43 = f14;
	}
}
