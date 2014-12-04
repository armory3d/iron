package fox.trait2d.util;

import kha.Image;
import kha.Painter;
import fox.math.Rect;
import fox.core.Trait;
import fox.core.IRenderable2D;
import fox.trait.Transform;

// Combines several textures and automatically adjusts sources
class MultiTextureRenderer extends Trait implements IRenderable2D {

	public var transform:Transform;
	public var source:Rect;

	var textures:Array<Image>;

	public function new(textures:Array<Image>) {
		super();

		this.textures = textures;
		source = new Rect(0, 0, textures[0].width, textures[0].height);
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.w = textures[0].width;
		transform.h = textures[0].height;
    }

	public function render(painter:Painter) {

		painter.setColor(transform.color);
		painter.opacity = transform.a;

		painter.drawImage2(textures[0], source.x, source.y, source.w, source.h,
						   transform.absx, transform.absy, transform.w, transform.h);
	}
}
