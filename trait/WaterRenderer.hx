package fox.trait;

import fox.core.ILateRenderable;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.sys.mesh.Mesh;

class WaterRenderer extends Renderer implements ILateRenderable {

	public var transform:Transform;

	@inject({asc:true,sibl:false})
	public var scene:SceneRenderer;

	public var mvpMatrix:Mat4;
	public var time:Vec3;

	public function new(mesh:Mesh) {
		super(mesh);

		mvpMatrix = new Mat4();
		time = new Vec3();
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.size.x = mesh.geometry.size.x * transform.scale.x;
		transform.size.y = mesh.geometry.size.y * transform.scale.y;
		transform.size.z = mesh.geometry.size.z * transform.scale.z;
    }

	public function render(g:kha.graphics4.Graphics) {
		
		mvpMatrix.identity();
		mvpMatrix.append(transform.matrix);
		mvpMatrix.append(scene.camera.viewMatrix);
		mvpMatrix.append(scene.camera.projectionMatrix);

		time.x += fox.sys.Time.delta;
		
		// Render mesh
		g.setVertexBuffer(mesh.geometry.vertexBuffer);
		g.setIndexBuffer(mesh.geometry.indexBuffer);
		g.setProgram(mesh.material.shader.program);

		setConstants(g);

		g.drawIndexedVertices();
	}
}
