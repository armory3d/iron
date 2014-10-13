package fox.sys.material;

import kha.Image;
import fox.trait.Renderer;

class TextureMaterial extends Material {

	public var texture:Image;

	public function new(shader:Shader, texture:Image) {
		super(shader);
		this.texture = texture;
	}

	public override function registerRenderer(renderer:Renderer) {
		renderer.setTexture(texture);
	}
}
