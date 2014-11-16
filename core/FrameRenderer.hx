package fox.core;

import composure.traits.AbstractTrait;
import kha.Color;
import kha.graphics4.CompareMode;
import fox.trait.MeshRenderer;

class FrameRenderer extends AbstractTrait {

	var renderTraits:Array<IRenderable> = [];
	public static var shadowMap:kha.Image;

	var clearColor:Color;

	public function new() {
		super();

		shadowMap = kha.Image.createRenderTarget(512, 512);
		clearColor = Color.fromFloats(Main.gameData.clear[0], Main.gameData.clear[1],
									  Main.gameData.clear[2], Main.gameData.clear[3]);
	}
	
	@injectAdd({desc:true,sibl:false})
	public function addRenderTrait(trait:IRenderable) {
		renderTraits.push(trait);
	}
	
	@injectRemove
	public function removeRenderTrait(trait:IRenderable) {
		renderTraits.remove(trait);
	}

	public function renderShadowMap() {
		var g = shadowMap.g4;
		
		for (trait in renderTraits) {
			if (Std.is(trait, MeshRenderer)) {
				cast(trait, MeshRenderer).renderShadowMap(g);
			}
		}
	}
	
	public function render(g:kha.graphics4.Graphics) {
		for (trait in renderTraits) {
			trait.render(g);
		}
	}

	public function begin(g:kha.graphics4.Graphics) {
		
		shadowMap.g4.begin();
		shadowMap.g4.setDepthMode(true, CompareMode.Less);
		shadowMap.g4.clear(Color.White, 1, null);
        renderShadowMap();
        shadowMap.g4.end();

		g.begin();
		g.setDepthMode(true, CompareMode.Less);
		g.clear(clearColor, 1, null);
	}

	public function end(g:kha.graphics4.Graphics) {
		
		g.setDepthMode(false, CompareMode.Less);
		g.end();
	}
}
