package fox.trait;

import fox.math.Vec3;
import fox.math.Mat4;
import fox.sys.mesh.Mesh;

class BillboardMeshRenderer extends MeshRenderer {

	public var camRightWorld:Vec3;
	public var camUpWorld:Vec3;

	public function new(mesh:Mesh) {
		super(mesh);

		camRightWorld = new Vec3();
		camUpWorld = new Vec3();

		//size = mesh.geometry.size;
	}

	override function render(g:kha.graphics4.Graphics) {

		var cam:Camera = scene.camera;
		camRightWorld.set(cam.viewMatrix._11, cam.viewMatrix._21, cam.viewMatrix._31);
		camUpWorld.set(cam.viewMatrix._12, cam.viewMatrix._22, cam.viewMatrix._32);

		super.render(g);
	}
}
