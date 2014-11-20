package fox.trait;

import fox.core.ILateRenderable;
import kha.Image;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.sys.material.TextureMaterial;
import fox.sys.mesh.Mesh;
import fox.sys.Assets;

class WaterRenderer extends Renderer implements ILateRenderable {

	public var transform:Transform;

	@inject({asc:true,sibl:false})
	public var scene:SceneRenderer;

	public var mvpMatrix:Mat4;

	public var mesh:Mesh;

	public function new(mesh:Mesh) {
		super();

		mvpMatrix = new Mat4();

		this.mesh = mesh;

		if (this.mesh.material != null) this.mesh.material.registerRenderer(this);
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.size.x = mesh.geometry.size.x * transform.scale.x;
		transform.size.y = mesh.geometry.size.y * transform.scale.y;
		transform.size.z = mesh.geometry.size.z * transform.scale.z;
    }

	public function render(g:kha.graphics4.Graphics) {
		
	}
}
