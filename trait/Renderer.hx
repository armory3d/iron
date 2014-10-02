package wings.trait;

import kha.Image;
import wings.core.Trait;
import wings.core.IRenderable;

class Renderer extends Trait implements IRenderable {

	public function new() {
		super();
	}

	public function render(g:kha.graphics4.Graphics) { }

	public function setTexture(tex:Image) { }
}
