package wings.w2d;

import kha.Painter;
import kha.Image;
import wings.math.Rect;

class SlicedImage2D extends Object2D {

	public var image(default, set):Image;

	public function new(image:Image, x:Float = 0, y:Float = 0) {
		super();

		rel.x = x;
		rel.y = y;
		
		this.image = image;
	}

	public override function render(painter:Painter) {
		if (image == null || !visible) return;

		painter.setColor(abs.color);
		painter.opacity = abs.a;

		

		super.render(painter);
	}

	function set_image(img:Image):Image {
		// Update object size
		if (img != null) {
			w = img.width;
			h = img.height;
		}

		return image = img;
	}
}
