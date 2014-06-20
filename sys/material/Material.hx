package wings.sys.material;

import wings.trait.Renderer;

class Material {

	public var shader:Shader;

	public function new(shader:Shader) {
		this.shader = shader;
	}

	public function registerRenderer(renderer:Renderer) {

	}
}
