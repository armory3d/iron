package wings.w3d.materials;

import kha.graphics.Texture;
import wings.w3d.scene.Model;

class ColorMaterial extends Material {

	var color:Int;

	public function new(shader:Shader, color:Int) {
		super(shader);

		this.color = color;
	}

	public override function registerModel(model:Model) {
		
	}
}
