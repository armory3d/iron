package wings.w3d.material;

import kha.graphics.Texture;
import wings.w3d.scene.Model;

class TextureMaterial extends Material {

	public var texture:Texture;

	public function new(shader:Shader, texture:Texture) {
		super(shader);
		this.texture = texture;
	}

	public override function registerModel(model:Model) {
		model.setTexture(texture);
	}
}
