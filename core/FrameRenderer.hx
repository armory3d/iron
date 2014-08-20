package wings.core;

import kha.Painter;
import composure.traits.AbstractTrait;
import kha.ShaderPainter;

class FrameRenderer extends AbstractTrait {

	var renderTexture:kha.graphics.Texture;
	var renderTraits:Array<IRenderable> = [];

	var imagePainter:ImageShaderPainter;

	public function new() {
		super();

		renderTexture = kha.Sys.graphics.createRenderTargetTexture(1136, 640, kha.graphics.TextureFormat.RGBA32, true);

		var projectionMatrix = kha.math.Matrix4.orthogonalProjection(0, renderTexture.realWidth, renderTexture.realHeight, 0, 0.1, 1000);
		imagePainter = new ImageShaderPainter(projectionMatrix);
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

	public function begin() {
		kha.Sys.graphics.clear(null, 1, null);
		kha.Sys.graphics.setDepthMode(true, kha.graphics.CompareMode.Less);

		//kha.Sys.graphics.renderToTexture(renderTexture);

		//kha.Sys.graphics.clear(null, 1, null);
		
	}

	public function end() {

		/*kha.Sys.graphics.renderToBackbuffer();
		kha.Sys.graphics.setBlendingMode(kha.graphics.BlendingOperation.SourceAlpha, kha.graphics.BlendingOperation.InverseSourceAlpha);

		// Portrait
		imagePainter.setProjection(kha.math.Matrix4.orthogonalProjection(0, kha.Sys.pixelWidth, 0, kha.Sys.pixelHeight, 0.1, 1000));
		imagePainter.drawImage2(renderTexture, 0, 0, renderTexture.realWidth, renderTexture.realHeight, 0, 0, renderTexture.width, renderTexture.height, 0,0,0, 1, kha.Color.White);

		// Landscape
		//imagePainter.setProjection(kha.math.Matrix4.orthogonalProjection(0, kha.Sys.pixelWidth, 0, kha.Sys.pixelHeight, 0.1, 1000));
		//imagePainter.drawImage2(renderTexture, 0, 0, renderTexture.realWidth, renderTexture.realHeight, kha.Sys.pixelWidth, 0, renderTexture.width, renderTexture.height, 0,0,(Math.PI / 2), 1, kha.Color.White);
		
		imagePainter.end();
		imagePainter.setProjection(kha.math.Matrix4.orthogonalProjection(0, renderTexture.realWidth, renderTexture.realHeight, 0, 0.1, 1000));

		kha.Sys.graphics.setDepthMode(true, kha.graphics.CompareMode.Always);*/
	}
}
