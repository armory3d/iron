package wings.core;

import kha.Painter;
import composure.traits.AbstractTrait;

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
	
	public function render() {
		for (trait in renderTraits) {
			trait.render();
		}
	}
}
