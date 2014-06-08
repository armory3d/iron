package wings.sys.material;

import kha.graphics.Texture;
import wings.trait.Renderer;

class TextureMaterial extends Material {

	public var texture:Texture;

	public function new(shader:Shader, texture:Texture) {
		super(shader);
		this.texture = texture;
	}

	public override function registerRenderer(renderer:Renderer) {
		renderer.setTexture(texture);
	}
}
