package fox.trait;

import fox.math.Vec3;
import fox.math.Mat4;
import fox.sys.mesh.Mesh;
import fox.core.IRenderable;

class BillboardRenderer extends Renderer implements IRenderable {

	public var transform:Transform;

	@inject({asc:true,sibl:false})
	public var scene:SceneRenderer;

	public var mvpMatrix:Mat4;
	public var transPos:Vec3;
	public var transSize:Vec3;
	public var camRightWorld:Vec3;
	public var camUpWorld:Vec3;
	public var texturing:Bool = true;

	public function new(mesh:Mesh) {
		super(mesh);

		mvpMatrix = new Mat4();

		transPos = new Vec3();
		transSize = new Vec3();

		camRightWorld = new Vec3();
		camUpWorld = new Vec3();
	}

	public override function initConstants() {
		setMat4(mvpMatrix);
		setVec3(transPos);
		setVec3(transSize);
		setVec3(camRightWorld);
		setVec3(camUpWorld);
		setBool(texturing);
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.size.x = mesh.geometry.size.x * transform.scale.x;
		transform.size.y = mesh.geometry.size.y * transform.scale.y;
		transform.size.z = mesh.geometry.size.z * transform.scale.z;
    }

	public function render(g:kha.graphics4.Graphics) {

		var cam:Camera = scene.camera;
		camRightWorld.set(cam.viewMatrix._11, cam.viewMatrix._21, cam.viewMatrix._31); // TODO: fix that Y is up!
		camUpWorld.set(cam.viewMatrix._12, cam.viewMatrix._22, cam.viewMatrix._32);

		mvpMatrix.identity();
		mvpMatrix.append(transform.matrix);
		mvpMatrix.append(scene.camera.viewMatrix);
		mvpMatrix.append(scene.camera.projectionMatrix);

		transPos.set(transform.pos.x, transform.pos.y, transform.pos.z);
		transSize.set(transform.size.x, transform.size.y, transform.size.z);
		
		// Render mesh
		g.setVertexBuffer(mesh.geometry.vertexBuffer);
		g.setIndexBuffer(mesh.geometry.indexBuffer);
		g.setProgram(mesh.material.shader.program);

		if (texturing) {
			g.setTexture(mesh.material.shader.textures[0], textures[0]);
		}

		setConstants(g);

		g.drawIndexedVertices();
	}
}
