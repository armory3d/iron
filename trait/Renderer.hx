package fox.trait;

import kha.Image;
import fox.core.Trait;
import fox.core.IRenderable;

class Renderer extends Trait implements IRenderable {

	public function new() {
		super();
	}

	public function render(g:kha.graphics4.Graphics) { }

	public function setTexture(tex:Image) { }
}
