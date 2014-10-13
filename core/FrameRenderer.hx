package fox.core;

import composure.traits.AbstractTrait;
import kha.graphics4.CompareMode;

class FrameRenderer extends AbstractTrait {

	var renderTraits:Array<IRenderable> = [];

	public function new() {
		super();
	}
	
	@injectAdd({desc:true,sibl:false})
	public function addRenderTrait(trait:IRenderable) {
		renderTraits.push(trait);
	}
	
	@injectRemove
	public function removeRenderTrait(trait:IRenderable) {
		renderTraits.remove(trait);
	}
	
	public function render(g:kha.graphics4.Graphics) {
		for (trait in renderTraits) {
			trait.render(g);
		}
	}

	public function begin(g:kha.graphics4.Graphics) {
		g.clear(kha.Color.fromBytes(0, 0, 0, 0));
		g.clear(null, 1, null);
		g.setDepthMode(true, CompareMode.Less);
	}

	public function end(g:kha.graphics4.Graphics) {
			
	}
}
