package wings.w3d.material;

import wings.w3d.scene.Model;

class Material {

	public var shader:Shader;

	public function new(shader:Shader) {
		this.shader = shader;
	}

	public function registerModel(model:Model) {

	}
}
