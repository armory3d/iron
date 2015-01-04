package fox.core;

import composure.traits.AbstractTrait;

class FrameRenderer2D extends AbstractTrait {

	var renderTraits:Array<IRenderable2D> = [];
	var lateRenderTraits:Array<ILateRenderable2D> = [];

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

	@injectAdd({desc:true,sibl:false})
	public function addLateRenderTrait(trait:ILateRenderable2D) {
		lateRenderTraits.push(trait);
	}
	
	@injectRemove
	public function removeLateRenderTrait(trait:ILateRenderable2D) {
		lateRenderTraits.remove(trait);
	}
	
	public function render(g:kha.graphics2.Graphics) {
		for(trait in renderTraits) {
			trait.render(g);
		}

		for(trait in lateRenderTraits) {
			trait.render(g);
		}

		// Render shadow map
		//g.color = kha.Color.White;
        //g.opacity = 1.0;
        //g.drawScaledImage(FrameRenderer.shadowMap, 0, 128, 128, -128);
        //g.drawScaledImage(FrameRenderer.shadowMap, 0, 0, 128, 128);
	}

	public function begin(g:kha.graphics2.Graphics) {
		g.begin(false);
	}

	public function end(g:kha.graphics2.Graphics) {
		g.end();
	}
}
