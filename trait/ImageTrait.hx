package wings.trait;

import kha.Image;
import kha.Painter;

import wings.math.Rect;
import wings.core.Trait;
import wings.core.IRenderTrait;

class ImageTrait extends Trait implements IRenderTrait {

	//@inject({desc:false,sibl:true})
	public var transform:Transform;
	public var source:Rect;

	var image:Image;

	public function new(image:Image) {
		super();

		this.image = image;
		source = new Rect(0, 0, image.width, image.height);
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.w = image.width;
		transform.h = image.height;
    }

	public function render(painter:Painter) {

		painter.drawImage2(image, source.x, source.y, source.w, source.h,
						   transform.absx, transform.absy, transform.w, transform.h);
	}
}
