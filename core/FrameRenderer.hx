package wings.core;

import kha.Painter;
import composure.traits.AbstractTrait;

class FrameRenderer extends AbstractTrait {

	var renderTraits:Array<IRenderTrait> = [];

	public function new() {
		super();
	}
	
	@injectAdd({desc:true,sibl:false})
	public function addRenderTrait(trait:IRenderTrait) {
		renderTraits.push(trait);
	}
	
	@injectRemove
	public function removeRenderTrait(trait:IRenderTrait) {
		renderTraits.remove(trait);
	}
	
	public function render(painter:Painter) {
		for(trait in renderTraits){
			trait.render(painter);
		}
	}
}
