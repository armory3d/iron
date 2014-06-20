package wings.core;

import kha.Painter;
import composure.traits.AbstractTrait;

class FrameRenderer2D extends AbstractTrait {

	var renderTraits:Array<IRenderable2D> = [];

	public function new() {
		super();
	}
	
	@injectAdd({desc:true,sibl:false})
	public function addRenderTrait(trait:IRenderable2D) {
		renderTraits.push(trait);
	}
	
	@injectRemove
	public function removeRenderTrait(trait:IRenderable2D) {
		renderTraits.remove(trait);
	}
	
	public function render(painter:Painter) {
		for(trait in renderTraits){
			trait.render(painter);
		}
	}
}
