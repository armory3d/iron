package fox.core;

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
	
	public function render(g:kha.graphics2.Graphics) {
		for(trait in renderTraits) {
			trait.render(g);
		}

		//g.color = kha.Color.White;
        //g.opacity = 1.0;
        //g.drawImage(FrameRenderer.shadowMap, 0, 0);
	}

	public function begin(g:kha.graphics2.Graphics) {
		g.begin(false);
	}

	public function end(g:kha.graphics2.Graphics) {
		g.end();
	}
}
