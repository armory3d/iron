package fox.core;

import composure.traits.AbstractTrait;
import kha.Color;
import kha.graphics4.CompareMode;
import fox.trait.MeshRenderer;

class FrameRenderer extends AbstractTrait {

	var renderTraits:Array<IRenderable> = [];
	var lateRenderTraits:Array<ILateRenderable> = [];
	
	public static var shadowMap:kha.Image;

	var clearColor:Color;

	public static var numRenders = 0;

	public function new() {
		super();

		// Create shadow map texture
		#if js
		shadowMap = kha.Image.createRenderTarget(512, 512, kha.graphics4.TextureFormat.RGBA128);
		#else
		shadowMap = kha.Image.createRenderTarget(512, 512);
		#end

		// Parse clear color
		if (Main.gameData != null) {
			clearColor = Color.fromFloats(Main.gameData.clear[0], Main.gameData.clear[1],
										  Main.gameData.clear[2], Main.gameData.clear[3]);
		}
		else {
			clearColor = Color.fromValue(0xffbac2fc);
		}
	}
	
	@injectAdd({desc:true,sibl:false})
	public function addRenderTrait(trait:IRenderable) {
		renderTraits.push(trait);
	}
	
	@injectRemove
	public function removeRenderTrait(trait:IRenderable) {
		renderTraits.remove(trait);
	}

	@injectAdd({desc:true,sibl:false})
	public function addLateRenderTrait(trait:ILateRenderable) {
		lateRenderTraits.push(trait);
	}
	
	@injectRemove
	public function removeLateRenderTrait(trait:ILateRenderable) {
		lateRenderTraits.remove(trait);
	}

	function renderShadowMap() {
		var g = shadowMap.g4;
		
		for (trait in renderTraits) {
			if (Std.is(trait, MeshRenderer)) {
				cast(trait, MeshRenderer).renderShadowMap(g);
			}
		}
	}
	
	public function render(g:kha.graphics4.Graphics) {
		numRenders = 0;

		for (trait in renderTraits) {
			trait.render(g);
		}

		for (trait in lateRenderTraits) {
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
