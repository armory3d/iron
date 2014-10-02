package wings.sys.material;

import wings.trait.Renderer;

class ColorMaterial extends Material {

	public var color:kha.Color;

	public function new(shader:Shader, color:kha.Color) {
		super(shader);
		this.color = color;
	}

	public override function registerRenderer(renderer:Renderer) {
		renderer.setColor(color);
	}
}
