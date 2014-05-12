package wings.w3d.scene;

import kha.Painter;
import wings.math.Vec3;
import wings.w3d.mesh.Mesh;
import wings.w3d.camera.Camera;

class Billboard extends Model {

	public var camRightWorld:Vec3;
	public var camUpWorld:Vec3;

	public function new(mesh:Mesh) {
    	super(mesh);

    	camRightWorld = new Vec3();
		camUpWorld = new Vec3();

		size = mesh.geometry.size;
	}

	public override function render(painter:Painter) {
		var cam:Camera = scene.camera;
		camRightWorld.set(cam.viewMatrix._11, cam.viewMatrix._21, cam.viewMatrix._31);
		camUpWorld.set(cam.viewMatrix._12, cam.viewMatrix._22, cam.viewMatrix._32);

		super.render(painter);
	}
}
