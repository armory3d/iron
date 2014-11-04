package fox.core;

import composure.traits.AbstractTrait;
import kha.graphics4.CompareMode;
import fox.trait.MeshRenderer;

class FrameRenderer extends AbstractTrait {

	var renderTraits:Array<IRenderable> = [];
	public static var shadowMap:kha.Image;

	public function new() {
		super();
		shadowMap = kha.Image.createRenderTarget(1024, 1024);
	}
	
	@injectAdd({desc:true,sibl:false})
	public function addRenderTrait(trait:IRenderable) {
		renderTraits.push(trait);
	}
	
	@injectRemove
	public function removeRenderTrait(trait:IRenderable) {
		renderTraits.remove(trait);
	}

	function renderShadowMap() {
		var g = shadowMap.g4;
		// g.setDepthMode(true, CompareMode.Less);
		// g.clear(kha.Color.fromBytes(96, 192, 214, 0));
		// g.clear(null, 1, null);
		for (trait in renderTraits) {
			if (Std.is(trait, MeshRenderer)) {
				//cast(trait, MeshRenderer).renderShadowMap(g);
			}
		}
	}
	
	public function render(g:kha.graphics4.Graphics) {

		renderShadowMap();

		// Render
		for (trait in renderTraits) {
			trait.render(g);
		}
	}

	public function begin(g:kha.graphics4.Graphics) {
		g.setDepthMode(true, CompareMode.Less);
		g.clear(kha.Color.fromBytes(96, 192, 214, 0));
		g.clear(null, 1, null);
	}

	public function end(g:kha.graphics4.Graphics) {
		g.setDepthMode(false, CompareMode.Less);
	}
}
